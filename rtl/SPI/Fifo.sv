module Fifo 
#(
    DATA_BUS_SIZE = 32, 
    FIFO_DEPTH = 8,
    string RAM_OUTPUT_AFTER_POP = "YES",
    string LATCH_TRESHOLDS = "YES"
)
(
    input logic clock,
    input logic areset,
    input logic sreset,
    input logic enable,
    
    input logic[$clog2(FIFO_DEPTH)-1:0] almostFullTreshold,
    input logic[$clog2(FIFO_DEPTH)-1:0] almostEmptyTreshold,
    
    input logic push,
    input logic pop,
    input logic[DATA_BUS_SIZE-1:0] writeData,
    output logic[DATA_BUS_SIZE-1:0] readData,
    output logic[$clog2(FIFO_DEPTH):0] queueSize,
    
    output logic empty,
    output logic full,
    output logic almostEmpty,
    output logic almostFull
);
    // synthesis translate_off
    initial
    begin
        assert(!(FIFO_DEPTH & (FIFO_DEPTH-1))) else $fatal(1, "Parameter FIFO_DEPTH not a power of 2!");
    end
    // synthesis translate_on

    logic[$clog2(FIFO_DEPTH)-1:0] almostFullTresholdReg;
    logic[$clog2(FIFO_DEPTH)-1:0] almostEmptyTresholdReg;
    generate if(LATCH_TRESHOLDS == "YES")
    begin
        always_ff @(posedge clock or posedge areset)
            if(areset)
            begin
                almostFullTresholdReg <= '1;
                almostEmptyTresholdReg <= '0;
            end
            else if(sreset)
            begin
                almostFullTresholdReg <= '1;
                almostEmptyTresholdReg <= '0;
            end
            else if(!enable)
            begin
                almostFullTresholdReg <= almostFullTreshold;
                almostEmptyTresholdReg <= almostEmptyTreshold;
            end
    end
    else if(LATCH_TRESHOLDS == "NO")
    begin
        always_comb
        begin
            almostFullTresholdReg = almostFullTreshold;
            almostEmptyTresholdReg = almostEmptyTreshold;
        end
    end
    endgenerate


    typedef logic[$clog2(FIFO_DEPTH)-1:0] Pointer;
    Pointer head = '0;
    Pointer tail = '0;
    Pointer delta; assign delta = tail-head;
    
    enum logic[1:0] {EMPTY, NORMAL, FULL} fifoState = EMPTY;
    always_ff @(posedge clock or posedge areset)
        if(areset)
            fifoState <= EMPTY;
        else if(sreset)
            fifoState <= EMPTY;
        else if(enable)
            case(fifoState)
                EMPTY:  fifoState <= push ? NORMAL : EMPTY;
                NORMAL: if(push && ~pop && delta == '1) // FIFO_DEPTH-1
                            fifoState <= FULL;
                        else if(~push && pop && delta == 1'b1)
                            fifoState <= EMPTY;
                FULL:   fifoState <= pop ? NORMAL : FULL;
                default: fifoState <= EMPTY;
            endcase
    
    always_ff @(posedge clock or posedge areset)
        if(areset)
            queueSize <= '0;
        else if(sreset)
            queueSize <= '0;
        else if(enable)
        begin
            if(push && !pop && fifoState != FULL)
                queueSize <= queueSize + 1'b1;
            if(pop && !push && fifoState != EMPTY)
                queueSize <= queueSize - 1'b1;
        end

    assign almostFull  = fifoState == NORMAL && delta >= Pointer'(almostFullTresholdReg);
    assign almostEmpty = fifoState == NORMAL && delta <= Pointer'(almostEmptyTresholdReg);
    assign full        = (fifoState == FULL);
    assign empty       = (fifoState == EMPTY);
            
    always_ff @(posedge clock or posedge areset)
        if(areset)
        begin
            tail <= '0;
            head <= '0;
        end
        else if(sreset)
        begin
            tail <= '0;
            head <= '0;
        end        
        else if(enable)
        begin
            if(push && fifoState != FULL)
                tail <= tail + 1'b1;
            if(pop && fifoState != EMPTY)
                head <= head + 1'b1;
        end
    
    (*ramstyle = "auto"*) logic[DATA_BUS_SIZE-1:0] fifo[FIFO_DEPTH] = '{FIFO_DEPTH{0}};    
    always_ff @(posedge clock)
        if(enable && push && fifoState != FULL)
            fifo[tail] <= writeData;
        
    generate if(RAM_OUTPUT_AFTER_POP == "YES")
    begin
        always_ff @(posedge clock)
            if(enable && pop && fifoState != EMPTY)
                readData <= fifo[head];
    end
    else if(RAM_OUTPUT_AFTER_POP == "NO")
    begin
        always_comb
            readData = fifo[head];
    end
    endgenerate

endmodule
