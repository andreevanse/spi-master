set TEST_NAME  "FifoTest"

set TMP_DIR "$SIM_DIR/$TEST_NAME"

quit -sim
file mkdir $TMP_DIR
cd $TMP_DIR

# #############################################################################################################################
# компилируем исходники
# #############################################################################################################################
    vlib fifo_tb

    # тестбенч
    vlog  "$TEST_DIR/FifoTest.sv" -work fifo_tb

    
    # исходный код
    vlog  "$SOURCE_DIR/SPI/Fifo.sv" -work fifo_tb


# #############################################################################################################################
vsim -voptargs="+acc" fifo_tb.FifoTest ;#-debugDB

add wave -divider "Fifo"
add wave -radix unsigned FifoTest/fifo_inst/*




run 2100ns;

wave zoom full