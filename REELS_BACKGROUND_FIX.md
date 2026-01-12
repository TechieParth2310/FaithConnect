# 🎬 Reels Background Playback Fix

## Problem Description

**Critical Issue:** Reels videos were playing continuously in the background even when the user switched to other tabs (Home, Messages, etc.). This caused:

- 🔋 **Battery drain** - Videos kept decoding and playing
- 🐌 **Performance issues** - Memory and CPU continuously used
- 📊 **Log spam** - Continuous MediaCodec, AudioTrack, BLASTBufferQueue logs
- 😣 **Poor UX** - Videos started automatically when app opened

### Evidence of the Problem

Terminal logs showing continuous video processing even when not on Reels tab:

```
I/MediaCodec: [0xb400007432409580] enqueue 30 input frames in last 1004 ms
I/MediaCodec: [0xb400007432409580] dequeue 31 output frames in last 1006 ms
D/BLASTBufferQueue: pipelineFull: too many frames in pipeline (6)
D/AudioTrack: pause(21407): prior state:STATE_ACTIVE
D/AudioTrack: start(21407): prior state:STATE_PAUSED
```

These logs repeated every 1-2 seconds = videos playing continuously in background.

## Solution Implemented

### 1. Added Lifecycle Management to ReelsScreen

**File:** `lib/screens/reels_screen.dart`

#### Changes Made:

**A. Added WidgetsBindingObserver Mixin**

```dart
class _ReelsScreenState extends State<ReelsScreen>
    with WidgetsBindingObserver {
```

This allows the screen to observe app lifecycle changes (when app goes to background).

**B. Added Active State Tracking**

```dart
bool _isActive = false; // Track if this screen is visible
```

**C. Registered Observer in initState**

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  widget.onSetActiveCallback?.call(setActive);
  _loadReels();
}
```

**D. Implemented App Lifecycle Handler**

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  // Pause videos when app goes to background
  if (state == AppLifecycleState.paused ||
      state == AppLifecycleState.inactive) {
    _pauseAllVideos();
  } else if (state == AppLifecycleState.resumed && _isActive) {
    // Resume current video only if screen is active
    _resumeCurrentVideo();
  }
}
```

**E. Added Tab Change Handler**

```dart
// Called from MainWrapper when tab changes
void setActive(bool active) {
  if (_isActive == active) return;

  setState(() => _isActive = active);

  if (!active) {
    // Pause all videos when tab switched away
    _pauseAllVideos();
  } else if (_reels.isNotEmpty && _currentIndex < _reels.length) {
    // Resume current video when tab switched back
    _resumeCurrentVideo();
  }
}
```

**F. Added Helper Methods**

```dart
void _pauseAllVideos() {
  for (var controller in _controllers.values) {
    if (controller.value.isInitialized && controller.value.isPlaying) {
      controller.pause();
    }
  }
}

void _resumeCurrentVideo() {
  if (_currentIndex >= 0 && _currentIndex < _reels.length) {
    final currentReel = _reels[_currentIndex];
    final controller = _controllers[currentReel.id];
    if (controller != null &&
        controller.value.isInitialized &&
        !controller.value.isPlaying) {
      controller.play();
    }
  }
}
```

**G. Updated Video Initialization**

```dart
// Only play video if screen is active
if (_isActive) {
  _controllers[reel.id]?.play();
}
```

**H. Updated dispose Method**

```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _pauseAllVideos(); // Pause all videos before disposing
  for (var controller in _controllers.values) {
    controller.dispose();
  }
  _pageController.dispose();
  super.dispose();
}
```

### 2. Updated ReelsScreen Constructor

**File:** `lib/screens/reels_screen.dart`

```dart
class ReelsScreen extends StatefulWidget {
  final Function(Function(bool))? onSetActiveCallback;

  const ReelsScreen({super.key, this.onSetActiveCallback});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}
```

This allows the parent widget (MainWrapper) to register a callback to control video playback.

### 3. Updated MainWrapper to Notify ReelsScreen

**File:** `lib/screens/main_wrapper.dart`

#### Changes Made:

**A. Added Callback Storage**

```dart
class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  UserModel? _currentUser;
  bool _isLoading = true;
  Function(bool)? _reelsSetActive;
```

**B. Pass Callback to ReelsScreen**

```dart
List<Widget> get _screens {
  if (_currentUser?.role == UserRole.religiousLeader) {
    return [
      const LeaderDashboardScreen(),
      ReelsScreen(onSetActiveCallback: (callback) => _reelsSetActive = callback),
      const SearchScreen(),
      const MessagesScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];
  } else {
    return [
      const HomeScreen(),
      ReelsScreen(onSetActiveCallback: (callback) => _reelsSetActive = callback),
      const LeadersScreen(),
      const MessagesScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];
  }
}
```

**C. Updated Tab Change Handler**

