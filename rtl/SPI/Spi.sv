module Spi  // Tsclk = Tclock * N_SCLK
#(
    FIFO_DEPTH = 256,
    MAX_SLAVES_NUMBER = 4,
    MAX_WORD_SIZE = 16
)
(
    input logic clock,
    input logic reset,
    input logic enable,
    
    input logic sclkPolarity,
    input logic sclkPhase,
    input logic[15:0] divisor, // минимум - 3 такта
    input logic[$clog2(MAX_WORD_SIZE)-1:0] wordSize, // размер фрейма данных
    input logic[15:0] recvNumber, // количество фреймов для приема в одном пакете
    input logic[MAX_SLAVES_NUMBER-1:0] chipSelectEnable, // разрешение конкретной линии nCS
    input logic[7:0] rxSampleDelay, // задержка отсчетов при приеме, нужно для флешек, пока не реализовано и неясно как
    
    input logic rxFifoEnable,
    input logic txFifoEnable,
    input logic[$clog2(FIFO_DEPTH)-1:0] rxFifoAlmostFullLevel,
    input logic[$clog2(FIFO_DEPTH)-1:0] rxFifoAlmostEmptyLevel,
    input logic[$clog2(FIFO_DEPTH)-1:0] txFifoAlmostFullLevel,
    input logic[$clog2(FIFO_DEPTH)-1:0] txFifoAlmostEmptyLevel,
    output logic[$clog2(FIFO_DEPTH):0] rxQueueSize,
    output logic[$clog2(FIFO_DEPTH):0] txQueueSize,
    
    output logic busy,
    
    input logic push,
    input logic[MAX_WORD_SIZE-1:0] txData,
    output logic fullTxFifo,
    output logic emptyTxFifo,
    output logic almostFullTxFifo,
    output logic almostEmptyTxFifo,
    
    input logic pop,
    output logic[MAX_WORD_SIZE-1:0] rxData,
    output logic fullRxFifo,
    output logic emptyRxFifo,
    output logic almostFullRxFifo,
    output logic almostEmptyRxFifo,

// spi interface 
    output logic oe, // Для управления выходного буфера в режиме 3-wire (MOSI + MISO = SIO)
    
    output logic[MAX_SLAVES_NUMBER-1:0] nCS,
    output logic SCLK,
    output logic MOSI,
    input logic MISO
);

    logic[15:0] recvNumberReg = '0;
    always_ff @(posedge clock or posedge reset)
        if(reset)
            recvNumberReg <= '0;
        else if(!enable)
            recvNumberReg <= recvNumber;

    logic[MAX_SLAVES_NUMBER-1:0] chipSelectEnableReg = '0;
    always_ff @(posedge clock or posedge reset)
        if(reset)
            chipSelectEnableReg <= '0;
        else if(!enable)
            chipSelectEnableReg <= chipSelectEnable;

    logic[7:0] rxSampleDelayReg = '0;
    always_ff @(posedge clock or posedge reset)
        if(reset)
            rxSampleDelayReg <= '0;
        else if(!enable)
            rxSampleDelayReg <= rxSampleDelay;

    logic rxFifoEnableReg = '1;
    always_ff @(posedge clock or posedge reset)
        if(reset)
            rxFifoEnableReg <= '1;
        else if(!enable)
            rxFifoEnableReg <= rxFifoEnable;
    
    logic txFifoEnableReg = '1;
    always_ff @(posedge clock or posedge reset)
        if(reset)
            txFifoEnableReg <= '1;
        else if(!enable)
            txFifoEnableReg <= txFifoEnable;

