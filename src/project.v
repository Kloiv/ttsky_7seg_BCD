// /*
//  * Copyright (c) 2024 Your Name
//  * SPDX-License-Identifier: Apache-2.0
//  */

// `default_nettype none

// module tt_um_example (
//     input  wire [7:0] ui_in,    // Dedicated inputs
//     output wire [7:0] uo_out,   // Dedicated outputs
//     input  wire [7:0] uio_in,   // IOs: Input path
//     output wire [7:0] uio_out,  // IOs: Output path
//     output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
//     input  wire       ena,      // always 1 when the design is powered, so you can ignore it
//     input  wire       clk,      // clock
//     input  wire       rst_n     // reset_n - low to reset
// );

//   // All output pins must be assigned. If not used, assign to 0.
//   //assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
//   assign uio_out = 0;
//   assign uio_oe  = 0;

//   // List all unused inputs to prevent warnings
//   wire _unused = &{ena, clk, rst_n, 1'b0};

// endmodule

/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_Contador_Completo (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // ==========================================
    // 1. CABLES INTERNOS
    // ==========================================
    wire [6:0] w_seg_out;    
    wire [2:0] w_digit_sel;
    wire       enable;     

    // ==========================================
    // 2. CONEXIONES
    // ==========================================
    
    // Conectamos la entrada 0 al cable de enable
    assign enable = ui_in[0]; 

    assign uo_out = {1'b0, w_seg_out};
    assign uio_out = {5'b00000, w_digit_sel};
    assign uio_oe  = 8'b00000111;

    wire _unused = &{ena, ui_in[7:1], uio_in, 1'b0}; // ui_in[0] ya no es "unused"

    // ==========================================
    // 3. INSTANCIACIÓN
    // ==========================================
    
    Contador_Completo Contador_Completo_Unit (
        .clk(clk),           
        .rst(rst_n),
        .enable(w_enable),      // <--- AQUI CONECTAMOS EL ENABLE
        .seg_out(w_seg_out), 
        .digit_sel(w_digit_sel) 
    );

endmodule
