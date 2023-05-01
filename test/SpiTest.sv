module SpiTest
#(
    CLOCK_PERIOD = 10ns
);

    logic clock;
    initial
    begin
        clock <= '0;
        forever #(CLOCK_PERIOD/2) clock <= ~clock;
    end

    logic reset = '0;
    logic enable = '0;
    
    logic start = '0;
    logic busy;
    logic[4:0] wordSize = 5'd0;
    logic[15:0] divisor = '0;
    
    logic push = '0;
    logic[31:0] txData;
    
    logic pop = '0;
    logic[31:0] rxData;

    logic nCS;
    logic SCLK;
    logic MOSI;
    logic MISO;
    
    Spi #(.FIFO_DEPTH(32), .MAX_SLAVES_NUMBER(1), .MAX_WORD_SIZE(32)) spi_inst
    (
        .clock(clock),
        .reset(reset),
        .enable(enable),
        
        .sclkPolarity('0),
        .sclkPhase('0),
        .divisor(divisor),
        .wordSize(wordSize),
        .recvNumber('d5),
        .chipSelectEnable('1),
    
        .rxFifoEnable('1),
        .txFifoEnable('1),
        .rxFifoAlmostFullLevel(30),
        .rxFifoAlmostEmptyLevel(2),
        .txFifoAlmostFullLevel(30),
        .txFifoAlmostEmptyLevel(2),
        .rxQueueSize(),
        .txQueueSize(),

        
        .busy(busy),

        .push(push),
        .txData(txData),
        .fullTxFifo(),
        .emptyTxFifo(),
        .almostFullTxFifo(),
        .almostEmptyTxFifo(),
    
        .pop(pop),
        .rxData(rxData),
        .fullRxFifo(),
        .emptyRxFifo(),
        .almostFullRxFifo(),
        .almostEmptyRxFifo(),

        .oe(),
        .nCS(nCS),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO)
    );

    assign MISO = MOSI;

    task Init(logic[15:0] div, logic[4:0] word);
        reset = '1;
        @(posedge clock);
        reset = '0;
        enable = '0;
        divisor = div;
        wordSize = word;
        @(posedge clock);
    endtask
       
    task Push(logic[31:0] data);
        push = '1;
        txData = data;
        @(posedge clock);
        push = '0;
    endtask
    
    task Pop();
        pop = '1;
        @(posedge clock);
        pop = '0;
    endtask

    
    initial
    begin
        Init(16'd8, 5'd15);
        enable = '1;
        for(int i = 0; i < 33; ++i)
        begin
            Push($random() & 32'hffff);
            @(posedge clock);
        end
        @(negedge busy);
        for(int i = 0; i < 32; ++i)
        begin
            Pop();
            @(posedge clock);
        end
    end



endmodule

