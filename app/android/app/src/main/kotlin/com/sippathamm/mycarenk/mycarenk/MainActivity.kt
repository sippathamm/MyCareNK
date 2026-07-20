package com.sippathamm.mycarenk.mycarenk

import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.sippathamm.mycarenk/download"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "downloadApk" -> {
                        val url = call.argument<String>("url") ?: run {
                            result.error("INVALID_ARG", "url is required", null)
                            return@setMethodCallHandler
                        }
                        val fileName = call.argument<String>("fileName") ?: "MyCareNK_update.apk"
                        try {
                            result.success(startDownload(url, fileName))
                        } catch (e: Exception) {
                            result.error("DOWNLOAD_ERROR", e.message, null)
                        }
                    }
                    "getDownloadProgress" -> {
                        val id = (call.argument<Any>("downloadId") as? Number)?.toLong() ?: run {
                            result.error("INVALID_ARG", "downloadId is required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(queryProgress(id))
                        } catch (e: Exception) {
                            result.error("PROGRESS_ERROR", e.message, null)
                        }
                    }
                    "cancelDownload" -> {
                        val id = (call.argument<Any>("downloadId") as? Number)?.toLong() ?: run {
                            result.error("INVALID_ARG", "downloadId is required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            removeDownload(id)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("CANCEL_ERROR", e.message, null)
                        }
                    }
                    "openDownloadsFolder" -> {
                        try {
                            val intent = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startDownload(url: String, fileName: String): Long {
        val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        removeDownloadsByUrl(manager, url)
        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle("MyCareNK")
            .setDescription("กำลังดาวน์โหลดเวอร์ชันใหม่...")
            .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
            .setMimeType("application/vnd.android.package-archive")
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)
        return manager.enqueue(request)
    }

    private fun queryProgress(downloadId: Long): Map<String, Any> {
        val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val cursor = manager.query(DownloadManager.Query().setFilterById(downloadId))
        if (cursor.moveToFirst()) {
            val status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
            val downloaded = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
            val total = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))
            cursor.close()
            return mapOf("status" to status, "downloaded" to downloaded, "total" to total)
        }
        cursor.close()
        return mapOf("status" to DownloadManager.STATUS_FAILED, "downloaded" to 0L, "total" to 0L)
    }

    private fun removeDownload(downloadId: Long) {
        val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        manager.remove(downloadId)
    }

    private fun removeDownloadsByUrl(manager: DownloadManager, url: String) {
        val cursor = manager.query(DownloadManager.Query())
        val toRemove = mutableListOf<Long>()
        while (cursor.moveToNext()) {
            val colUrl = cursor.getColumnIndex(DownloadManager.COLUMN_URI)
            val colId = cursor.getColumnIndex(DownloadManager.COLUMN_ID)
            if (colUrl >= 0 && colId >= 0 && cursor.getString(colUrl) == url) {
                toRemove.add(cursor.getLong(colId))
            }
        }
        cursor.close()
        if (toRemove.isNotEmpty()) manager.remove(*toRemove.toLongArray())
    }
}
