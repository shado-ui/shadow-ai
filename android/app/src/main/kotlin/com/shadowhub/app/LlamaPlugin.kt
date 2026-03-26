package com.shadowhub.app

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*

class LlamaPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    // Pointer to native llama_context (stored as Long)
    private var modelPtr: Long = 0L
    private var ctxPtr: Long = 0L

    private var nativeLoaded = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "ai_hub/llama")
        channel.setMethodCallHandler(this)

        // Load the native library (optional - online models work without it)
        try {
            System.loadLibrary("llama_jni")
            nativeLoaded = true
        } catch (e: UnsatisfiedLinkError) {
            // Native lib not built - offline models won't work but online is fine
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
        if (ctxPtr != 0L) nativeFreeContext(ctxPtr)
        if (modelPtr != 0L) nativeFreeModel(modelPtr)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (!nativeLoaded && call.method != "getFreeMemoryMB") {
            return result.error("NATIVE_NOT_AVAILABLE",
                "Offline models not available. Use online models instead.", null)
        }

        when (call.method) {

            "loadModel" -> {
                val modelPath = call.argument<String>("modelPath") ?: return result.error("ARG", "modelPath required", null)
                val nThreads = call.argument<Int>("nThreads") ?: 4
                val nCtx = call.argument<Int>("nCtx") ?: 512

                scope.launch {
                    try {
                        // Free existing model if any
                        if (ctxPtr != 0L) { nativeFreeContext(ctxPtr); ctxPtr = 0L }
                        if (modelPtr != 0L) { nativeFreeModel(modelPtr); modelPtr = 0L }

                        modelPtr = nativeLoadModel(modelPath)
                        if (modelPtr == 0L) throw RuntimeException("Failed to load model from $modelPath")

                        ctxPtr = nativeCreateContext(modelPtr, nThreads, nCtx)
                        if (ctxPtr == 0L) throw RuntimeException("Failed to create llama context")

                        withContext(Dispatchers.Main) { result.success(true) }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) { result.error("LOAD_ERR", e.message, null) }
                    }
                }
            }

            "infer" -> {
                val prompt = call.argument<String>("prompt") ?: return result.error("ARG", "prompt required", null)
                val maxTokens = call.argument<Int>("maxTokens") ?: 256
                val temperature = call.argument<Double>("temperature") ?: 0.7

                if (ctxPtr == 0L) {
                    return result.error("NOT_LOADED", "Model not loaded. Call loadModel first.", null)
                }

                scope.launch {
                    try {
                        val response = nativeInfer(ctxPtr, prompt, maxTokens, temperature.toFloat())
                        withContext(Dispatchers.Main) { result.success(response) }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) { result.error("INFER_ERR", e.message, null) }
                    }
                }
            }

            "unloadModel" -> {
                scope.launch {
                    if (ctxPtr != 0L) { nativeFreeContext(ctxPtr); ctxPtr = 0L }
                    if (modelPtr != 0L) { nativeFreeModel(modelPtr); modelPtr = 0L }
                    withContext(Dispatchers.Main) { result.success(null) }
                }
            }

            "getFreeMemoryMB" -> {
                val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val info = ActivityManager.MemoryInfo()
                am.getMemoryInfo(info)
                val freeMB = (info.availMem / 1024 / 1024).toInt()
                result.success(freeMB)
            }

            else -> result.notImplemented()
        }
    }

    // ── Native JNI declarations ──────────────────────────────────────────────
    private external fun nativeLoadModel(modelPath: String): Long
    private external fun nativeCreateContext(modelPtr: Long, nThreads: Int, nCtx: Int): Long
    private external fun nativeInfer(ctxPtr: Long, prompt: String, maxTokens: Int, temperature: Float): String
    private external fun nativeFreeContext(ctxPtr: Long)
    private external fun nativeFreeModel(modelPtr: Long)
}
