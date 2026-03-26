#include <jni.h>
#include <string>
#include <sstream>
#include <android/log.h>

// Include llama.cpp headers (placed in jni/llama.cpp/ submodule)
#include "llama.cpp/llama.h"
#include "llama.cpp/common/common.h"

#define LOG_TAG "LlamaJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

extern "C" {

// ── Load model ───────────────────────────────────────────────────────────────
JNIEXPORT jlong JNICALL
Java_com_shadowhub_app_LlamaPlugin_nativeLoadModel(
        JNIEnv *env, jobject /* this */, jstring modelPathJ) {

    const char *modelPath = env->GetStringUTFChars(modelPathJ, nullptr);
    LOGI("Loading model: %s", modelPath);

    llama_model_params mparams = llama_model_default_params();
    mparams.n_gpu_layers = 0; // CPU-only for mobile

    llama_model *model = llama_load_model_from_file(modelPath, mparams);
    env->ReleaseStringUTFChars(modelPathJ, modelPath);

    if (!model) {
        LOGE("Failed to load model");
        return 0L;
    }

    LOGI("Model loaded successfully");
    return reinterpret_cast<jlong>(model);
}

// ── Create context ───────────────────────────────────────────────────────────
JNIEXPORT jlong JNICALL
Java_com_shadowhub_app_LlamaPlugin_nativeCreateContext(
        JNIEnv * /* env */, jobject /* this */,
        jlong modelPtr, jint nThreads, jint nCtx) {

    auto *model = reinterpret_cast<llama_model *>(modelPtr);

    llama_context_params cparams = llama_context_default_params();
    cparams.n_ctx     = (uint32_t) nCtx;
    cparams.n_threads = (uint32_t) nThreads;
    cparams.n_threads_batch = (uint32_t) nThreads;

    llama_context *ctx = llama_new_context_with_model(model, cparams);
    if (!ctx) {
        LOGE("Failed to create context");
        return 0L;
    }

    LOGI("Context created (ctx=%d, threads=%d)", nCtx, nThreads);
    return reinterpret_cast<jlong>(ctx);
}

// ── Inference ────────────────────────────────────────────────────────────────
JNIEXPORT jstring JNICALL
Java_com_shadowhub_app_LlamaPlugin_nativeInfer(
        JNIEnv *env, jobject /* this */,
        jlong ctxPtr, jstring promptJ, jint maxTokens, jfloat temperature) {

    auto *ctx   = reinterpret_cast<llama_context *>(ctxPtr);
    auto *model = llama_get_model(ctx);

    const char *promptStr = env->GetStringUTFChars(promptJ, nullptr);
    std::string prompt(promptStr);
    env->ReleaseStringUTFChars(promptJ, promptStr);

    // Tokenize
    std::vector<llama_token> tokens(prompt.size() + 8);
    int nTokens = llama_tokenize(
        model, prompt.c_str(), (int) prompt.size(),
        tokens.data(), (int) tokens.size(),
        /*add_bos=*/true, /*special=*/false
    );
    if (nTokens < 0) {
        LOGE("Tokenization failed");
        return env->NewStringUTF("[Error: tokenization failed]");
    }
    tokens.resize(nTokens);

    // Reset KV cache and evaluate prompt
    llama_kv_cache_clear(ctx);

    llama_batch batch = llama_batch_get_one(tokens.data(), nTokens);
    if (llama_decode(ctx, batch) != 0) {
        LOGE("llama_decode (prompt) failed");
        return env->NewStringUTF("[Error: decode failed]");
    }

    // Sampling params
    auto sparams = llama_sampler_chain_default_params();
    llama_sampler *sampler = llama_sampler_chain_init(sparams);
    llama_sampler_chain_add(sampler, llama_sampler_init_temp(temperature));
    llama_sampler_chain_add(sampler, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));

    // Generate tokens
    std::string output;
    for (int i = 0; i < maxTokens; i++) {
        llama_token tok = llama_sampler_sample(sampler, ctx, -1);

        if (llama_token_is_eog(model, tok)) break;

        char buf[256];
        int n = llama_token_to_piece(model, tok, buf, sizeof(buf), 0, false);
        if (n > 0) output.append(buf, n);

        // Feed token back
        llama_batch next = llama_batch_get_one(&tok, 1);
        if (llama_decode(ctx, next) != 0) break;
    }

    llama_sampler_free(sampler);

    LOGI("Generated %zu chars", output.size());
    return env->NewStringUTF(output.c_str());
}

// ── Free context ─────────────────────────────────────────────────────────────
JNIEXPORT void JNICALL
Java_com_shadowhub_app_LlamaPlugin_nativeFreeContext(
        JNIEnv * /* env */, jobject /* this */, jlong ctxPtr) {
    llama_free(reinterpret_cast<llama_context *>(ctxPtr));
    LOGI("Context freed");
}

// ── Free model ───────────────────────────────────────────────────────────────
JNIEXPORT void JNICALL
Java_com_shadowhub_app_LlamaPlugin_nativeFreeModel(
        JNIEnv * /* env */, jobject /* this */, jlong modelPtr) {
    llama_free_model(reinterpret_cast<llama_model *>(modelPtr));
    LOGI("Model freed");
}

} // extern "C"
