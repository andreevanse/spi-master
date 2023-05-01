set TEST_NAME  "SpiBaseTest"

set TMP_DIR "$SIM_DIR/$TEST_NAME"

quit -sim
file mkdir $TMP_DIR
cd $TMP_DIR

# #############################################################################################################################
# компилируем исходники
# #############################################################################################################################
    vlib spi_tb

    # тестбенч
    vlog  "$TEST_DIR/SpiBaseTest.sv" -work spi_tb

    
    # исходный код
    vlog  "$SOURCE_DIR/SPI/SpiBase.sv" -work spi_tb
    vlog  "$SOURCE_DIR/SPI/ShiftRegister.sv" -work spi_tb


# #############################################################################################################################
vsim -voptargs="+acc" spi_tb.SpiBaseTest ;#-debugDB

add wave -divider "SPI"
add wave -radix unsigned SpiBaseTest/spi_inst/*




run 20us;

wave zoom full