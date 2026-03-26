import Flutter
import UIKit

@objc class LlamaPlugin: NSObject, FlutterPlugin {

    private var model: OpaquePointer?
    private var ctx: OpaquePointer?
    private let queue = DispatchQueue(label: "com.aihub.llama", qos: .userInitiated)

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "ai_hub/llama",
            binaryMessenger: registrar.messenger()
        )
        let instance = LlamaPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {
        case "loadModel":
            guard let path = args["path"] as? String else {
                return result(FlutterError(code: "ARG", message: "path required", details: nil))
            }
            queue.async {
                self.unload()
                var mp = llama_model_default_params()
                mp.n_gpu_layers = 0
                guard let m = llama_model_load_from_file(path, mp) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "LOAD", message: "Failed to load model", details: nil))
                    }
                    return
                }
                self.model = m
                var cp = llama_context_default_params()
                cp.n_ctx = 2048
                cp.n_threads = 4
                cp.n_threads_batch = 4
                guard let c = llama_init_from_model(m, cp) else {
                    llama_model_free(m)
                    self.model = nil
                    DispatchQueue.main.async {
                        result(FlutterError(code: "CTX", message: "Failed to create context", details: nil))
                    }
                    return
                }
                self.ctx = c
                DispatchQueue.main.async { result(true) }
            }

        case "generate":
            guard let prompt = args["prompt"] as? String else {
                return result(FlutterError(code: "ARG", message: "prompt required", details: nil))
            }
            guard let ctx = self.ctx, let model = self.model else {
                return result(FlutterError(code: "NO_MODEL", message: "Model not loaded", details: nil))
            }
            queue.async {
                let output = self.generate(ctx: ctx, model: model, prompt: prompt)
                DispatchQueue.main.async { result(output) }
            }

        case "unloadModel":
            queue.async {
                self.unload()
                DispatchQueue.main.async { result(nil) }
            }

        case "getFreeMemoryMB":
            let total = ProcessInfo.processInfo.physicalMemory / 1024 / 1024
            result(Int(total / 2))

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func generate(ctx: OpaquePointer, model: OpaquePointer, prompt: String) -> String {
        let maxTokens: Int32 = 512
        let vocab = llama_model_get_vocab(model)

        var tokens = [llama_token](repeating: 0, count: prompt.utf8.count + 16)
        let nTokens = llama_tokenize(vocab, prompt, Int32(prompt.utf8.count),
                                     &tokens, Int32(tokens.count), true, false)
        guard nTokens > 0 else { return "[tokenization failed]" }
        tokens = Array(tokens.prefix(Int(nTokens)))

        let mem = llama_get_memory(ctx)
        llama_memory_clear(mem, true)
        var batch = llama_batch_get_one(&tokens, nTokens)
        guard llama_decode(ctx, batch) == 0 else { return "[decode failed]" }

        let sparams = llama_sampler_chain_default_params()
        guard let sampler = llama_sampler_chain_init(sparams) else { return "[sampler init failed]" }
        llama_sampler_chain_add(sampler, llama_sampler_init_temp(0.7))
        llama_sampler_chain_add(sampler, llama_sampler_init_dist(1234))
        defer { llama_sampler_free(sampler) }

        var output = ""
        for _ in 0..<maxTokens {
            let tok = llama_sampler_sample(sampler, ctx, -1)
            if llama_vocab_is_eog(vocab, tok) { break }

            var buf = [CChar](repeating: 0, count: 256)
            let n = llama_token_to_piece(vocab, tok, &buf, Int32(buf.count), 0, false)
            if n > 0 {
                output += String(bytes: buf.prefix(Int(n)).map { UInt8(bitPattern: $0) }, encoding: .utf8) ?? ""
            }

            var nextTok = tok
            var nextBatch = llama_batch_get_one(&nextTok, 1)
            if llama_decode(ctx, nextBatch) != 0 { break }
        }
        return output
    }

    private func unload() {
        if let c = ctx { llama_free(c); ctx = nil }
        if let m = model { llama_model_free(m); model = nil }
    }
}
