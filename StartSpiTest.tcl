set TEST_NAME  "SpiTest"

set TMP_DIR "$SIM_DIR/$TEST_NAME"

quit -sim
file mkdir $TMP_DIR
cd $TMP_DIR

# #############################################################################################################################
# компилируем исходники
# #############################################################################################################################
    vlib spi_tb

    # тестбенч
    vlog  "$TEST_DIR/SpiTest.sv" -work spi_tb

    
    # исходный код
    vlog  "$SOURCE_DIR/SPI/Spi.sv" -work spi_tb
    vlog  "$SOURCE_DIR/SPI/Fifo.sv" -work spi_tb
    vlog  "$SOURCE_DIR/SPI/SpiBase.sv" -work spi_tb
    vlog  "$SOURCE_DIR/SPI/ShiftRegister.sv" -work spi_tb


# #############################################################################################################################
vsim -voptargs="+acc" spi_tb.SpiTest ;#-debugDB

add wave -divider "SPI"
add wave -radix unsigned SpiTest/spi_inst/*
add wave -radix unsigned {SpiTest/spi_inst/nCS[0]}





run 50us;

wave zoom full
