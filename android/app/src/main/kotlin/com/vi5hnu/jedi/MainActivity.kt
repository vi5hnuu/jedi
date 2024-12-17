package com.vi5hnu.jedi

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.channel.shared.data"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState) // Fixed syntax error: added closing parenthesis.

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getSharedFile") {
                    val intent: Intent? = intent
                    val uri = intent?.data
                    val filePath: String? = uri?.path
                    result.success(filePath)
                } else {
                    result.notImplemented()
                }
            }
    }
}
