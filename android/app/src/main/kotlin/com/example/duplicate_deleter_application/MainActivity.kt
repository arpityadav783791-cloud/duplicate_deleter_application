package com.example.duplicate_deleter_application

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.StatFs
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "duplicate_deleter/storage"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "getStorageInfo" -> {
                    try {
                        val path = call.argument<String>("path")
                            ?: "/storage/emulated/0"

                        val stat = StatFs(path)

                        val totalBytes =
                            stat.blockCountLong * stat.blockSizeLong

                        val freeBytes =
                            stat.availableBlocksLong * stat.blockSizeLong

                        val usedBytes =
                            totalBytes - freeBytes

                        result.success(
                            mapOf(
                                "totalBytes" to totalBytes,
                                "usedBytes" to usedBytes,
                                "freeBytes" to freeBytes
                            )
                        )

                    } catch (e: Exception) {
                        result.error(
                            "STORAGE_ERROR",
                            "Unable to read storage.",
                            e.message
                        )
                    }
                }

                "openManageExternalStorage" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {

                            val intent = Intent(
                                Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                                Uri.parse("package:$packageName")
                            )

                            startActivity(intent)

                        } else {

                            val intent = Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.parse("package:$packageName")
                            )

                            startActivity(intent)
                        }

                        result.success(true)

                    } catch (e: Exception) {
                        result.error(
                            "SETTINGS_ERROR",
                            "Unable to open storage settings.",
                            e.message
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}