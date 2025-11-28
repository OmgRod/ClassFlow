package com.example.misplace_no_more

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import androidx.annotation.NonNull
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "detention_safe"
	private val REQUEST_CODE_PICK_DIR = 42424
	private var pendingResult: MethodChannel.Result? = null

	override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"pickDirectory" -> {
					if (pendingResult != null) {
						result.error("busy", "Picker already running", null)
						return@setMethodCallHandler
					}
					pendingResult = result
					val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
					// Optionally persist permissions
					startActivityForResult(intent, REQUEST_CODE_PICK_DIR)
				}
				"saveFileToUri" -> {
					try {
						val treeUri = call.argument<String>("treeUri")
						val filename = call.argument<String>("filename")
						val bytes = call.argument<ByteArray>("bytes")
						if (treeUri == null || filename == null || bytes == null) {
							result.error("invalid_args", "Missing args", null)
							return@setMethodCallHandler
						}
						val tree = Uri.parse(treeUri)
						val doc = DocumentFile.fromTreeUri(this, tree)
						val created = doc?.createFile("application/octet-stream", filename)
						if (created == null) {
							result.error("create_failed", "Failed to create file in tree", null)
							return@setMethodCallHandler
						}
						contentResolver.openOutputStream(created.uri).use { os ->
							if (os == null) {
								result.error("open_failed", "Failed to open output stream", null)
								return@setMethodCallHandler
							}
							os.write(bytes)
							os.flush()
						}
						result.success(true)
					} catch (e: Exception) {
						result.error("exception", e.message, null)
					}
				}
				"saveBytesToDownloads" -> {
					try {
						val filename = call.argument<String>("filename")
						val mime = call.argument<String>("mime") ?: "application/octet-stream"
						val bytes = call.argument<ByteArray>("bytes")
						if (filename == null || bytes == null) {
							result.error("invalid_args", "Missing args", null)
							return@setMethodCallHandler
						}

						val resolver = contentResolver
						val values = ContentValues().apply {
							put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
							put(MediaStore.MediaColumns.MIME_TYPE, mime)
							if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
								put(MediaStore.MediaColumns.RELATIVE_PATH, "Download/")
							}
						}

						val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
							MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
						} else {
							MediaStore.Files.getContentUri("external")
						}

						val uri = resolver.insert(collection, values)
						if (uri == null) {
							result.error("insert_failed", "Failed to insert into MediaStore", null)
							return@setMethodCallHandler
						}

						resolver.openOutputStream(uri).use { os ->
							if (os == null) {
								result.error("open_failed", "Failed to open output stream", null)
								return@setMethodCallHandler
							}
							os.write(bytes)
							os.flush()
						}

						result.success(true)
					} catch (e: Exception) {
						result.error("exception", e.message, null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
		super.onActivityResult(requestCode, resultCode, data)
		if (requestCode == REQUEST_CODE_PICK_DIR) {
			val result = pendingResult
			pendingResult = null
			if (resultCode == Activity.RESULT_OK && data != null) {
				val tree = data.data
				// Persist URI permission so app can write later
				try {
					val takeFlags = (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
					contentResolver.takePersistableUriPermission(tree!!, takeFlags)
				} catch (_: Exception) {
				}
				result?.success(tree.toString())
			} else {
				result?.success(null)
			}
		}
	}
}
