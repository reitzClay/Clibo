package com.example.clibofe

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.graphics.Rect
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.view.PixelCopy
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.claybytes.clibo/screen_capture"
    private val REQUEST_MEDIA_PROJECTION = 1001

    private var projectionManager: MediaProjectionManager? = null
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var pendingResult: MethodChannel.Result? = null

    private var screenWidth = 1080
    private var screenHeight = 1920
    private var screenDensity = 320

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        updateDisplayMetrics()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermissions" -> result.success(mediaProjection != null)
                "requestPermissions" -> requestMediaProjectionPermission(result)
                "captureScreen" -> captureDeviceScreen(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun updateDisplayMetrics() {
        val metrics = DisplayMetrics()
        windowManager.defaultDisplay.getRealMetrics(metrics)
        screenWidth = metrics.widthPixels
        screenHeight = metrics.heightPixels
        screenDensity = metrics.densityDpi
    }

    private fun requestMediaProjectionPermission(result: MethodChannel.Result) {
        if (mediaProjection != null) {
            result.success(true)
            return
        }

        val manager = projectionManager ?: run {
            result.error("NO_PROJECTION_MANAGER", "MediaProjectionManager unavailable", null)
            return
        }

        pendingResult = result
        val captureIntent = manager.createScreenCaptureIntent()
        startActivityForResult(captureIntent, REQUEST_MEDIA_PROJECTION)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_MEDIA_PROJECTION) {
            val result = pendingResult
            pendingResult = null

            if (resultCode == Activity.RESULT_OK && data != null) {
                try {
                    val manager = projectionManager ?: getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    mediaProjection = manager.getMediaProjection(resultCode, data)
                    setupVirtualDisplay()
                    result?.success(true)
                } catch (e: Exception) {
                    result?.error("PROJECTION_INIT_FAILED", "Failed to initialize MediaProjection: ${e.message}", null)
                }
            } else {
                result?.error("PERMISSION_DENIED", "User denied MediaProjection screen capture permission", null)
            }
        }
    }

    private fun setupVirtualDisplay() {
        updateDisplayMetrics()
        imageReader = ImageReader.newInstance(screenWidth, screenHeight, PixelFormat.RGBA_8888, 2)
        mediaProjection?.createVirtualDisplay(
            "CliboScreenCapture",
            screenWidth,
            screenHeight,
            screenDensity,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface,
            null,
            null
        )
    }

    private fun captureDeviceScreen(result: MethodChannel.Result) {
        // Try MediaProjection stream capture first for full system screen capture
        val reader = imageReader
        if (reader != null) {
            var image: Image? = null
            try {
                image = reader.acquireLatestImage() ?: reader.acquireNextImage()
                if (image != null) {
                    val bytes = imageToJpegBytes(image)
                    image.close()
                    if (bytes != null && bytes.isNotEmpty()) {
                        result.success(bytes)
                        return
                    }
                }
            } catch (e: Exception) {
                image?.close()
            }
        }

        // Fallback to Window PixelCopy
        captureWindowPixelCopy(result)
    }

    private fun imageToJpegBytes(image: Image): ByteArray? {
        val planes = image.planes
        val buffer: ByteBuffer = planes[0].buffer
        val pixelStride = planes[0].pixelStride
        val rowStride = planes[0].rowStride
        val rowPadding = rowStride - pixelStride * image.width

        val bitmap = Bitmap.createBitmap(
            image.width + rowPadding / pixelStride,
            image.height,
            Bitmap.Config.ARGB_8888
        )
        bitmap.copyPixelsFromBuffer(buffer)

        val cleanBitmap = Bitmap.createBitmap(bitmap, 0, 0, image.width, image.height)
        val stream = ByteArrayOutputStream()
        cleanBitmap.compress(Bitmap.CompressFormat.JPEG, 75, stream)
        val bytes = stream.toByteArray()

        bitmap.recycle()
        cleanBitmap.recycle()
        return bytes
    }

    private fun captureWindowPixelCopy(result: MethodChannel.Result) {
        try {
            val windowRef = window ?: run {
                result.error("NO_WINDOW", "Window reference is null", null)
                return
            }

            val view = windowRef.decorView.rootView
            val width = if (view.width > 0) view.width else screenWidth
            val height = if (view.height > 0) view.height else screenHeight
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val location = IntArray(2)
                view.getLocationInWindow(location)
                val rect = Rect(location[0], location[1], location[0] + width, location[1] + height)

                PixelCopy.request(windowRef, rect, bitmap, { copyResult ->
                    if (copyResult == PixelCopy.SUCCESS) {
                        val stream = ByteArrayOutputStream()
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 75, stream)
                        result.success(stream.toByteArray())
                    } else {
                        result.error("PIXEL_COPY_FAILED", "PixelCopy failed with status code $copyResult", null)
                    }
                }, Handler(Looper.getMainLooper()))
            } else {
                result.error("UNSUPPORTED_ANDROID_VERSION", "Requires Android O or newer", null)
            }
        } catch (e: Exception) {
            result.error("CAPTURE_EXCEPTION", "Failed to capture window: ${e.message}", null)
        }
    }

    override fun onDestroy() {
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        super.onDestroy()
    }
}