```dart
onTap: (index) {
  // Notify ReelsScreen of active state
  final reelsIndex = 1; // Reels is always at index 1 for both roles
  _reelsSetActive?.call(index == reelsIndex);

  setState(() {
    _currentIndex = index;
  });
},
```

## How It Works

### Flow Diagram

```
1. User opens app
   ↓
2. MainWrapper initializes ReelsScreen with callback
   ↓
3. ReelsScreen registers its setActive() method with MainWrapper
   ↓
4. User navigates to different tab
   ↓
5. MainWrapper's onTap detects tab change
   ↓
6. MainWrapper calls _reelsSetActive(index == reelsIndex)
   ↓
7. ReelsScreen's setActive() is called
   ↓
8. If not active: _pauseAllVideos()
   If active: _resumeCurrentVideo()
   ↓
9. Videos only play when Reels tab is visible ✅
```

### Lifecycle Management

**When App Goes to Background:**

```
App State: Active → Paused
↓
didChangeAppLifecycleState(AppLifecycleState.paused)
↓
_pauseAllVideos() called
↓
All video controllers paused
```

**When App Returns to Foreground:**

```
App State: Paused → Resumed
↓
didChangeAppLifecycleState(AppLifecycleState.resumed)
↓
Check if _isActive == true
↓
If yes: _resumeCurrentVideo()
If no: Keep videos paused
```

**When Tab Changes:**

```
User taps different tab
↓
MainWrapper.onTap(newIndex)
↓
_reelsSetActive(newIndex == 1)
↓
ReelsScreen.setActive(active)
↓
If active: Resume current video
If not active: Pause all videos
```

## Testing Results

### Before Fix ❌

- Videos played continuously in background
- MediaCodec logs appeared every second
- `pipelineFull` errors in logs
- Battery drain observed
- Videos started automatically on app launch

### After Fix ✅

- Videos only play when Reels tab is visible
- MediaCodec logs only appear when actually watching reels
- No `pipelineFull` errors when not watching
- Normal battery usage
- Videos start only when user navigates to Reels tab

### Test Scenario Verification

| Scenario                     | Before Fix         | After Fix                   |
| ---------------------------- | ------------------ | --------------------------- |
| Open app on Home tab         | ❌ Videos playing  | ✅ No videos playing        |
| Switch to Reels tab          | ✅ Videos play     | ✅ Videos play              |
| Switch to Messages tab       | ❌ Videos continue | ✅ Videos pause immediately |
| App goes to background       | ❌ Videos continue | ✅ Videos pause             |
| Return to app (not on Reels) | ❌ Videos continue | ✅ Videos stay paused       |
| Return to app (on Reels)     | ❌ Already playing | ✅ Resume current video     |

## Performance Impact

### Memory Usage

- **Before:** Video decoders active continuously
- **After:** Video decoders active only when needed

### Battery Life

- **Before:** Continuous video decoding and audio processing
- **After:** Normal battery usage

### Log Output

- **Before:** Continuous MediaCodec, AudioTrack, BLASTBufferQueue spam
- **After:** Clean logs, messages only when actively watching

## Code Quality Improvements

1. **Proper Lifecycle Management** - Screen now properly observes app lifecycle
2. **Resource Cleanup** - Videos paused before disposal
3. **Clear State Management** - `_isActive` flag tracks visibility
4. **Callback Pattern** - Clean communication between parent and child
5. **Defensive Programming** - Null checks and initialization checks

## Best Practices Followed

✅ **Dispose Pattern** - All observers and controllers properly cleaned up  
✅ **State Management** - Clear boolean flag for active state  
✅ **Callback Communication** - Clean parent-child communication  
✅ **Null Safety** - Proper null checks throughout  
✅ **Resource Management** - Videos paused when not visible  
✅ **Performance** - Minimal impact on app performance  
✅ **User Experience** - Videos only play when intended

## Additional Benefits

1. **Battery Life** - Users will experience better battery life
2. **Data Usage** - If streaming over cellular, less background data usage
3. **Performance** - App runs smoother overall
4. **User Control** - Users have control over when videos play
5. **Professional UX** - Behavior matches expectations from apps like Instagram/TikTok

## Related Files Modified

1. `lib/screens/reels_screen.dart` - Added lifecycle management
2. `lib/screens/main_wrapper.dart` - Added tab change notification

## Future Enhancements

Consider adding:

- Option to auto-play videos on tab enter
- Option to continue playing in picture-in-picture mode
- Analytics tracking for video engagement
- Preloading optimization based on active state

## Notes

- Reels are muted by default (volume = 0.0)
- Users can unmute with the volume toggle button
- Videos loop continuously when playing
- Only current video plays at a time (not multiple videos)
- Previous and next videos are preloaded for smooth scrolling

---

**Status:** ✅ **FIXED** - Reels now only play when tab is visible  
**Tested:** ✅ Verified on motorola edge 40 (Android 15)  
**Impact:** 🟢 High - Major performance and UX improvement
