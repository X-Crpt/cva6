module ghash_tb;

    // Inputs
    logic [127:0] x, y;
    // Output
    logic [127:0] res;

    // Instantiate the module under test
    ghash dut (
        .x(x),
        .y(y),
        .res(res)
    );

    // Expected results
    typedef struct {
        logic [127:0] x;
        logic [127:0] y;
        logic [127:0] expected;
    } test_vector_t;

    test_vector_t tests [8];

    initial begin
        // Setup test vectors from provided list
        tests[0].x = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
        tests[0].y = 128'h00000000000000000000000000000000;
        tests[0].expected = 128'h00000000000000000000000000000000;

        tests[1].x = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
        tests[1].y = 128'h00000000000000000000000000000001;
        tests[1].expected = 128'h52a4dcb814e54ae1b2d2402fdc6eb849;

        tests[2].x = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
        tests[2].y = 128'h00000000000000000000000000000002;
        tests[2].expected = 128'ha549b97029ca95c365a4805fb8dd7092;

        tests[3].x = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
        tests[3].y = 128'h00000000000000000000000000000003;
        tests[3].expected = 128'hf7ed65c83d2fdf22d776c07064b3c8db;

        tests[4].x = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
        tests[4].y = 128'h00000000000000000000000000000004;
        tests[4].expected = 128'h889372e053952b86cb4900bf71bae125;

        tests[5].x = 128'hb83b533708bf535d0aa6e52980d53b78;
        tests[5].y = 128'h000000d3000000000000000000000000;
        tests[5].expected = 128'hdcb09a8c910b20dfc49373e09e9d4685;

        tests[6].x = 128'hb83b533708bf535d0aa6e52980d53b78;
        tests[6].y = 128'h000000d4000000000000000000000000;
        tests[6].expected = 128'hdbd10487604a53d5b2ea02c6f47c313c;

        tests[7].x = 128'hb83b533708bf535d0aa6e52980d53b78;
        tests[7].y = 128'h000000d5000000000000000000000000;
        tests[7].expected = 128'hdac7805ff03cf5bba394a47ce131fb6f;

        // Run tests
        for (int i = 0; i < 8; i++) begin
            x = tests[i].x;
            y = tests[i].y;

            #1; // Wait one delta cycle for combinational logic

            $display("Test %0d:", i);
            $display("  x        = %032x", x);
            $display("  y        = %032x", y);
            $display("  expected = %032x", tests[i].expected);
            $display("  got      = %032x", res);
            if (res === tests[i].expected) begin
                $display("  Result:   PASSED\n");
            end else begin
                $display("  Result:   FAILED\n");
            end
        end

        $finish;
    end

endmodule
