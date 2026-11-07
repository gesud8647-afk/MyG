#include "PocketBridge.h"
#include "llama.h"
#include <algorithm>
#include <atomic>
#include <climits>
#include <cstdio>
#include <cstring>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <string>
#include <vector>

struct pocket_engine {
    llama_model *model = nullptr;
    llama_context *context = nullptr;
    std::atomic<bool> cancelled{false};
    ~pocket_engine() {
        if (context) llama_free(context);
        if (model) llama_model_free(model);
    }
};

static void set_error(char *out, int32_t capacity, const char *message) {
    if (out && capacity > 0) std::snprintf(out, static_cast<size_t>(capacity), "%s", message);
}
static bool abort_decode(void *data) {
    return static_cast<pocket_engine *>(data)->cancelled.load();
}

extern "C" pocket_engine *pocket_create(const char *path, char *error, int32_t capacity) {
    try {
        static std::once_flag initialized;
        std::call_once(initialized, [] { llama_backend_init(); });
        auto engine = std::make_unique<pocket_engine>();
        llama_model_params mp = llama_model_default_params();
        mp.n_gpu_layers = 0;
        mp.use_mmap = true;
        engine->model = llama_model_load_from_file(path, mp);
        if (!engine->model) throw std::runtime_error("Impossibile caricare il GGUF. Usa Qwen3-0.6B ufficiale.");
        char architecture[64] = {0};
        llama_model_meta_val_str(engine->model, "general.architecture", architecture, sizeof(architecture));
        if (std::strcmp(architecture, "qwen3") != 0 || llama_model_n_params(engine->model) > 800000000ULL) {
            throw std::runtime_error("Questo prototipo accetta Qwen3 fino a 0.8B parametri. Usa Qwen3-0.6B.");
        }
        llama_context_params cp = llama_context_default_params();
        cp.n_ctx = 2048;
        cp.n_batch = 128;
        cp.n_ubatch = 128;
        cp.n_threads = 4;
        cp.n_threads_batch = 4;
        cp.offload_kqv = false;
        cp.abort_callback = abort_decode;
        cp.abort_callback_data = engine.get();
        engine->context = llama_init_from_model(engine->model, cp);
        if (!engine->context) throw std::runtime_error("Memoria insufficiente o contesto non inizializzabile. Chiudi altre app e riprova.");
        return engine.release();
    } catch (const std::exception &e) { set_error(error, capacity, e.what()); return nullptr; }
    catch (...) { set_error(error, capacity, "Errore nativo durante il caricamento."); return nullptr; }
}

extern "C" void pocket_destroy(pocket_engine *engine) { delete engine; }
extern "C" void pocket_prepare(pocket_engine *engine) { if (engine) engine->cancelled.store(false); }
extern "C" void pocket_cancel(pocket_engine *engine) { if (engine) engine->cancelled.store(true); }

static int32_t generate_impl(pocket_engine *engine, const char *prompt, int32_t max_tokens,
                             pocket_chunk_callback callback, void *user_data) {
    if (!engine || !prompt || !callback) throw std::runtime_error("Modello non caricato.");
    if (engine->cancelled.load()) return 1;
    max_tokens = std::max(32, std::min(384, max_tokens));
    const auto *vocab = llama_model_get_vocab(engine->model);
    const size_t length = std::strlen(prompt);
    if (length > 32000 || length > INT32_MAX) throw std::runtime_error("Messaggio troppo lungo.");
    int32_t needed = llama_tokenize(vocab, prompt, static_cast<int32_t>(length), nullptr, 0, true, true);
    if (needed >= 0 || needed == INT32_MIN) throw std::runtime_error("Tokenizzazione non riuscita.");
    needed = -needed;
    const int32_t limit = static_cast<int32_t>(llama_n_ctx(engine->context)) - max_tokens - 8;
    if (needed > limit) throw std::runtime_error("La chat supera il contesto disponibile: avvia una nuova chat o accorcia il messaggio.");
    std::vector<llama_token> tokens(static_cast<size_t>(needed));
    int32_t actual = llama_tokenize(vocab, prompt, static_cast<int32_t>(length), tokens.data(), needed, true, true);
    if (actual <= 0) throw std::runtime_error("Il modello non ha riconosciuto il testo.");
    tokens.resize(static_cast<size_t>(actual));
    llama_memory_clear(llama_get_memory(engine->context), true);
    // Preserve RAII cleanup even on cancellation or an exception.
    std::unique_ptr<llama_sampler, decltype(&llama_sampler_free)> sampler(
        llama_sampler_chain_init(llama_sampler_chain_default_params()), llama_sampler_free);
    if (!sampler) throw std::runtime_error("Sampler non inizializzato.");
    llama_sampler_chain_add(sampler.get(), llama_sampler_init_top_k(20));
    llama_sampler_chain_add(sampler.get(), llama_sampler_init_top_p(0.8f, 1));
    llama_sampler_chain_add(sampler.get(), llama_sampler_init_penalties(256, 1.05f, 0.0f, 1.5f));
    llama_sampler_chain_add(sampler.get(), llama_sampler_init_temp(0.7f));
    llama_sampler_chain_add(sampler.get(), llama_sampler_init_dist(LLAMA_DEFAULT_SEED));
    for (size_t offset = 0; offset < tokens.size(); offset += 128) {
        if (engine->cancelled.load()) return 1;
        const int32_t count = static_cast<int32_t>(std::min<size_t>(128, tokens.size() - offset));
        llama_batch batch = llama_batch_get_one(tokens.data() + offset, count);
        if (llama_decode(engine->context, batch) != 0) {
            if (engine->cancelled.load()) return 1;
            throw std::runtime_error("Errore nella lettura del prompt.");
        }
    }
    for (int32_t i = 0; i < max_tokens; ++i) {
        if (engine->cancelled.load()) return 1;
        llama_token next = llama_sampler_sample(sampler.get(), engine->context, -1);
        if (llama_vocab_is_eog(vocab, next)) return 0;
        char local[256];
        int32_t count = llama_token_to_piece(vocab, next, local, sizeof(local), 0, false);
        if (count < 0) {
            std::vector<char> expanded(static_cast<size_t>(-count));
            count = llama_token_to_piece(vocab, next, expanded.data(), static_cast<int32_t>(expanded.size()), 0, false);
            if (count < 0) throw std::runtime_error("Decodifica testo non riuscita.");
            if (count > 0 && !callback(expanded.data(), count, user_data)) return 1;
        } else if (count > 0 && !callback(local, count, user_data)) { return 1; }
        llama_batch batch = llama_batch_get_one(&next, 1);
        if (llama_decode(engine->context, batch) != 0) {
            if (engine->cancelled.load()) return 1;
            throw std::runtime_error("Generazione interrotta da un errore del motore.");
        }
    }
    return 2;
}

extern "C" int32_t pocket_generate(pocket_engine *engine, const char *prompt, int32_t max_tokens,
                                  pocket_chunk_callback callback, void *user_data,
                                  char *error, int32_t capacity) {
    try { return generate_impl(engine, prompt, max_tokens, callback, user_data); }
    catch (const std::exception &e) { set_error(error, capacity, e.what()); return -1; }
    catch (...) { set_error(error, capacity, "Errore nativo durante la risposta."); return -1; }
}
