package com.lvzhiyi.jingtouben

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity(), ShareHostApi {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ShareHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, this)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        ShareHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, null)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun shareText(title: String, text: String, callback: (Result<Unit>) -> Unit) {
        if (isFinishing || isDestroyed) {
            callback(Result.failure(FlutterError("share_unavailable", "Activity unavailable")))
            return
        }
        try {
            val send = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_SUBJECT, title)
                putExtra(Intent.EXTRA_TITLE, title)
                putExtra(Intent.EXTRA_TEXT, text)
            }
            startActivity(Intent.createChooser(send, "分享分镜"))
        } catch (_: Exception) {
            // 不将原始异常或分享内容写入日志／回传。
            callback(Result.failure(FlutterError("share_failed", "Unable to open share sheet")))
            return
        }
        // 仅确认面板已打开，不代表用户已经发送；取消不会误报成功。
        callback(Result.success(Unit))
    }
}