//////////////////////////////////////////////////////////////////////
    logic pushRx, popTx;
    logic[MAX_WORD_SIZE-1:0] dataFromTxFifoToMux, dataFromMasterToRxFifo;

    Fifo 
    #(
        .DATA_BUS_SIZE(MAX_WORD_SIZE), 
        .FIFO_DEPTH(FIFO_DEPTH),
        .LATCH_TRESHOLDS("YES"),
        .RAM_OUTPUT_AFTER_POP("YES")
    )
    txfifo_inst
    (
        .clock(clock),
        .areset(!enable),
        .sreset(reset),
        .enable(enable),
        
        .almostFullTreshold(txFifoAlmostFullLevel),
        .almostEmptyTreshold(txFifoAlmostEmptyLevel),
        
        .push(push),
        .pop(popTx),
        .writeData(txData),
        .readData(dataFromTxFifoToMux),
        .queueSize(txQueueSize),
        
        .empty(emptyTxFifo),
        .full(fullTxFifo),
        .almostEmpty(almostEmptyTxFifo),
        .almostFull(almostFullTxFifo)
    );

    Fifo 
    #(
        .DATA_BUS_SIZE(MAX_WORD_SIZE), 
        .FIFO_DEPTH(FIFO_DEPTH),
        .LATCH_TRESHOLDS("YES"),
        .RAM_OUTPUT_AFTER_POP("NO")
    )
    rxfifo_inst
    (
        .clock(clock),
        .areset(!enable),
        .sreset(reset),
        .enable(enable),
        
        .almostFullTreshold(rxFifoAlmostFullLevel),
        .almostEmptyTreshold(rxFifoAlmostEmptyLevel),
        
        .push(pushRx),
        .pop(pop),
        .writeData(dataFromMasterToRxFifo),
        .readData(rxData),
        .queueSize(rxQueueSize),
        
        .empty(emptyRxFifo),
        .full(fullRxFifo),
        .almostEmpty(almostEmptyRxFifo),
        .almostFull(almostFullRxFifo)
    );

    logic masterReady;
    logic[15:0] recvCounter = '0;
    logic recvCounterStop; assign recvCounterStop = (recvCounter == '0);
    
    enum logic[2:0] {IDLE, TX_POP, LOAD, WORK, RX_PUSH} state = IDLE;
    always_ff @(posedge clock or posedge reset)
        if(reset)
            state <= IDLE;
        else if(enable)
            unique case(state)
                IDLE    : if(txFifoEnableReg)
                              state <= emptyTxFifo ? IDLE : TX_POP;
                          else if(rxFifoEnableReg)
                              state <= push ? LOAD : IDLE;
                TX_POP  : state <= LOAD;
                LOAD    : state <= WORK;
                WORK    : if(masterReady)
                          begin
                              if(rxFifoEnableReg)
                                  state <= RX_PUSH;
                              else if(txFifoEnableReg)
                                  state <= emptyTxFifo ? IDLE : TX_POP;
                          end
                RX_PUSH : if(txFifoEnableReg)
                              state <= emptyTxFifo ? IDLE : TX_POP;
                          else
                              state <= recvCounterStop ? IDLE : LOAD;
            endcase
    
    logic[MAX_WORD_SIZE-1:0] txDataDelay;
    always_ff @(posedge clock or posedge reset)
        if(reset)
            txDataDelay <= '0;
        else if(!txFifoEnableReg && state == IDLE)
            txDataDelay <= txData;

    logic[MAX_WORD_SIZE-1:0] toMaster;
    assign toMaster = txFifoEnableReg ? dataFromTxFifoToMux : txDataDelay;

    assign pushRx = (state == RX_PUSH);
    assign popTx = (state == TX_POP);

    always_ff @(posedge clock or posedge reset)
        if(reset)
            recvCounter <= '0;
        else if(enable)
        begin
            if(state == IDLE)
                recvCounter <= recvNumberReg;
            else if(state == RX_PUSH)
                recvCounter <= recvCounterStop ? '0 : recvCounter - 1'b1;
        end
            
    always_ff @(posedge clock or posedge reset)
        if(reset)
            oe <= '0;
        else if(enable)
            oe <= (state == WORK && txFifoEnable && !rxFifoEnable);

    always_ff @(posedge clock or posedge reset)
        if(reset)
            busy <= '0;
        else if(enable)
            busy <= (state != IDLE);


    SpiBase #(.MAX_WORD_SIZE(MAX_WORD_SIZE)) spiBase_inst
    (
        .clock(clock),
        .reset(reset),
        .enable(enable),
        
        .sclkPolarity(sclkPolarity),
        .sclkPhase(sclkPhase),
        .divisor(divisor),
        .wordSize(wordSize),
        
        .start(state == LOAD),
        .ready(masterReady),
        .busy(),
        .sendData(toMaster),    
        .recvData(dataFromMasterToRxFifo),

        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO)
    );
    
    genvar i;
    generate for(i = 0; i < MAX_SLAVES_NUMBER; ++i)
    begin : csControl
        assign nCS[i] = !(state != IDLE && chipSelectEnableReg[i]);
    end
    endgenerate
    
endmodule
