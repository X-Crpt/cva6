def gf_2_128_mul(x, y):
    assert x < (1 << 128)
    assert y < (1 << 128)
    res = 0
    for i in range(127, -1, -1):
        res ^= x * ((y >> i) & 1)
        x = (x >> 1) ^ ((x & 1) * 0xE1000000000000000000000000000000)
    assert res < (1 << 128)
    return res

def gf_2_128_mul_debug(x, y):
    assert x < (1 << 128)
    assert y < (1 << 128)

    res = 0
    print(f"Initial x = {x:032x}")
    print(f"Initial y = {y:032x}")
    print("-" * 100)

    for i in range(127, -1, -1):
        bit = (y >> i) & 1
        if bit:
            res ^= x
        print(f"i = {i:3d} | bit = {bit} | x = {x:032x} | res = {res:032x}")

        lsb = x & 1
        x >>= 1
        if lsb:
            # Reduction with the polynomial (E1...00 in hex)
            x ^= 0xE1000000000000000000000000000000
            print(f"      Reduction applied -> x = {x:032x}")

    assert res < (1 << 128)
    print("-" * 100)
    print(f"Final result: {res:032x}\n")
    return res

def run_test_vectors():
    test_vectors = [
        # (x, y, expected)
        ("66e94bd4ef8a2c3b884cfa59ca342b2e", "00000000000000000000000000000000", "00000000000000000000000000000000"),
        ("66e94bd4ef8a2c3b884cfa59ca342b2e", "00000000000000000000000000000001", "52a4dcb814e54ae1b2d2402fdc6eb849"),
        ("66e94bd4ef8a2c3b884cfa59ca342b2e", "00000000000000000000000000000002", "a549b97029ca95c365a4805fb8dd7092"),
        ("66e94bd4ef8a2c3b884cfa59ca342b2e", "00000000000000000000000000000003", "f7ed65c83d2fdf22d776c07064b3c8db"),
        ("66e94bd4ef8a2c3b884cfa59ca342b2e", "00000000000000000000000000000004", "889372e053952b86cb4900bf71bae125"),

        ("b83b533708bf535d0aa6e52980d53b78", "000000d3000000000000000000000000", "dcb09a8c910b20dfc49373e09e9d4685"),
        ("b83b533708bf535d0aa6e52980d53b78", "000000d4000000000000000000000000", "dbd10487604a53d5b2ea02c6f47c313c"),
        ("b83b533708bf535d0aa6e52980d53b78", "000000d5000000000000000000000000", "dac7805ff03cf5bba394a47ce131fb6f"),
    ]

    for x_hex, y_hex, expected_hex in test_vectors:
        x_val = int(x_hex, 16)
        y_val = int(y_hex, 16)
        expected_val = int(expected_hex, 16)
        
        #result_val = gf_2_128_mul(x_val, y_val)
        result_val = gf_2_128_mul_debug(x_val, y_val)
        result_hex = f"{result_val:032x}"

        print(f"Input X:      {x_hex}")
        print(f"Input Y:      {y_hex}")
        print(f"Expected:     {expected_hex}")
        print(f"Got:          {result_hex}")
        
        if result_val == expected_val:
            print("Result:       OK\n")
        else:
            print("Result:       MISMATCH!\n")

if __name__ == "__main__":
    run_test_vectors()
