package com.ksl.ksl

import android.content.Context
import android.graphics.*
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class HandLandmarkChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.ksl.ksl/hand_landmark"
        const val SIZE = 224
    }

    private var handLandmarker: HandLandmarker? = null

    private val CONNECTIONS = listOf(
        0 to 1, 1 to 2, 2 to 3, 3 to 4,
        0 to 5, 5 to 6, 6 to 7, 7 to 8,
        0 to 9, 9 to 10, 10 to 11, 11 to 12,
        0 to 13, 13 to 14, 14 to 15, 15 to 16,
        0 to 17, 17 to 18, 18 to 19, 19 to 20,
        5 to 9, 9 to 13, 13 to 17
    )

    init {
        try {
            android.util.Log.d("HandLandmark", "Đang đọc model file...")
            val modelBytes = context.assets.open("flutter_assets/assets/hand_landmarker.task").readBytes()
            android.util.Log.d("HandLandmark", "Model size: ${modelBytes.size} bytes")

            val options = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(
                    BaseOptions.builder()
                        .setModelAssetBuffer(
                            java.nio.ByteBuffer.allocateDirect(modelBytes.size).apply {
                                put(modelBytes)
                                rewind()
                            }
                        )
                        .build()
                )
                .setRunningMode(RunningMode.IMAGE)
                .setNumHands(1)
                .setMinHandDetectionConfidence(0.5f)
                .setMinHandPresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .build()

            handLandmarker = HandLandmarker.createFromOptions(context, options)
            android.util.Log.d("HandLandmark", "Khởi tạo thành công!")
        } catch (e: Throwable) {
            android.util.Log.e("HandLandmark", "LỖI: ${e.javaClass.name}: ${e.message}")
            handLandmarker = null
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        android.util.Log.d("HandLandmark", "onMethodCall: ${call.method}")
        if (call.method != "processFrame") {
            result.notImplemented()
            return
        }
        val bytes = call.argument<ByteArray>("bytes")
        if (bytes == null) {
            result.error("NO_BYTES", "Missing bytes", null)
            return
        }
        try {
            result.success(processFrame(bytes))
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    private fun processFrame(bytes: ByteArray): ByteArray? {
        android.util.Log.d("HandLandmark", "processFrame: ${bytes.size} bytes")  // ← thêm
        val bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            ?.copy(Bitmap.Config.ARGB_8888, true) ?: return null

        android.util.Log.d("HandLandmark", "Bitmap: ${bmp.width}x${bmp.height}")  // ← thêm
        val detectionResult = handLandmarker
            ?.detect(BitmapImageBuilder(bmp).build())
            ?: run {
                android.util.Log.e("HandLandmark", "handLandmarker is null!")  // ← thêm
                return null
            }

        val allHands = detectionResult.landmarks()
        android.util.Log.d("HandLandmark", "Hands detected: ${allHands.size}")  // ← thêm

        if (allHands.isEmpty()) return null

        val hand: List<NormalizedLandmark> = allHands[0]

        val rawXs = FloatArray(hand.size) { i -> hand[i].x() }
        val rawYs = FloatArray(hand.size) { i -> hand[i].y() }

        val minX = rawXs.min()!!
        val maxX = rawXs.max()!!
        val minY = rawYs.min()!!
        val maxY = rawYs.max()!!

        val rangeX = (maxX - minX).coerceAtLeast(0.001f)
        val rangeY = (maxY - minY).coerceAtLeast(0.001f)
        val scale = (1.0f - 2 * 0.05f) / maxOf(rangeX, rangeY)
        val padding = 0.05f

        val xs = FloatArray(hand.size) { i ->
            val nx = (rawXs[i] - minX) * scale + padding +
                    (1.0f - 2 * padding - rangeX * scale) / 2f
            (nx * SIZE).coerceIn(0f, SIZE - 1f)
        }
        val ys = FloatArray(hand.size) { i ->
            val ny = (rawYs[i] - minY) * scale + padding +
                    (1.0f - 2 * padding - rangeY * scale) / 2f
            (ny * SIZE).coerceIn(0f, SIZE - 1f)
        }

        // Vẽ skeleton nền đen
        val outBmp = Bitmap.createBitmap(SIZE, SIZE, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(outBmp)
        canvas.drawColor(Color.BLACK)

        val linePaint = Paint().apply {
            color = Color.WHITE
            strokeWidth = 2f
            style = Paint.Style.STROKE
            isAntiAlias = true
        }
        val dotPaint = Paint().apply {
            color = Color.rgb(180, 180, 180)
            style = Paint.Style.FILL
            isAntiAlias = true
        }

        for ((a, b) in CONNECTIONS) {
            canvas.drawLine(xs[a], ys[a], xs[b], ys[b], linePaint)
        }
        for (i in hand.indices) {
            canvas.drawCircle(xs[i], ys[i], 3f, dotPaint)
        }

        val stream = ByteArrayOutputStream()
        outBmp.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}