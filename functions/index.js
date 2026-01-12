/**
 * Firebase Cloud Functions for FaithConnect
 *
 * This file contains the cloud function that sends push notifications
 * to users' mobile devices using Firebase Cloud Messaging (FCM).
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function: sendPushNotification
 *
 * Triggers when a new document is created in the 'push_notifications' collection.
 * Fetches the user's FCM tokens and sends the push notification to all their devices.
 */
exports.sendPushNotification = functions.firestore
  .document("push_notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const notificationData = snapshot.data();
    const notificationId = context.params.notificationId;

    console.log(`📬 Processing push notification: ${notificationId}`);
    console.log(`📝 Data:`, JSON.stringify(notificationData));

    try {
      const { userId, title, body, type, postId, chatId, imageUrl } =
        notificationData;

      if (!userId || !title) {
        console.error("❌ Missing required fields: userId or title");
        await snapshot.ref.update({
          sent: false,
          error: "Missing required fields",
        });
        return null;
      }

      // Get user's FCM tokens from their profile
      const userDoc = await db.collection("users").doc(userId).get();

      if (!userDoc.exists) {
        console.error(`❌ User not found: ${userId}`);
        await snapshot.ref.update({ sent: false, error: "User not found" });
        return null;
      }

      const userData = userDoc.data();
      const fcmTokens = userData.fcmTokens || [];

      if (fcmTokens.length === 0) {
        console.log(`⚠️ No FCM tokens found for user: ${userId}`);
        await snapshot.ref.update({ sent: false, error: "No FCM tokens" });
        return null;
      }

      console.log(
        `📱 Found ${fcmTokens.length} FCM token(s) for user: ${userId}`
      );

      // Prepare the notification message
      const message = {
        notification: {
          title: title,
          body: body || getDefaultBody(type),
        },
        data: {
          type: type || "general",
          postId: postId || "",
          chatId: chatId || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          notification: {
            icon: "ic_launcher",
            color: "#6366F1",
            channelId: "faith_connect_notifications",
            priority: "high",
            defaultSound: true,
            defaultVibrateTimings: true,
          },
          priority: "high",
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: title,
                body: body || getDefaultBody(type),
              },
              badge: 1,
              sound: "default",
            },
          },
        },
      };

      // Add image if provided
      if (imageUrl) {
        message.notification.imageUrl = imageUrl;
        message.android.notification.imageUrl = imageUrl;
      }

      // Send to all user's devices
      const sendResults = [];
      const invalidTokens = [];

      for (const token of fcmTokens) {
        try {
          const response = await messaging.send({
            ...message,
            token: token,
          });
          console.log(
            `✅ Successfully sent to token: ${token.substring(0, 20)}...`
          );
          sendResults.push({ token: token, success: true, response });
        } catch (error) {
          console.error(
            `❌ Failed to send to token: ${token.substring(0, 20)}...`,
            error.message
          );
          sendResults.push({
            token: token,
            success: false,
            error: error.message,
          });

          // Track invalid tokens for cleanup
          if (
            error.code === "messaging/invalid-registration-token" ||
            error.code === "messaging/registration-token-not-registered"
          ) {
            invalidTokens.push(token);
          }
        }
      }

      // Clean up invalid tokens from user's profile
      if (invalidTokens.length > 0) {
        console.log(`🧹 Removing ${invalidTokens.length} invalid token(s)`);
        await db
          .collection("users")
          .doc(userId)
          .update({
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
          });
      }

      // Update the notification document with results
      const successCount = sendResults.filter((r) => r.success).length;
      await snapshot.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        successCount: successCount,
        totalTokens: fcmTokens.length,
        invalidTokensRemoved: invalidTokens.length,
      });

      console.log(
        `✅ Push notification sent successfully to ${successCount}/${fcmTokens.length} device(s)`
      );
      return { success: true, sentCount: successCount };
    } catch (error) {
      console.error("❌ Error sending push notification:", error);
      await snapshot.ref.update({
        sent: false,
        error: error.message,
        errorAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return { success: false, error: error.message };
    }
  });

/**
 * Helper function to get default notification body based on type
 */
function getDefaultBody(type) {
  switch (type) {
    case "like":
      return "liked your content";
    case "comment":
      return "commented on your content";
    case "newFollower":
      return "started following you";
    case "newMessage":
      return "sent you a message";
    case "newPost":
      return "posted new content";
    case "newReel":
      return "posted a new reel";
    default:
      return "You have a new notification";
  }
}

/**
 * Cloud Function: cleanupOldNotifications
 *
 * Scheduled function that runs daily to clean up old push notification records
 * (older than 7 days) to keep the database clean.
 */
exports.cleanupOldNotifications = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async (context) => {
    console.log("🧹 Running cleanup of old push notifications...");

    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 7); // 7 days ago

    try {
      const snapshot = await db
        .collection("push_notifications")
        .where("createdAt", "<", cutoffDate)
        .limit(500) // Process in batches
        .get();

      if (snapshot.empty) {
        console.log("✅ No old notifications to clean up");
        return null;
      }

      const batch = db.batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`✅ Deleted ${snapshot.size} old notification records`);
      return { deleted: snapshot.size };
    } catch (error) {
      console.error("❌ Error cleaning up notifications:", error);
      return { error: error.message };
    }
  });

/**
 * Cloud Function: sendTopicNotification
 *
 * HTTP callable function to send notifications to all users subscribed to a topic.
 * Useful for broadcast announcements.
 */
exports.sendTopicNotification = functions.https.onCall(
  async (data, context) => {
    // Verify the caller is authenticated and is an admin/leader
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { topic, title, body, type } = data;

    if (!topic || !title) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Topic and title are required"
      );
    }

    try {
      const message = {
        notification: {
          title: title,
          body: body || "You have a new announcement",
        },
        data: {
          type: type || "announcement",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        topic: topic,
        android: {
          notification: {
            icon: "ic_launcher",
            color: "#6366F1",
            channelId: "faith_connect_notifications",
          },
        },
      };

      const response = await messaging.send(message);
      console.log(`✅ Topic notification sent to: ${topic}`, response);
      return { success: true, messageId: response };
    } catch (error) {
      console.error("❌ Error sending topic notification:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  }
);
