module SpiAvalonWrapper
(
    input logic avalon_clock,
    input logic avalon_reset,
    
    input logic avalon_write,
    input logic avalon_read,
    //input logic avalon_waitrequest,
    
    input logic[5:0] avalon_address, //64 регистра
    input logic[31:0] avalon_writedata,
    output logic[31:0] avalon_readdata,
    output logic avalon_irq,
    
// conduit
    output logic oe,
    
    output logic nCS,
    output logic SCLK,
    output logic MOSI,
    input logic MISO
);

    localparam REG_MAP_SIZE = 64;
    
    logic[REG_MAP_SIZE-1:0] regAddressDecode;
    genvar i;
    generate for(i = 0; i < REG_MAP_SIZE; ++i)
    begin : addressDecode
        assign regAddressDecode[i] = (avalon_address[$clog2(REG_MAP_SIZE)-1:0] == $clog2(REG_MAP_SIZE)'(i)) && (avalon_write || avalon_read);
    end
    endgenerate

    `define ONE_HOT(reg_idx) (REG_MAP_SIZE'(1) << reg_idx)
    
    typedef enum {
        CTRLR0,
        CTRLR1,
        SPIENR,
        MWCR,
        SER,
        BAUDR,
        TXFTLR,
        RXFTLR,
        TXFLR,
        RXFLR,
        SR,
        IMR,
        ISR,
        RISR,
        TXOICR,
        RXOICR,
        RXUICR,
        MSTICR,
        ICR,
        DMACR,
        DMATDLR,
        DMARDLR,
        IDR,
        SPI_VERSION_ID,
        DR,
        _DR_MIRROR1,
        _DR_MIRROR2,
        _DR_MIRROR3,
        _DR_MIRROR4,
        _DR_MIRROR5,
        _DR_MIRROR6,
        _DR_MIRROR7,
        _DR_MIRROR8,
        _DR_MIRROR9,
        _DR_MIRROR10,
        _DR_MIRROR11,
        _DR_MIRROR12,
        _DR_MIRROR13,
        _DR_MIRROR14,
        _DR_MIRROR15,
        _DR_MIRROR16,
        _DR_MIRROR17,
        _DR_MIRROR18,
        _DR_MIRROR19,
        _DR_MIRROR20,
        _DR_MIRROR21,
        _DR_MIRROR22,
        _DR_MIRROR23,
        _DR_MIRROR24,
        _DR_MIRROR25,
        _DR_MIRROR26,
        _DR_MIRROR27,
        _DR_MIRROR28,
        _DR_MIRROR29,
        _DR_MIRROR30,
        _DR_MIRROR31,
        _DR_MIRROR32,
        _DR_MIRROR33,
        _DR_MIRROR34,
        _DR_MIRROR35,
        _DR_MIRROR36,
        _DR_MIRROR37,
        _DR_MIRROR38,
        RX_SAMPLE_DLY
    } spiRegs_t;


    logic[3:0] cfs;
    logic srl;
    logic[1:0] tmod;
    logic scpol;
    logic scph;
    logic[1:0] frf;
    logic[3:0] dfs = 4'h7;
    logic[15:0] ndf;
    logic spi_en;
    logic mhs, mdd, mwmod;
    logic[3:0] ser;
    logic[15:0] sckdv;
    logic[7:0] tft, rft;
    logic[8:0] txtfl, rxtfl;
    logic rff, rfne, tfe, tfnf, busy;
    logic rxfim = '1, rxoim = '1, rxuim = '1, txoim = '1, txeim = '1;
    logic mstis, rxfis, rxois, rxuis, txois, txeis;
    logic rxfir, rxoir, rxuir, txoir, txeir;
    logic txoicr, rxoicr, rxuicr, msticr, icr;
    logic tdmae, rdmae;
    logic[7:0] dmatdl, dmardl;
    logic[15:0] dr;
    logic[6:0] rsd;
    
    
    
    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            avalon_readdata <= '0;
        else if(avalon_read)
            unique case(regAddressDecode)
                `ONE_HOT(CTRLR0)         : avalon_readdata <= {16'b0, cfs, srl, 1'b0, tmod, scpol, scph, frf, dfs};
                `ONE_HOT(CTRLR1)         : avalon_readdata <= {16'b0, ndf};
                `ONE_HOT(SPIENR)         : avalon_readdata <= {31'b0, spi_en};
                `ONE_HOT(MWCR)           : avalon_readdata <= {29'b0, mhs, mdd, mwmod};
                `ONE_HOT(SER)            : avalon_readdata <= {28'b0, ser};
                `ONE_HOT(BAUDR)          : avalon_readdata <= {16'b0, sckdv};
                `ONE_HOT(TXFTLR)         : avalon_readdata <= {24'b0, tft};
                `ONE_HOT(RXFTLR)         : avalon_readdata <= {24'b0, rft};
                `ONE_HOT(TXFLR)          : avalon_readdata <= {23'b0, txtfl};
                `ONE_HOT(RXFLR)          : avalon_readdata <= {23'b0, rxtfl};
                `ONE_HOT(SR)             : avalon_readdata <= {27'b0, rff, rfne, tfe, tfnf, busy};
                `ONE_HOT(IMR)            : avalon_readdata <= {27'b0, rxfim, rxoim, rxuim, txoim, txeim};
                `ONE_HOT(ISR)            : avalon_readdata <= {26'b0, mstis, rxfis, rxois, rxuis, txois, txeis};
                `ONE_HOT(RISR)           : avalon_readdata <= {27'b0, rxfir, rxoir, rxuir, txoir, txeir};
                `ONE_HOT(TXOICR)         : avalon_readdata <= {31'b0, txoicr};
                `ONE_HOT(RXOICR)         : avalon_readdata <= {31'b0, rxoicr};
                `ONE_HOT(RXUICR)         : avalon_readdata <= {31'b0, rxuicr};
                `ONE_HOT(MSTICR)         : avalon_readdata <= {31'b0, msticr};
                `ONE_HOT(ICR)            : avalon_readdata <= {31'b0, icr};
                `ONE_HOT(DMACR)          : avalon_readdata <= {30'b0, tdmae, rdmae};
                `ONE_HOT(DMATDLR)        : avalon_readdata <= {24'b0, dmatdl};
                `ONE_HOT(DMARDLR)        : avalon_readdata <= {24'b0, dmardl};
                `ONE_HOT(IDR)            : avalon_readdata <= 32'h05510000;
                `ONE_HOT(SPI_VERSION_ID) : avalon_readdata <= 32'h3332302A;
                `ONE_HOT(DR)             : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR1)    : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR2)    : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR3)    : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR4)    : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR5)    : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR6)    : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR7)    : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR8)    : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR9)    : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR10)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR11)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR12)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR13)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR14)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR15)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR16)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR17)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR18)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR19)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR20)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR21)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR22)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR23)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR24)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR25)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR26)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR27)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR28)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR29)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR30)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR31)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR32)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR33)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR34)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR35)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR36)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR37)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(_DR_MIRROR38)   : avalon_readdata <= {16'b0, dr};
                `ONE_HOT(RX_SAMPLE_DLY)  : avalon_readdata <= {25'b0, rsd};
           endcase

    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            spi_en <= '0;
        else if(regAddressDecode[SPIENR] && avalon_write)
            spi_en <= avalon_writedata[0];

    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
        begin
            cfs <= '0;
            srl <= '0;
            tmod <= '0;
            scpol <= '0;
            scph <= '0;
            frf <= '0;
            dfs <= 4'd7;
        end
        else if(!spi_en && regAddressDecode[CTRLR0] && avalon_write)
        begin
            cfs <= avalon_writedata[15:12]; // cfs not implemented
            srl <= avalon_writedata[11];
            tmod <= avalon_writedata[9:8]; // tmod valid only for 0x0(T&R), 0x1(TO), 0x2(RO)
            scpol <= avalon_writedata[7];
            scph <= avalon_writedata[6];
            frf <= avalon_writedata[5:4]; // frf implemented only for 0x0 Motorola SPI
            dfs <= avalon_writedata[3:0];
        end
        
    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            ndf <= '0;
        else if(!spi_en && regAddressDecode[CTRLR1] && avalon_write)
            ndf <= avalon_writedata[15:0];

    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
        begin
            mhs <= '0;
            mdd <= '0;
            mwmod <= '0;
        end
        else if(!spi_en && regAddressDecode[MWCR] && avalon_write)
        begin
            mhs <= avalon_writedata[2]; // not implemented
            mdd <= avalon_writedata[1]; // not implemented
            mwmod <= avalon_writedata[0]; // not implemented
        end

    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            ser <= '0;
        else if(!spi_en && regAddressDecode[SER] && avalon_write)
            ser <= avalon_writedata[3:0];

    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            sckdv <= '0;
        else if(!spi_en && regAddressDecode[BAUDR] && avalon_write)
            sckdv <= {avalon_writedata[15:1], 1'b0};
            
    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            tft <= '0;
        else if(!spi_en && regAddressDecode[TXFTLR] && avalon_write)
            tft <= avalon_writedata[7:0];

    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            rft <= '0;
        else if(!spi_en && regAddressDecode[RXFTLR] && avalon_write)
            rft <= avalon_writedata[7:0];

    ///// Interrupts
    logic emptyTxFifo, almostEmptyTxFifo, fullTxFifo;
    logic fullRxFifo, almostFullRxFifo, emptyRxFifo;

    logic emptyTx;     assign emptyTx = almostEmptyTxFifo || emptyTxFifo;
    logic overflowTx;  assign overflowTx = fullTxFifo;
    logic fullRx;      assign fullRx = fullRxFifo || almostFullRxFifo;
    logic overflowRx;  assign overflowRx = fullRxFifo;
    logic underflowRx; assign underflowRx = emptyRxFifo;
    
    logic emptyTx_delay, overflowTx_delay;
    logic fullRx_delay, overflowRx_delay, underflowRx_delay;
    
    logic emptyTxStatusRisingEdge, overflowTxStatusRisingEdge;
    logic fullRxStatusRisingEdge,  overflowRxStatusRisingEdge, underflowRxStatusRisingEdge;

    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
        begin
            emptyTx_delay <= '0;
            overflowTx_delay <= '0;
            fullRx_delay <= '0;
            overflowRx_delay <= '0;
            underflowRx_delay <= '0;
        end
        else
        begin
            emptyTx_delay <= emptyTx;
            overflowTx_delay <= overflowTx;
            fullRx_delay <= fullRx;
            overflowRx_delay <= overflowRx;
            underflowRx_delay <= underflowRx;
        end
        
    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
        begin
            emptyTxStatusRisingEdge <= '0;
            overflowTxStatusRisingEdge <= '0;
            fullRxStatusRisingEdge <= '0;
            overflowRxStatusRisingEdge <= '0;
            underflowRxStatusRisingEdge <= '0;
        end
        else
        begin
            emptyTxStatusRisingEdge <= ~emptyTx_delay & emptyTx;
            overflowTxStatusRisingEdge <= ~overflowTx_delay & overflowTx;
            fullRxStatusRisingEdge <= ~fullRx_delay & fullRx;
            overflowRxStatusRisingEdge <= ~overflowRx_delay & overflowRx;
            underflowRxStatusRisingEdge <= ~underflowRx_delay & underflowRx;
        end
    
    logic emptyTxIrq, overflowTxIrq;
    logic fullRxIrq, overflowRxIrq, underflowRxIrq;
    logic pop, push;


    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            emptyTxIrq <= '0;
        else
            emptyTxIrq <= spi_en ? emptyTx : '0;
        
    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            overflowTxIrq <= '0;
        else if(spi_en)
        begin
            if(push)
                overflowTxIrq <= fullTxFifo;
            else if((regAddressDecode[TXOICR] || regAddressDecode[ICR]) && avalon_read)
                overflowTxIrq <= '0;
        end
        
    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            fullRxIrq <= '0;
        else
            fullRxIrq <= spi_en ? fullRx : '0;

    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            overflowRxIrq <= '0;
        else if(spi_en)
        begin
            if(overflowRxStatusRisingEdge)
                overflowRxIrq <= '1;
            else if((regAddressDecode[RXOICR] || regAddressDecode[ICR]) && avalon_read)
                overflowRxIrq <= '0;
        end

    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            underflowRxIrq <= '0;
        else if(spi_en)
        begin
            if(pop)
                underflowRxIrq <= emptyRxFifo;
            else if((regAddressDecode[RXUICR] || regAddressDecode[ICR]) && avalon_read)
                underflowRxIrq <= '0;
        end

    //////////////////////////////////////////////////////////// 

    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            {rxfim, rxoim, rxuim, txoim, txeim} <= '1;
        else if(regAddressDecode[IMR] && avalon_write)
            {rxfim, rxoim, rxuim, txoim, txeim} <= avalon_writedata[4:0];
            
    assign mstis = '0; // not implemented
    assign rxfis = rxfim & fullRxIrq;
    assign rxois = rxoim & overflowRxIrq;
    assign rxuis = rxuim & underflowRxIrq;
    assign txois = txoim & overflowTxIrq;
    assign txeis = txeim & emptyTxIrq;
            
    assign rxfir = fullRxIrq;
    assign rxoir = overflowRxIrq;
    assign rxuir = underflowRxIrq;
    assign txoir = overflowTxIrq;
    assign txeir = emptyTxIrq;
    
    assign txoicr = overflowTxIrq;
    assign rxoicr = overflowRxIrq;
    assign rxuicr = underflowRxIrq;
    assign icr = overflowTxIrq | overflowRxIrq | underflowRxIrq; // no mstis 

    assign avalon_irq = rxfis | rxois | rxuis | txois | txeis;

    //DMA control////////////////////////////////////////////////////////
    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            {tdmae, rdmae} <= '0;
        else if(regAddressDecode[DMACR] && avalon_write)
            {tdmae, rdmae} <= avalon_writedata[1:0]; // not implemented
            
    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            dmatdl <= '0;
        else if(regAddressDecode[DMATDLR] && avalon_write)
            dmatdl <= avalon_writedata[7:0]; // not implemented

    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            dmardl <= '0;
        else if(regAddressDecode[DMARDLR] && avalon_write)
            dmardl <= avalon_writedata[7:0]; // not implemented
            
    ////////////////////////////////////////////////////////////////////////
    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
            rsd <= '0;
        else if(regAddressDecode[RX_SAMPLE_DLY] && avalon_write)
            rsd <= avalon_writedata[6:0]; // not implemented
    ////////////////////////////////////////////////////////////////////////
    logic drSelect;
    assign drSelect = |regAddressDecode[_DR_MIRROR38:DR];
    
    logic[15:0] rxData;
    assign dr = avalon_write ? avalon_writedata[15:0] : rxData;

    logic avalon_read_delay, avalon_write_delay;
    always_ff @(posedge avalon_clock or posedge avalon_reset)
        if(avalon_reset)
        begin
            avalon_read_delay <= '0;
            avalon_write_delay <= '0;
        end
        else
        begin
            avalon_read_delay <= avalon_read;
            avalon_write_delay <= avalon_write;
        end

    assign pop = drSelect && avalon_read && !avalon_read_delay;
    assign push = drSelect && avalon_write && !avalon_write_delay;
    
    logic miso, mosi;
    Spi 
    #(
        .FIFO_DEPTH(256),
        .MAX_SLAVES_NUMBER(4),
        .MAX_WORD_SIZE(16)
    )
    spi_inst
    (
        .clock(avalon_clock),
        .reset(avalon_reset),
        .enable(spi_en),
        
        .sclkPolarity(scpol),
        .sclkPhase(scph),
        .divisor(sckdv),
        .wordSize(dfs),
        .recvNumber(ndf),
        .chipSelectEnable(ser),
        .rxSampleDelay(),
        
        .rxFifoEnable(~tmod[0]),
        .txFifoEnable(~tmod[1]),
        .rxFifoAlmostFullLevel(rft), // +1 ??????????????????????
        .rxFifoAlmostEmptyLevel('0),
        .txFifoAlmostFullLevel('1),
        .txFifoAlmostEmptyLevel(tft),
        .rxQueueSize(rxtfl),
        .txQueueSize(txtfl),
        
        .busy(busy),
        
        .push(push),
        .txData(dr),
        .fullTxFifo(fullTxFifo), 
        .emptyTxFifo(emptyTxFifo),
        .almostFullTxFifo(),
        .almostEmptyTxFifo(almostEmptyTxFifo),
        
        .pop(pop),
        .rxData(rxData),
        .fullRxFifo(fullRxFifo),
        .emptyRxFifo(emptyRxFifo), 
        .almostFullRxFifo(almostFullRxFifo),
        .almostEmptyRxFifo(),

    // spi interface 
        .oe(oe),
        
        .nCS(nCS),
        .SCLK(SCLK),
        .MOSI(mosi),
        .MISO(miso)
    );
    
    assign tfe = emptyTx;
    assign tfnf = ~overflowTx;
    assign rff = fullRx;
    assign rfne = ~underflowRx;

    assign miso = srl ? mosi : MISO;
    assign MOSI = mosi;

endmodule
