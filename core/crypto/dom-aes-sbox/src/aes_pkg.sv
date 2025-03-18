package aes_pkg;

typedef struct packed {
    logic [3:0] AA;
    logic [3:0] AB;
    logic [3:0] BB;
    logic [3:0] BA;
}gf16_mult_t;

typedef struct packed {
    logic [3:0] shareA;
    logic [3:0] shareB;
} gf16_mult_res_t;

typedef struct packed {
    logic [1:0] AA;
    logic [1:0] AB;
    logic [1:0] BB;
    logic [1:0] BA;
}gf4_mult_t;

typedef struct packed {
    logic [1:0] shareA;
    logic [1:0] shareB;
} gf4_mult_res_t;

typedef struct packed {
    logic [3:0] shareA;
    logic [3:0] shareB;
} gf16_inversion_t;


endpackage