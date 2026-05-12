#include <immintrin.h>

void saxpyStreaming(int N, float scale, float X[], float Y[], float result[]) {
    const __m256 scaleVec = _mm256_set1_ps(scale);

    int i = 0;
    for (; i + 7 < N; i += 8) {
        __m256 x = _mm256_load_ps(X + i);
        __m256 y = _mm256_load_ps(Y + i);
        __m256 value = _mm256_add_ps(_mm256_mul_ps(scaleVec, x), y);
        _mm256_stream_ps(result + i, value);
    }

    _mm_sfence();

    for (; i < N; i++) {
        result[i] = scale * X[i] + Y[i];
    }
}
