package com.example.suraksha_women_safety_app

import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val smsChannel = "suraksha/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, smsChannel).setMethodCallHandler { call, result ->
            if (call.method != "sendSms") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val phoneNumber = call.argument<String>("phoneNumber")
            val message = call.argument<String>("message")

            if (phoneNumber.isNullOrBlank() || message.isNullOrBlank()) {
                result.error("INVALID_SMS_ARGS", "Phone number and message are required.", null)
                return@setMethodCallHandler
            }

            try {
                val smsManager = SmsManager.getDefault()
                val parts = smsManager.divideMessage(message)
                smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null)
                result.success(true)
            } catch (error: Exception) {
                result.error("SMS_SEND_FAILED", error.message, null)
            }
        }
    }
}
