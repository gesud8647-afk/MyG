#ifndef POCKET_BRIDGE_H
#define POCKET_BRIDGE_H
#include <stdint.h>
#include <stdbool.h>
#ifdef __cplusplus
extern "C" {
#endif

typedef struct pocket_engine pocket_engine;
typedef bool (*pocket_chunk_callback)(const char *bytes, int32_t length, void *user_data);
pocket_engine *pocket_create(const char *path, char *error, int32_t error_capacity);
void pocket_destroy(pocket_engine *engine);
void pocket_prepare(pocket_engine *engine);
void pocket_cancel(pocket_engine *engine);
// 0 = end-of-response, 1 = cancelled, 2 = output limit, negative = error.
int32_t pocket_generate(pocket_engine *engine, const char *prompt, int32_t max_tokens,
                        pocket_chunk_callback callback, void *user_data,
                        char *error, int32_t error_capacity);
#ifdef __cplusplus
}
#endif
#endif
