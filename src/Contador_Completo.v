module Contador_Completo (
    input  wire clk,         // Reloj de 50MHz
    input  wire rst,         // Botón en PIN 23 (Activo en 0)
	input  wire enable,
    output reg  [6:0] seg_out,   // Salida compartida
    output reg  [2:0] digit_sel  // Selector de dígito
);

    parameter FREQ_CLK = 50000000;
    localparam LIMITE_CUENTA = (FREQ_CLK / 8);
    localparam LIMITE_REFRESCO = (FREQ_CLK / 1000);

    // ==========================================
    // LOGICA DEL CONTADOR (4Hz)
    // ==========================================
    integer cnt_4hz;
    reg     tick_4hz;
    reg [7:0] cuenta_binaria;

    // CAMBIO 1: "negedge rst" detecta la bajada (al presionar)
    always @(posedge clk or negedge rst) begin
        // CAMBIO 2: "!rst" (si rst es 0, entonces resetea)
        if (!rst) begin
            cnt_4hz <= 0;
            tick_4hz <= 0;
            cuenta_binaria <= 0;
        end else begin
            if (cnt_4hz >= LIMITE_CUENTA - 1) begin
                cnt_4hz <= 0;
                tick_4hz <= 1;
            end else begin
                cnt_4hz <= cnt_4hz + 1;
                tick_4hz <= 0;
            end

            if (tick_4hz) begin
                cuenta_binaria <= cuenta_binaria + 1; 
            end
        end
    end

    // ==========================================
    // CONVERSIÓN BCD
    // ==========================================
    wire [3:0] bcd_c, bcd_d, bcd_u;
    assign bcd_c = cuenta_binaria / 100;
    assign bcd_d = (cuenta_binaria % 100) / 10;
    assign bcd_u = (cuenta_binaria % 100) % 10;

    // ==========================================
    // LOGICA DE MULTIPLEXACIÓN (REFRESCO)
    // ==========================================
    integer cnt_refresco;
    reg [1:0] estado_mux; 
    reg [3:0] digito_actual; 
	 
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cnt_refresco <= 0;
            estado_mux   <= 0;
        end else begin
            if (cnt_refresco >= LIMITE_REFRESCO - 1) begin
                cnt_refresco <= 0;
                if (estado_mux == 2) estado_mux <= 0;
                else estado_mux <= estado_mux + 1;
            end else begin
                cnt_refresco <= cnt_refresco + 1;
            end
        end
    end

    // ==========================================
    // SALIDA
    // ==========================================
    always @(*) begin
        // Selección del Display (Transistores)
        case (estado_mux)
            2'd0: begin // Unidades
                digito_actual = bcd_u;
                digit_sel     = 3'b110; 
            end
            2'd1: begin // Decenas
                digito_actual = bcd_d;
                digit_sel     = 3'b101; 
            end
            2'd2: begin // Centenas
                digito_actual = bcd_c;
                digit_sel     = 3'b011; 
            end
            default: begin
                digito_actual = 4'd0;
                digit_sel     = 3'b111; 
            end
        endcase

        // Decodificación 7 Segmentos (Lógica Negativa: 0 = Encendido)
        case (digito_actual)
            4'h0: seg_out = 7'b0000001; // 0
            4'h1: seg_out = 7'b1001111; // 1
            4'h2: seg_out = 7'b0010010; // 2
            4'h3: seg_out = 7'b0000110; // 3
            4'h4: seg_out = 7'b1001100; // 4
            4'h5: seg_out = 7'b0100100; // 5
            4'h6: seg_out = 7'b0100000; // 6
            4'h7: seg_out = 7'b0001111; // 7
            4'h8: seg_out = 7'b0000000; // 8
            4'h9: seg_out = 7'b0000100; // 9
            default: seg_out = 7'b1111111; // Apagado
        endcase
    end


endmodule
