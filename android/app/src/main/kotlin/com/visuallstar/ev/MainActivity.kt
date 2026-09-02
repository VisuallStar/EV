package com.visuallstar.ev

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.Uri
import android.hardware.camera2.CameraManager
import android.content.Context
import android.media.AudioManager
import android.provider.AlarmClock
import android.content.ContentValues
import android.provider.MediaStore
import android.graphics.Bitmap
import android.os.Build

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ev/accessibility"
    private val DEVICE_CHANNEL = "com.ev/device_actions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registerAccessibilityChannel(flutterEngine, this)
        registerDeviceActionsChannel(flutterEngine, this)
    }

    companion object {
        fun registerAccessibilityChannel(flutterEngine: FlutterEngine, context: Context) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ev/accessibility")
                .setMethodCallHandler { call, result ->
                    android.util.Log.d("EVKotlin", "Received method call: ${call.method}")
                    when (call.method) {
                        "ping" -> result.success(true)

                        "logToNative" -> {
                            val msg = call.argument<String>("message") ?: ""
                            android.util.Log.d("EVDart", msg)
                            result.success(true)
                        }

                        "isServiceRunning" -> {
                            result.success(EVAccessibilityService.isRunning())
                        }

                        "openAccessibilitySettings" -> {
                            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            context.startActivity(intent)
                            result.success(true)
                        }

                        "dumpScreen" -> {
                            val service = EVAccessibilityService.instance
                            if (service == null) {
                                result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                            } else {
                                val nodes = service.dumpScreen()
                                result.success(nodes)
                            }
                        }

                        "takeScreenshot" -> {
                            val service = EVAccessibilityService.instance
                            if (service == null) {
                                result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                            } else {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                    service.takeScreenshot { base64 ->
                                        if (base64 != null) {
                                            result.success(base64)
                                        } else {
                                            result.error("SCREENSHOT_FAILED", "Failed to capture screenshot", null)
                                        }
                                    }
                                } else {
                                    result.error("UNSUPPORTED_VERSION", "Screenshot requires Android 11+", null)
                                }
                            }
                        }

                        "clickByText" -> {
                            val text = call.argument<String>("text") ?: ""
                            val service = EVAccessibilityService.instance
                            if (service == null) {
                                result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                            } else {
                                result.success(service.clickByText(text))
                            }
                        }

                        "clickAt" -> {
                            val x = call.argument<Double>("x")?.toFloat() ?: 0f
                            val y = call.argument<Double>("y")?.toFloat() ?: 0f
                            val service = EVAccessibilityService.instance
                            if (service == null) {
                                result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                            } else {
                                result.success(service.clickAtCoordinates(x, y))
                            }
                        }

                        "typeText" -> {
                            val text = call.argument<String>("text") ?: ""
                            val hint = call.argument<String>("fieldHint")
                            val service = EVAccessibilityService.instance
                            if (service == null) {
                                result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                            } else {
                                result.success(service.typeText(text, hint))
                            }
                        }

                        "pressEnter" -> {
                            val service = EVAccessibilityService.instance
                            if (service == null) {
                                result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                            } else {
                                result.success(service.pressEnter())
                            }
                        }

                        "scroll" -> {
                            val direction = call.argument<String>("direction") ?: "down"
                            val target = call.argument<String>("target")
                            val service = EVAccessibilityService.instance
                            if (service == null) {
                                result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                            } else {
                                result.success(service.scroll(direction, target))
                            }
                        }

                        "showToast" -> {
                            val message = call.argument<String>("message") ?: ""
                            android.widget.Toast.makeText(context, message, android.widget.Toast.LENGTH_SHORT).show()
                            result.success(true)
                        }

                        "swipe" -> {
                            val startX = call.argument<Double>("startX")?.toFloat() ?: 0f
                            val startY = call.argument<Double>("startY")?.toFloat() ?: 0f
                            val endX = call.argument<Double>("endX")?.toFloat() ?: 0f
                            val endY = call.argument<Double>("endY")?.toFloat() ?: 0f
                            val service = EVAccessibilityService.instance
                            if (service == null) {
                                result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                            } else {
                                result.success(service.swipe(startX, startY, endX, endY))
                            }
                        }

                        "pressBack" -> {
                            val service = EVAccessibilityService.instance
                            if (service == null) {
                                result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                            } else {
                                result.success(service.pressBack())
                            }
                        }

                        "pressHome" -> {
                            val service = EVAccessibilityService.instance
                            if (service == null) {
                                result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                            } else {
                                result.success(service.pressHome())
                            }
                        }

                        "openNotifications" -> {
                            val service = EVAccessibilityService.instance
                            if (service == null) {
                                result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                            } else {
                                result.success(service.openNotifications())
                            }
                        }

                        "getCurrentPackage" -> {
                            val service = EVAccessibilityService.instance
                            if (service == null) {
                                result.error("SERVICE_NOT_RUNNING", "Accessibility service is not running", null)
                            } else {
                                result.success(service.getCurrentPackage())
                            }
                        }

                        else -> result.notImplemented()
                    }
                }
        }

        fun registerDeviceActionsChannel(flutterEngine: FlutterEngine, context: Context) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ev/device_actions")
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "toggleFlash" -> {
                            val state = call.argument<String>("state") ?: "off"
                            try {
                                val cm = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
                                val ids = cm.cameraIdList
                                if (ids.isNotEmpty()) {
                                    cm.setTorchMode(ids[0], state == "on")
                                    result.success("Flashlight $state")
                                } else {
                                    result.error("NO_CAMERA", "No camera found", null)
                                }
                            } catch (e: Exception) {
                                result.error("FLASH_ERROR", "Flashlight error: ${e.message}", null)
                            }
                        }

                        "setScreenTimeout" -> {
                            val seconds = call.argument<Int>("seconds") ?: 30
                            try {
                                if (Settings.System.canWrite(context)) {
                                    Settings.System.putInt(
                                        context.contentResolver,
                                        Settings.System.SCREEN_OFF_TIMEOUT,
                                        seconds * 1000
                                    )
                                    result.success("Screen timeout set to $seconds seconds")
                                } else {
                                    val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                                    intent.data = Uri.parse("package:${context.packageName}")
                                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    context.startActivity(intent)
                                    result.error("PERMISSION_NEEDED", "Please allow write settings permission", null)
                                }
                            } catch (e: Exception) {
                                result.error("TIMEOUT_ERROR", "Screen timeout error: ${e.message}", null)
                            }
                        }

                        "youtubeSearch" -> {
                            val query = call.argument<String>("query") ?: ""
                            try {
                                val intent = Intent(
                                    Intent.ACTION_VIEW,
                                    Uri.parse("https://www.youtube.com/results?search_query=" + Uri.encode(query))
                                )
                                intent.setPackage("com.google.android.youtube")
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                context.startActivity(intent)
                                result.success("Searching YouTube for $query")
                            } catch (e: Exception) {
                                // Fallback to browser
                                val fallback = Intent(
                                    Intent.ACTION_VIEW,
                                    Uri.parse("https://www.youtube.com/results?search_query=" + Uri.encode(query))
                                )
                                fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                context.startActivity(fallback)
                                result.success("Searching YouTube for $query (browser)")
                            }
                        }

                        "setBrightnessNative" -> {
                            val value = call.argument<Int>("value") ?: 128
                            try {
                                if (Settings.System.canWrite(context)) {
                                    Settings.System.putInt(
                                        context.contentResolver,
                                        Settings.System.SCREEN_BRIGHTNESS,
                                        value.coerceIn(0, 255)
                                    )
                                    result.success("Brightness set to ${value * 100 / 255}%")
                                } else {
                                    val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                                    intent.data = Uri.parse("package:${context.packageName}")
                                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    context.startActivity(intent)
                                    result.error("PERMISSION_NEEDED", "Please allow write settings permission", null)
                                }
                            } catch (e: Exception) {
                                result.error("BRIGHTNESS_ERROR", "Brightness error: ${e.message}", null)
                            }
                        }

                        "setVolumeNative" -> {
                            val level = call.argument<Int>("level") ?: 50
                            try {
                                val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                                val maxVol = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                                val vol = (level * maxVol / 100).coerceIn(0, maxVol)
                                am.setStreamVolume(AudioManager.STREAM_MUSIC, vol, AudioManager.FLAG_SHOW_UI)
                                result.success("Volume set to $level%")
                            } catch (e: Exception) {
                                result.error("VOLUME_ERROR", "Volume error: ${e.message}", null)
                            }
                        }

                        "setAlarmDirect" -> {
                            val hour = call.argument<Int>("hour") ?: 0
                            val minute = call.argument<Int>("minute") ?: 0
                            val label = call.argument<String>("label") ?: ""
                            try {
                                val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                                    putExtra(AlarmClock.EXTRA_HOUR, hour)
                                    putExtra(AlarmClock.EXTRA_MINUTES, minute)
                                    if (label.isNotEmpty()) putExtra(AlarmClock.EXTRA_MESSAGE, label)
                                    putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                context.startActivity(intent)
                                result.success("Alarm set for ${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}")
                            } catch (e: Exception) {
                                result.error("ALARM_ERROR", "Alarm error: ${e.message}", null)
                            }
                        }

                        "setTimerDirect" -> {
                            val seconds = call.argument<Int>("seconds") ?: 60
                            val label = call.argument<String>("label") ?: ""
                            try {
                                val intent = Intent(AlarmClock.ACTION_SET_TIMER).apply {
                                    putExtra(AlarmClock.EXTRA_LENGTH, seconds)
                                    if (label.isNotEmpty()) putExtra(AlarmClock.EXTRA_MESSAGE, label)
                                    putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                context.startActivity(intent)
                                result.success("Timer set for ${seconds / 60}m ${seconds % 60}s")
                            } catch (e: Exception) {
                                result.error("TIMER_ERROR", "Timer error: ${e.message}", null)
                            }
                        }

                        "shareImage" -> {
                            val path = call.argument<String>("path") ?: ""
                            val packageName = call.argument<String>("package") ?: ""
                            try {
                                val file = java.io.File(path)
                                val uri = androidx.core.content.FileProvider.getUriForFile(
                                    context,
                                    "${context.packageName}.provider",
                                    file
                                )
                                val intent = Intent(Intent.ACTION_SEND).apply {
                                    type = "image/*"
                                    putExtra(Intent.EXTRA_STREAM, uri)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    if (packageName.isNotEmpty()) setPackage(packageName)
                                }
                                context.startActivity(Intent.createChooser(intent, "Share via").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                                result.success("Sharing image")
                            } catch (e: Exception) {
                                result.error("SHARE_ERROR", "Share error: ${e.message}", null)
                            }
                        }

                        "makeDirectCall" -> {
                            val number = call.argument<String>("number") ?: ""
                            try {
                                val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$number"))
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                context.startActivity(intent)
                                result.success("Calling $number")
                            } catch (e: Exception) {
                                result.error("CALL_ERROR", "Call error: ${e.message}", null)
                            }
                        }

                        "openWhatsApp" -> {
                            val number = call.argument<String>("number") ?: ""
                            val message = call.argument<String>("message") ?: ""
                            try {
                                val url = if (number.isNotEmpty()) {
                                    "https://api.whatsapp.com/send?phone=$number&text=${Uri.encode(message)}"
                                } else {
                                    "https://api.whatsapp.com/send?text=${Uri.encode(message)}"
                                }
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                                intent.setPackage("com.whatsapp")
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                context.startActivity(intent)
                                result.success("Opening WhatsApp")
                            } catch (e: Exception) {
                                result.error("WA_ERROR", "WhatsApp error: ${e.message}", null)
                            }
                        }

                        else -> result.notImplemented()
                    }
                }
        }
    }
}
