// Copyright OpenHW Group contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
#include <stdint.h>
#include <stdio.h>
#include "uart.h"

uint8_t uart_read_byte_blocking(void)
{
    uint8_t c;
    while (!read_serial(&c)) {
        // busy-wait; optionally you can add a timeout or WFI
    }
    return c;
}

void write_reg_u8(uintptr_t addr, uint8_t value)
{
    volatile uint8_t *loc_addr = (volatile uint8_t *)addr;
    *loc_addr = value;
}

uint8_t read_reg_u8(uintptr_t addr)
{
    return *(volatile uint8_t *)addr;
}

int is_transmit_empty()
{
    return read_reg_u8(UART_LINE_STATUS) & 0x20;
}

int is_receive_empty()
{
    return !(read_reg_u8(UART_LINE_STATUS) & 0x1);
}

void write_serial(char a)
{
    while (is_transmit_empty() == 0) {};

    write_reg_u8(UART_THR, a);
}

int read_serial(uint8_t *res)
{
    if(is_receive_empty()) {
        return 0;
    }

    *res = read_reg_u8(UART_RBR);
    return 1;
}

void init_uart(uint32_t freq, uint32_t baud)
{
    uint32_t divisor = 27;//freq / (baud << 4);

    write_reg_u8(UART_INTERRUPT_ENABLE, 0x00); // Disable all interrupts
    write_reg_u8(UART_LINE_CONTROL, 0x80);     // Enable DLAB (set baud rate divisor)
    write_reg_u8(UART_DLAB_LSB, divisor);         // divisor (lo byte)
    write_reg_u8(UART_DLAB_MSB, (divisor >> 8) & 0xFF);  // divisor (hi byte)
    write_reg_u8(UART_LINE_CONTROL, 0x03);     // 8 bits, no parity, one stop bit
    write_reg_u8(UART_FIFO_CONTROL, 0xC7);     // Enable FIFO, clear them, with 14-byte threshold
    write_reg_u8(UART_MODEM_CONTROL, 0x20);    // Autoflow mode
}

void print_uart(const char *str)
{
    const char *cur = &str[0];
    while (*cur != '\0')
    {
        write_serial((uint8_t)*cur);
        ++cur;
    }
}

uint8_t bin_to_hex_table[16] = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

void bin_to_hex(uint8_t inp, uint8_t res[2])
{
    res[0] = bin_to_hex_table[(inp >> 4) & 0xf]; // high nibble
    res[1] = bin_to_hex_table[inp & 0xf];        // low nibble
    return;
}

void print_uart_int(uint32_t value)
{
    const char hex_table[] = "0123456789ABCDEF";
    char s[4];
    for (int i = 3; i >= 0; i--)
    {
        uint8_t byte = (value >> (i * 8)) & 0xFF;
        s[0] = hex_table[(byte >> 4) & 0xF];
        s[1] = hex_table[byte & 0xF];
        s[2] = ' ';
        s[3] = '\0';
        print_uart(s);
    }
}

void print_uart_addr(uint64_t addr)
{
    const char hex_table[] = "0123456789ABCDEF";
    char s[4];
    for (int i = 7; i >= 0; i--)
    {
        uint8_t byte = (addr >> (i * 8)) & 0xFF;
        s[0] = hex_table[(byte >> 4) & 0xF];
        s[1] = hex_table[byte & 0xF];
        s[2] = ' ';
        s[3] = '\0';
        print_uart(s);
    }
}

// void print_uart_byte(uint8_t byte)
// {
//     uint8_t hex[2];
//     bin_to_hex(byte, hex);
//     write_serial(hex[0]);
//     write_serial(hex[1]);
// }
void print_uart_byte(uint8_t byte)
{
    const char hex_table[] = "0123456789ABCDEF";
    char s[4];
    s[0] = hex_table[(byte >> 4) & 0xF];
    s[1] = hex_table[byte & 0xF];
    s[2] = ' ';
    s[3] = '\0';
    print_uart(s);   // print_uart will call write_serial for each char reliably
}