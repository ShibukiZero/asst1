#include <immintrin.h>
#include <math.h>

void sqrtAVX2(int N, float initialGuess, float values[], float output[]) {
    static const float kThreshold = 0.00001f;

    const __m256 threshold = _mm256_set1_ps(kThreshold);
    const __m256 three = _mm256_set1_ps(3.f);
    const __m256 half = _mm256_set1_ps(0.5f);
    const __m256 one = _mm256_set1_ps(1.f);
    const __m256 absMask =
        _mm256_castsi256_ps(_mm256_set1_epi32(0x7fffffff));

    int i = 0;
    for (; i + 7 < N; i += 8) {
        __m256 x = _mm256_loadu_ps(values + i);
        __m256 guess = _mm256_set1_ps(initialGuess);

        __m256 error = _mm256_and_ps(
            _mm256_sub_ps(_mm256_mul_ps(_mm256_mul_ps(guess, guess), x), one),
            absMask);
        __m256 active = _mm256_cmp_ps(error, threshold, _CMP_GT_OQ);

        while (_mm256_movemask_ps(active) != 0) {
            __m256 guess2 = _mm256_mul_ps(guess, guess);
            __m256 guess3 = _mm256_mul_ps(guess2, guess);
            __m256 next = _mm256_mul_ps(
                _mm256_sub_ps(_mm256_mul_ps(three, guess),
                              _mm256_mul_ps(x, guess3)),
                half);

            guess = _mm256_blendv_ps(guess, next, active);

            error = _mm256_and_ps(
                _mm256_sub_ps(
                    _mm256_mul_ps(_mm256_mul_ps(guess, guess), x), one),
                absMask);
            active = _mm256_cmp_ps(error, threshold, _CMP_GT_OQ);
        }

        _mm256_storeu_ps(output + i, _mm256_mul_ps(x, guess));
    }

    for (; i < N; i++) {
        float x = values[i];
        float guess = initialGuess;
        float error = fabsf(guess * guess * x - 1.f);

        while (error > kThreshold) {
            guess = (3.f * guess - x * guess * guess * guess) * 0.5f;
            error = fabsf(guess * guess * x - 1.f);
        }

        output[i] = x * guess;
    }
}
