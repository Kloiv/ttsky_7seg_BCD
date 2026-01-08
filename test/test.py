import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.result import TestFailure

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
    # Accedemos a la señal interna 'cnt_4hz' dentro de la instancia 'Contador_Completo_Unit'
    # Nota: Si tu instancia se llama diferente en project.v, cambia el nombre aquí.
    internal_counter = dut.Contador_Completo_Unit.cnt_4hz.value.integer
    
    if internal_counter != 0:
         raise TestFailure(f"Fallo de Reset: El contador interno debería ser 0, es {internal_counter}")
    
    # Verificar que el display muestra '0' (Segmentos activados por 0 logic)
    # 0 = 7'b0000001 (g es el bit 0 y está apagado/1)
    # uo_out agrega un 0 al inicio -> 8'b00000001 -> 1 decimal
    segments = dut.uo_out.value.integer
    if segments != 1:
        dut._log.error(f"Display incorrecto tras reset. Esperado=1 (0x01), Leído={segments}")
    else:
        dut._log.info("✔ Reset verificado: Display muestra 0 y contador interno en 0")


@cocotb.test()
async def test_enable_functionality(dut):
    """Prueba que el contador interno aumente SOLO cuando enable (ui_in[0]) es 1"""
    dut._log.info("Iniciando Test: Enable")
    
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())

    # Reset inicial
    dut.rst_n.value = 0
    dut.ui_in.value = 0 
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # --- PRUEBA 1: ENABLE = 1 (Debe contar) ---
    dut.ui_in.value = 1 # Activamos enable (bit 0)
    
    # Tomamos el valor actual del contador interno
    val_antes = dut.Contador_Completo_Unit.cnt_4hz.value.integer
    
    # Esperamos 100 ciclos de reloj
    await ClockCycles(dut.clk, 100)
    
    val_despues = dut.Contador_Completo_Unit.cnt_4hz.value.integer
    
    dut._log.info(f"Con Enable=1: Antes={val_antes}, Después={val_despues}")

    if val_despues <= val_antes:
        raise TestFailure("El contador NO incrementó a pesar de tener Enable=1")
    else:
        dut._log.info("✔ El contador incrementa correctamente con Enable")


@cocotb.test()
async def test_disable_functionality(dut):
    """Prueba que el contador interno SE CONGELE cuando enable es 0"""
    dut._log.info("Iniciando Test: Disable")
    
    clock = Clock(dut.clk, CLK_PERIOD_NS, units="ns")
    cocotb.start_soon(clock.start())
    
    # Aseguramos que no estamos en reset
    dut.rst_n.value = 1
    
    # Primero dejamos que avance un poco
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 10)
    
    # --- PRUEBA 2: ENABLE = 0 (Debe pausar) ---
    dut.ui_in.value = 0 # Desactivamos enable
    
    # Tomamos valor
    val_antes = dut.Contador_Completo_Unit.cnt_4hz.value.integer
    
    # Esperamos 100 ciclos
    await ClockCycles(dut.clk, 100)
    
    val_despues = dut.Contador_Completo_Unit.cnt_4hz.value.integer
    
    dut._log.info(f"Con Enable=0: Antes={val_antes}, Después={val_despues}")
    
    if val_despues != val_antes:
        raise TestFailure(f"El contador se movió aunque Enable=0! (Diff: {val_despues - val_antes})")
    else:
        dut._log.info("✔ El contador se pausa correctamente (Disable funciona)")
