module SpiBase #(parameter MAX_WORD_SIZE = 32)
(
    input logic clock,
    input logic reset,
    input logic enable,
    
    input logic sclkPolarity,
    input logic sclkPhase,
    input logic[15:0] divisor,
    input logic[$clog2(MAX_WORD_SIZE)-1:0] wordSize,
    
    input logic start,
    output logic ready,
    output logic busy,
    input logic[MAX_WORD_SIZE-1:0] sendData,    
    output logic[MAX_WORD_SIZE-1:0] recvData,

// spi interface 
    output logic SCLK,
    output logic MOSI,
    input logic MISO
);

    logic sclkPolarityReg, sclkPhaseReg;
    logic[$clog2(MAX_WORD_SIZE)-1:0] wordSizeReg;
    logic[$clog2(MAX_WORD_SIZE)-1:0] bitCounter = '0;
    
    logic[15:0] divisorReg;
    logic[15:0] sclkCounter = '0; // Счетчик для формирования SCLK с нужной частотой

    always_ff @(posedge clock or posedge reset)
        if(reset)
            divisorReg <= 16'h4;
        else if(!enable)
            divisorReg <= divisor;

    always_ff @(posedge clock or posedge reset)
        if(reset)
            sclkPolarityReg <= '0;
        else if(!enable)
            sclkPolarityReg <= sclkPolarity;

    always_ff @(posedge clock or posedge reset)
        if(reset)
            sclkPhaseReg <= '0;
        else if(!enable)
            sclkPhaseReg <= sclkPhase;
            
    always_ff @(posedge clock or posedge reset)
        if(reset)
            wordSizeReg <= '0;
        else if(!enable)
            wordSizeReg <= wordSize;
            
////////////////////////////////////////////////////////////////////////////////

    logic sclkCycle; assign sclkCycle = (sclkCounter == divisorReg-1'b1);
    logic wordEnd; assign wordEnd = (bitCounter == wordSizeReg);
    
    enum logic[3:0] {IDLE, INIT, WORK, FINISH} state = IDLE;
    always_ff @(posedge clock or posedge reset)
        if(reset)
            state <= IDLE;
        else if(enable)
            unique case(state)
                IDLE   : state <= start ? INIT : IDLE;
                INIT   : state <= WORK;
                WORK   : state <= (wordEnd && sclkCycle) ? FINISH : WORK;
                FINISH : state <= IDLE;
            endcase

    always_ff @(posedge clock or posedge reset)
        if(reset)
            sclkCounter <= '0;
        else if(enable)
            if(state == WORK)
                sclkCounter <= sclkCycle ? '0 : sclkCounter + 1'b1;
            else
                sclkCounter <= '0;

    always_ff @(posedge clock or posedge reset)
        if(reset)
            bitCounter <= '0;
        else if(enable && state == WORK)
        begin
            if(sclkCycle)
                bitCounter <= bitCounter + 1'b1;
        end
        else
            bitCounter <= '0;

    logic sclkLoadEdge, sclkSaveEdge;

    always_ff @(posedge clock)
        sclkLoadEdge <= (sclkCounter == '0 && state == WORK);

    always_ff @(posedge clock)
        sclkSaveEdge <= (sclkCounter == divisorReg/2 && state == WORK);
                
    logic sclk;
    always_ff @(posedge clock or posedge reset)
        if(reset)
            sclk <= '0;
        else if(enable)
        begin
            if(state == IDLE)
                sclk <= '0;
            else
            begin
                if(sclkLoadEdge)
                    sclk <= sclkPhaseReg;
                if(sclkSaveEdge)
                    sclk <= ~sclkPhaseReg;
            end
        end

    logic shiftRegOut;
    ShiftRegister #(.MAX_WORD_SIZE(MAX_WORD_SIZE)) shreg_inst
    (
        .clock(clock),
        .reset(reset),
        .enable(enable),
        
        .wordSize(wordSizeReg),
        
        .write(state == INIT),
        .read(state == FINISH),
        .shift(sclkSaveEdge),
        .dataIn(sendData),
        .dataOut(recvData),
        
        .shiftIn(MISO),
        .shiftOut(shiftRegOut)
    );

    always_ff @(posedge clock or posedge reset)
        if(reset)
            MOSI <= '0;
        else if(enable)
        begin
            if(state == IDLE)
                MOSI <= '0;
            else if(sclkLoadEdge)
                MOSI <= shiftRegOut;
        end
    
    assign SCLK = sclkPolarityReg ? ~sclk : sclk;    

    always_ff @(posedge clock)
        busy <= (state != IDLE);

    always_ff @(posedge clock)
        ready <= (state == FINISH);

endmodule
