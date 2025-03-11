#include <stdint.h>
#include "aes_asm.h"
#include "trigger_auto.h"
#include "uart.h"

void print_uart_array(uint8_t *arr, size_t len) {
    for (size_t i = 0; i < len; i++) {
        print_uart_byte(arr[i]);
    }
    write_serial('\n'); // New line for readability
}

int main(int argc, char* arg[])
{

    uint8_t  key [16] = {0x2b ,0x7e ,0x15 ,0x16 ,0x28 ,0xae ,0xd2 ,0xa6 ,0xab ,0xf7 ,0x15 ,0x88 ,0x09 ,0xcf ,0x4f ,0x3c};
    uint8_t  pt  [16] = {0x32 ,0x43 ,0xf6 ,0xa8 ,0x88 ,0x5a ,0x30 ,0x8d ,0x31 ,0x31 ,0x98 ,0xa2 ,0xe0 ,0x37 ,0x07 ,0x34};
    uint8_t  ct  [16] = {0x39, 0x25, 0x84, 0x1D, 0x02, 0xDC, 0x09, 0xFB, 0xDC, 0x11, 0x85, 0x97, 0x19, 0x6A, 0x0B, 0x32};
    
    uint32_t volatile * trigger = (uint32_t*)TRIGGER_CTRL;
    

    *trigger = 1 << TRIGGER_CTRL_START;
    KeyExpansion_ENC(RoundKey, key);
    *trigger = 1 << TRIGGER_CTRL_STOP;
    
    print_uart_array(pt, 16);
    *trigger = 1 << TRIGGER_CTRL_START;
    AES_Cipher(pt, RoundKey);
    *trigger = 1 << TRIGGER_CTRL_STOP;
    print_uart_array(pt, 16);

    return 0;
}
