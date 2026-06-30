package com.mirza.flutter_unified_image_picker

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileOutputStream

class FlutterUnifiedImagePickerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private lateinit var context: android.content.Context
    private var pendingResult: Result? = null
    private var activityBinding: ActivityPluginBinding? = null
    private val pickImagesRequestCode = 57001

    private val activityResultListener =
        PluginRegistry.ActivityResultListener { requestCode, resultCode, data ->
            if (requestCode != pickImagesRequestCode) {
                return@ActivityResultListener false
            }
            val result = pendingResult ?: return@ActivityResultListener false
            pendingResult = null
            if (resultCode == Activity.RESULT_OK) {
                val paths =
                    collectUris(data).mapNotNull { uri -> copyUriToCache(uri) }
                result.success(paths)
            } else {
                result.success(emptyList<String>())
            }
            true
        }

    override fun onAttachedToEngine(
        @NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding,
    ) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "app.gallery/images")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "pickImages" -> {
                val act = activity
                if (act == null) {
                    result.error("NO_ACTIVITY", "Plugin requires an Activity.", null)
                    return
                }
                if (pendingResult != null) {
                    result.error("ALREADY_ACTIVE", "Image picker is already active.", null)
                    return
                }
                val allowMultiple = call.argument<Boolean>("allowMultiple") ?: false
                pendingResult = result
                try {
                    act.startActivityForResult(buildPickIntent(allowMultiple), pickImagesRequestCode)
                } catch (e: Exception) {
                    pendingResult = null
                    result.error("PICKER_FAILED", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun buildPickIntent(allowMultiple: Boolean): Intent {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Intent(MediaStore.ACTION_PICK_IMAGES).apply {
                if (allowMultiple) {
                    putExtra(
                        MediaStore.EXTRA_PICK_IMAGES_MAX,
                        MediaStore.getPickImagesMaxLimit(),
                    )
                }
            }
        } else {
            Intent(Intent.ACTION_GET_CONTENT).apply {
                type = "image/*"
                addCategory(Intent.CATEGORY_OPENABLE)
                if (allowMultiple) {
                    putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                }
            }
        }
    }

    private fun collectUris(data: Intent?): List<Uri> {
        if (data == null) {
            return emptyList()
        }
        val uris = mutableListOf<Uri>()
        val clipData = data.clipData
        if (clipData != null) {
            for (i in 0 until clipData.itemCount) {
                uris.add(clipData.getItemAt(i).uri)
            }
        } else {
            data.data?.let { uris.add(it) }
        }
        return uris
    }

    private fun copyUriToCache(uri: Uri): String? {
        return try {
            val extension = context.contentResolver.getType(uri)
                ?.substringAfterLast('/')
                ?.takeIf { it.isNotBlank() }
                ?: "jpg"
            val file = File(
                context.cacheDir,
                "picked_${System.currentTimeMillis()}.$extension",
            )
            context.contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(file).use { output -> input.copyTo(output) }
            } ?: return null
            file.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(activityResultListener)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(activityResultListener)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    private fun detachActivity() {
        activityBinding?.removeActivityResultListener(activityResultListener)
        activityBinding = null
        activity = null
        pendingResult?.success(emptyList<String>())
        pendingResult = null
    }
}
