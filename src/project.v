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

    // Estos cables llevan las señales desde tu módulo hacia los pines de salida
    wire [6:0] w_seg_out;    // Cable para los segmentos
    wire [2:0] w_digit_sel;  // Cable para el selector de dígitos

    
    // Conectamos los segmentos (7 bits) a la salida dedicada uo_out.
    // uo_out[7] queda en 0 (punto decimal apagado).
    assign uo_out = {1'b0, w_seg_out};

    // Conectamos el selector (3 bits) a los pines bidireccionales uio_out.
    // Los bits superiores se ponen a 0.
    assign uio_out = {5'b00000, w_digit_sel};

    // Configuramos uio_oe para que los pines que usamos sean SALIDAS (1).
    // Los 3 primeros bits (uio[0], uio[1], uio[2]) son salidas.
    assign uio_oe  = 8'b00000111;
    
    Contador_Completo Contador_Completo_Unit (
        .clk(clk),           // Conecta el reloj del sistema al reloj del módulo
        .rst(rst_n),         // Conecta el reset (activo bajo) del sistema
        .seg_out(w_seg_out), // Conecta la salida de segmentos a nuestro cable
        .digit_sel(w_digit_sel) // Conecta el selector a nuestro cable
    );
    // Evitamos advertencias sobre señales que tu contador no usa (como ui_in).
    wire _unused = &{ena, ui_in, uio_in, 1'b0};

endmodule
