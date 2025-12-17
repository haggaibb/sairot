package com.example.sairot

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "kiosk_settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getAndroidId" -> {
                            val androidId = Settings.Secure.getString(
                                contentResolver,
                                Settings.Secure.ANDROID_ID
                            )
                            result.success(androidId)
                        }

                        "openKioskSettings" -> {
                            val intent = Intent().apply {
                                component = ComponentName(
                                    "com.manageengine.mdm.android",
                                    "com.manageengine.mdm.framework.kiosk.KioskSettingsActivity"
                                )
                            }
                            startActivity(intent)
                            result.success(true)
                        }

                        "openWifiPicker" -> {
                            val intent = Intent().apply {
                                component = ComponentName(
                                    "com.manageengine.mdm.android",
                                    "com.manageengine.mdm.framework.customsettings.WifiPickerActivity"
                                )
                            }
                            startActivity(intent)
                            result.success(true)
                        }

                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("INTENT_FAILED", e.message, null)
                }
            }
    }
}