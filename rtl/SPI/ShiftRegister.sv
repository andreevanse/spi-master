module ShiftRegister #(MAX_WORD_SIZE = 16)
(
    input logic clock,
    input logic reset,
    input logic enable,
    
    input logic[$clog2(MAX_WORD_SIZE)-1:0] wordSize,
    
    input logic write,
    input logic read,
    input logic shift,
    input logic[MAX_WORD_SIZE-1:0] dataIn,
    output logic[MAX_WORD_SIZE-1:0] dataOut,
    
    input logic shiftIn,
    output logic shiftOut
);

    logic[MAX_WORD_SIZE-1:0] shiftReg = '0;    
    logic[MAX_WORD_SIZE-1:0] shiftRegMask; // маска для выгрузки
    
    always_comb
    begin
        shiftRegMask = ~1'b1;
        shiftRegMask <<= wordSize;
        shiftRegMask = ~shiftRegMask;
    end
            
    assign shiftOut = shiftReg[wordSize];

    always_ff @(posedge clock or posedge reset)
        if(reset)
            shiftReg <= '0;
        else if(enable)
        begin
            if(write)
                shiftReg <= dataIn;
            else if(shift)
                shiftReg <= {shiftReg[MAX_WORD_SIZE-2:0], shiftIn};
                
            if(read)
                dataOut <= shiftReg & shiftRegMask;
        end

endmodule
