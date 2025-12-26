package com.sairot

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "kiosk_settings"
    private var volumeButtonEventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isAudioModeEnabled = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Create EventChannel for volume button events
        volumeButtonEventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.sairot/volume_button_events"
        )

        volumeButtonEventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        // Create MethodChannel to receive audio mode state from Flutter
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.sairot/audio_mode"
        ).setMethodCallHandler { call, result ->
            if (call.method == "setAudioModeEnabled") {
                isAudioModeEnabled = call.arguments as? Boolean ?: false
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

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

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        // Intercept volume button presses when audio mode is enabled
        if (isAudioModeEnabled && (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN)) {
            eventSink?.success("volumeButtonDown")
            return true // Consume the event to prevent volume change
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        // Intercept volume button releases when audio mode is enabled
        if (isAudioModeEnabled && (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN)) {
            eventSink?.success("volumeButtonUp")
            return true // Consume the event to prevent volume change
        }
        return super.onKeyUp(keyCode, event)
    }
}