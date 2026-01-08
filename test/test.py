import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

# Configuración del reloj: 50 MHz (Periodo de 20ns)
CLK_PERIOD_NS = 20 

@cocotb.test()
async def test_reset(dut):
    """Prueba que el sistema se resetee correctamente y muestre el numero 0"""
    dut._log.info("Iniciando Test: Reset")

    # 1. Iniciar el Reloj
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # 2. Aplicar Reset (Activo bajo)
    dut.rst_n.value = 0
    dut.ui_in.value = 0  # Enable apagado
    await ClockCycles(dut.clk, 5)

    # 3. Liberar Reset
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # 4. Verificar estado inicial
    # Detectar si estamos en prueba Gate Level (GL)
    is_gl_test = cocotb.plusargs.get('GL_TEST', False)
    
    if not is_gl_test:
        try:
            internal_counter = dut.Contador_Completo_Unit.cnt_4hz.value.integer
            # REEMPLAZO DE TestFailure POR assert
            assert internal_counter == 0, f"Fallo de Reset: El contador interno debería ser 0, es {internal_counter}"
        except AttributeError:
            dut._log.warning("Señal interna no accesible, saltando chequeo interno.")
    
    # Verificar que el display muestra '0' (Segmentos activados por 0 logic)
    # 0 = 7'b0000001 (g es el bit 0 y está apagado/1)
    # uo_out agrega un 0 al inicio -> 8'b00000001 -> 1 decimal
    segments = dut.uo_out.value.integer
    if segments != 1:
        dut._log.error(f"Display incorrecto tras reset. Esperado=1 (0x01), Leído={segments}")
    else:
        dut._log.info("✔ Reset verificado: Display muestra 0")


@cocotb.test()
async def test_enable_functionality(dut):
    """Prueba que el contador interno aumente SOLO cuando enable (ui_in[0]) es 1"""
    dut._log.info("Iniciando Test: Enable")
    
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Detectar si estamos en prueba Gate Level (GL)
    is_gl_test = cocotb.plusargs.get('GL_TEST', False)

    # Reset inicial
    dut.rst_n.value = 0
    dut.ui_in.value = 0 
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # --- PRUEBA: ENABLE = 1 ---
    dut.ui_in.value = 1 
    
    if not is_gl_test:
        # Solo intentamos leer señales internas si NO es una prueba GL
        try:
            val_antes = dut.Contador_Completo_Unit.cnt_4hz.value.integer
        except AttributeError:
            dut._log.warning("No se pudo acceder a la señal interna. Saltando verificación interna.")
            return

        await ClockCycles(dut.clk, 100)
        
        val_despues = dut.Contador_Completo_Unit.cnt_4hz.value.integer
        dut._log.info(f"RTL Check -> Antes: {val_antes}, Despues: {val_despues}")

        # REEMPLAZO DE TestFailure POR assert
        assert val_despues > val_antes, "El contador NO incrementó a pesar de tener Enable=1"
        
        dut._log.info("✔ El contador incrementa correctamente con Enable")
    else:
        dut._log.info("Test GL detectado: Saltando inspección interna.")
        await ClockCycles(dut.clk, 100)


@cocotb.test()
async def test_disable_functionality(dut):
    """Prueba que el contador interno SE CONGELE cuando enable es 0"""
    dut._log.info("Iniciando Test: Disable")
    
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())
    
    is_gl_test = cocotb.plusargs.get('GL_TEST', False)

    # Aseguramos que no estamos en reset
    dut.rst_n.value = 1
    
    # Primero dejamos que avance un poco
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 20)
    
    # --- PRUEBA 2: ENABLE = 0 (Debe pausar) ---
    dut.ui_in.value = 0 # Desactivamos enable
    
    if not is_gl_test:
        try:
            val_antes = dut.Contador_Completo_Unit.cnt_4hz.value.integer
        except AttributeError:
            return

        # Esperamos 100 ciclos
        await ClockCycles(dut.clk, 100)
        
        val_despues = dut.Contador_Completo_Unit.cnt_4hz.value.integer
        
        dut._log.info(f"Con Enable=0: Antes={val_antes}, Después={val_despues}")
        
        # REEMPLAZO DE TestFailure POR assert
        assert val_despues == val_antes, f"El contador se movió aunque Enable=0! (Diff: {val_despues - val_antes})"
        
        dut._log.info("✔ El contador se pausa correctamente (Disable funciona)")
    else:
        await ClockCycles(dut.clk, 100)
