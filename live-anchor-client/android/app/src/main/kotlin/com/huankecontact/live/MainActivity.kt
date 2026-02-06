package com.huankecontact.live

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream

class MainActivity : FlutterActivity() {

    private val channelName = "com.huankecontact.live/video_thumbnail"
    private val installChannelName = "com.huankecontact.live/app_install"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        createFCMNotificationChannel()
    }

    /** 创建 FCM 默认通知渠道（与 AndroidManifest 中 default_notification_channel_id 一致） */
    private fun createFCMNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channelId = "high_importance_channel"
        val channel = NotificationChannel(
            channelId,
            "Push Notifications",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "FCM push notifications"
            enableVibration(true)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        messenger = flutterEngine.dartExecutor.binaryMessenger

        // 应用更新：安装 APK（使用 FileProvider content URI，兼容 Android 7+）
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, installChannelName).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val path = call.argument<String>("path")
                if (path.isNullOrEmpty()) {
                    result.error("INVALID_ARGS", "path required", null)
                    return@setMethodCallHandler
                }
                try {
                    val file = File(path)
                    if (!file.exists()) {
                        result.error("FILE_NOT_FOUND", "APK file not found", null)
                        return@setMethodCallHandler
                    }
                    val authority = "${applicationContext.packageName}.fileProvider"
                    val uri: Uri = FileProvider.getUriForFile(this, authority, file)
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/vnd.android.package-archive")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("INSTALL_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }

        // 视频封面：getThumbnail
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "getThumbnail") {
                val videoPath = call.argument<String>("videoPath")
                val outputDir = call.argument<String>("outputDir")
                if (videoPath == null || outputDir == null) {
                    result.error("INVALID_ARGS", "videoPath and outputDir required", null)
                    return@setMethodCallHandler
                }
                try {
                    val retriever = MediaMetadataRetriever()
                    retriever.setDataSource(videoPath)
                    val bitmap = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                    retriever.release()
                    if (bitmap == null) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    val dir = File(outputDir)
                    if (!dir.exists()) dir.mkdirs()
                    val outFile = File(dir, "cover_${System.currentTimeMillis()}.jpg")
                    var os: OutputStream? = null
                    try {
                        os = FileOutputStream(outFile)
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, os)
                        os.flush()
                        result.success(outFile.absolutePath)
                    } finally {
                        os?.close()
                        if (!bitmap.isRecycled) bitmap.recycle()
                    }
                } catch (e: Exception) {
                    result.error("THUMBNAIL_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    companion object {
        private var messenger: io.flutter.plugin.common.BinaryMessenger? = null

        fun sendPushToken(token: String) {
            val binaryMessenger = messenger ?: return
            MethodChannel(binaryMessenger, "im_push_token").invokeMethod("onPushToken", token)
        }
    }
}
