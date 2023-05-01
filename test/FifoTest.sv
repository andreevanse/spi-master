module FifoTest
#(
    CLOCK_PERIOD = 10ns,
    FIFO_DEPTH = 16,
    DATA_BUS_SIZE = 32
);

    logic clock;
    initial
    begin
        clock <= '0;
        forever #(CLOCK_PERIOD/2) clock <= ~clock;
    end

    logic reset = '0;
    logic enable = '0;
    
    logic[$clog2(FIFO_DEPTH)-1:0] almostFullTreshold = '0;
    logic[$clog2(FIFO_DEPTH)-1:0] almostEmptyTreshold = '0;
    
    logic push = '0;
    logic pop = '0;
    logic[DATA_BUS_SIZE-1:0] writeData = '0;
    logic[DATA_BUS_SIZE-1:0] readData;
    logic[$clog2(FIFO_DEPTH):0] queueSize;
    
    logic empty;
    logic full;
    logic almostEmpty;
    logic almostFull;

    
    Fifo 
    #(
        .DATA_BUS_SIZE(DATA_BUS_SIZE), 
        .FIFO_DEPTH(FIFO_DEPTH),
        .RAM_OUTPUT_AFTER_POP("YES"),
        .LATCH_TRESHOLDS("YES")
    )
    fifo_inst
    (
        .clock(clock),
        .areset(reset),
        .sreset(),
        .enable(enable),
        
        .almostFullTreshold(almostFullTreshold),
        .almostEmptyTreshold(almostEmptyTreshold),
        
        .push(push),
        .pop(pop),
        .writeData(writeData),
        .readData(readData),
        .queueSize(queueSize),
        
        .empty(empty),
        .full(full),
        .almostEmpty(almostEmpty),
        .almostFull(almostFull)
    );



    task Init(logic[$clog2(FIFO_DEPTH)-1:0] af, ae);
        reset = '1;
        @(posedge clock);
        reset = '0;
        enable = '0;
        almostFullTreshold = af;
        almostEmptyTreshold = ae;
        @(posedge clock);
        enable = '1;
    endtask
       
    task Push(logic[DATA_BUS_SIZE-1:0] data);
        push = '1;
        writeData = data;
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
        Init(0, 2);
        for(int i = 0; i < 17; ++i)
        begin
            Push((i+6)*31);
            repeat(5) @(posedge clock);
        end
        for(int i = 0; i < 17; ++i)
        begin
            Pop();
            repeat(5) @(posedge clock);
        end
    end

endmodule

