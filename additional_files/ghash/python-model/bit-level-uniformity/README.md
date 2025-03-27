# Randomness Uniformity Check

## Overview
This project verifies the uniformity of a 128-bit random output by checking the distribution of 1s and 0s across multiple samples. The goal is to ensure each bit position in the output is approximately 50% 1s and 50% 0s.

## Steps
### 1. Collect a Large Sample
Generate at least **10,000** random 128-bit outputs, resulting in **1.28 million bits**.

### 2. Count 1s vs 0s per Bit Position
For each of the **128-bit positions**, count how often the bit is `1` over all **10,000 samples**.

### 3. Estimate Statistical Fluctuation
Each bit position follows a **binomial distribution** `B(n, 0.5)`, where:
- `n = 10,000` samples
- Expected mean: `n × 0.5 = 5,000`
- Standard deviation: `σ = sqrt(n × 0.5 × 0.5) = sqrt(10,000 × 0.25) = 50`

### 4. Choose a Threshold
Define an acceptance range around 50%:
- **±2σ (95% confidence):** 49% – 51% (4,900 to 5,100 ones)
- **±3σ (99.7% confidence):** 48.5% – 51.5% (4,850 to 5,150 ones)
- **Typical practical choice:** 48% – 52% (roughly ±2.5σ)

### 5. Evaluate Each Bit Position
For each bit position (0 to 127):
- Compute `count_of_ones / 10,000 × 100%`
- If within **chosen range** (e.g., 48%–52%), mark as "pass"
- If **all** 128-bit positions pass, the sample run is "good"

## Considerations for Deeper Testing
While this test checks basic uniformity, cryptographic-quality randomness requires further validation using:
- **NIST SP 800-22 test suite**
- **Diehard tests**
- Other statistical measures (autocorrelation, runs, linear complexity, etc.)

This quick check provides a first-step verification of bit-level uniformity in random number generation.
