package com.faithconnect.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun getRenderMode(): RenderMode {
        // Use TextureView instead of SurfaceView to avoid BLASTBufferQueue overflow
        return RenderMode.texture
    }
}
