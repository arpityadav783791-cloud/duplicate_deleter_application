package com.example.duplicate_deleter_application

import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "duplicate_deleter/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
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

                        val blockSize = stat.blockSizeLong
                        val totalBlocks = stat.blockCountLong
                        val availableBlocks = stat.availableBlocksLong

                        val totalBytes = totalBlocks * blockSize
                        val freeBytes = availableBlocks * blockSize
                        val usedBytes = totalBytes - freeBytes

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
                            "Unable to read storage information.",
                            e.message
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}