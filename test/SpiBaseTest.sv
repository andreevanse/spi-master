module SpiBaseTest
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
    // logic busy;
    logic sclkPolarity = '0;
    logic sclkPhase = '0;
    logic[4:0] wordSize = 5'd15;
    logic[15:0] divisor = '0;
    
    // logic push = '0;
    logic[31:0] sendData = '0;
    // logic fullSendFifo;
    // logic emptySendFifo;
    // logic almostFullSendFifo;
    // logic almostEmptySendFifo;
    
    // logic pop = '0;
    logic[31:0] recvData;
    // logic fullRecvFifo;
    // logic emptyRecvFifo;
    // logic almostFullRecvFifo;
    // logic almostEmptyRecvFifo;

    // logic nCS;
    logic SCLK;
    logic MOSI;
    logic MISO;

    
    SpiBase #(.MAX_WORD_SIZE(32)) spi_inst
    (
        .clock(clock),
        .reset(reset),
        .enable(enable),
        
        .sclkPolarity(sclkPolarity),
        .sclkPhase(sclkPhase),
        .divisor(divisor),
        .wordSize(wordSize),
        
        .start(start),
        .ready(ready),
        .sendData(sendData),    
        .recvData(recvData),

    // spi interface 
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO)
    );


    assign MISO = MOSI;

    task Init(logic[15:0] div, logic polarity, logic phase, logic[4:0] word);
        reset = '1;
        @(posedge clock);
        reset = '0;
        enable = '0;
        divisor = div;
        sclkPolarity = polarity;
        sclkPhase = phase;
        wordSize = word;
        @(posedge clock);
    endtask
       
    task Start(logic[31:0] data);
        start = '1;
        sendData = data;
        @(posedge clock);
        start = '0;
    endtask

    
    
    initial
    begin
        Init(16'd30, 1, 1, 5'd31);
        enable = '1;
        Start(32'h8000BCA5);
        @(negedge ready);
        Start(8012);
    end



endmodule

