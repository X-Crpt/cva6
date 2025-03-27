import random

# 1) GF(2^128) multiplication with the GHASH reduction polynomial
def gf_2_128_mul(x, y):
    assert x < (1 << 128)
    assert y < (1 << 128)
    res = 0
    for i in range(127, -1, -1):
        if (y >> i) & 1:
            res ^= x
        # Multiply x by X in GF(2), shifting to the right by 1
        # if LSB is 1, we XOR with the reduction polynomial
        lsb = x & 1
        x >>= 1
        if lsb:
            x ^= 0xE1000000000000000000000000000000
    return res

def main():
    # 2) Prepare counters for bit statistics across 10,000 outputs
    # We'll track how many times each of the 128 bits is '1'
    num_outputs = 1000 * 10  # 1000 tests × 10 calls per test = 10,000 total outputs
    bit_counts = [0] * 128   # bit_counts[i] = how many times bit i was 1 across all outputs
    
    # 3) Open a file to log results (random x and the 10 outputs)
    # Adjust filename or logging as you prefer
    with open("test_results.txt", "w") as f:
        f.write("TestIndex,RandomX,CallIndex,Output\n")
        
        # 4) Run 1000 tests
        for test_index in range(1000):
            # Randomize x for this test (128-bit random)
            x = random.getrandbits(128)
            # Start y = 0
            y = x
            # Do 10 calls in a feedback manner
            for call_index in range(10):
                out = gf_2_128_mul(x, y)
                # Write result to file (hex representation for clarity)
                f.write(f"{test_index},{x:032x},{call_index},{out:032x}\n")
                # Update bit_counts
                for bit_pos in range(128):
                    # Check if bit_pos is 1 in 'out'
                    if (out >> bit_pos) & 1:
                        bit_counts[bit_pos] += 1
                # Feedback: next y becomes the current output
                y = out
    
    # 5) After collecting all 10,000 outputs, check uniformity
    # Each bit should be ~50% 1's. We'll check how close they are.
    # Example threshold: each bit in range [48%, 52%].
    lower_threshold = 0.48
    upper_threshold = 0.52
    
    # We can store or print summary of bit distribution
    print("=== Bit Distribution Summary ===")
    passes = True
    for bit_pos in range(128):
        # fraction of times this bit was '1'
        fraction_ones = bit_counts[bit_pos] / num_outputs
        # Print or log the fraction
        print(f"Bit {bit_pos:3d}: {fraction_ones*100:6.3f}%  (Count: {bit_counts[bit_pos]})")
        # Check thresholds
        if not (lower_threshold <= fraction_ones <= upper_threshold):
            passes = False
    
    if passes:
        print("\nAll bits pass the [48%, 52%] uniformity check.")
    else:
        print("\nSome bits are out of the [48%, 52%] range. Check distribution above.")

if __name__ == "__main__":
    main()
