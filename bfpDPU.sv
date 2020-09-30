module bfpDPU(clk, reset, vector, vector2, vector_valid, vector_valid2, valid_outFP, outFP);//very simple testbench, last 2 modules do not successfully parameterize with V or P

    //V is vector length, P is parallelism, BIT is incoming FP size, FPM is mantissa size of FP,
    //BFPM is mantissa size of BFP, Exponent lengths are calculated based off of these parameters,
    //Exponent length for BFP is assumed to be the same as that of FP.

    //Steps/modules:
    //2)find largest exponent in P values, for all V/P groups
    //3)adjust mantissa of each value (P at a time)
    //4)multiply and accumulate incoming values (P mantissas at a time), and accumulate with prior sum
    //5)count leading zeroes to determine how much to scale back resulting exponent
    //6)shift mantissa to fit to FP mantissa and adjust exponent accordingly. Resulting in FP value
    parameter                   V=4, P=V/1, BIT=32, FPM=23, BFPM=4, EXT=0;
    localparam                  EXP=BIT-FPM-1;//-1 since we exclude sign bit
    localparam                  LONGBFPM=2*(BFPM+2);//mantissa+sign+invisible1, times 2
    localparam                  SHIFTMAX=((LONGBFPM+$clog2(V)+1)/2);
    localparam                  TREE_WIDTH=2**($clog2((LONGBFPM+$clog2(V))/2));
    localparam                  ENC_WIDTH=$clog2((LONGBFPM+$clog2(V))/2)+2;

    input                           clk, reset, vector_valid, vector_valid2;
    input [V-1:0][BIT-1:0]          vector, vector2;
    output logic                    valid_outFP;
    output logic [BIT-1:0]          outFP;

    logic                           outSign;
    
    logic [P-1:0][BFPM+EXP:0]       outvect, outvect2;
    logic                           valid_outLE, valid_outMA, valid_outMA2,  
                                    valid_outVP, valid_outBFPtoFP, valid_outLE2;
    logic [EXP-1:0]                 outExpLE, outExpMA, outExpMA2, outExpVP, outExpBFPtoFP,
                                    outExpLE2;
    logic [P-1:0][BFPM+1:0]         mants, mants2;
    logic [LONGBFPM-1+$clog2(V):0]  outVectProd;
    logic [ENC_WIDTH-1:0]           outEnc;
    logic [(2*TREE_WIDTH)-1:0]      outMant;

    logic [P-1:0]                   signs1, signs2;


    integer i;


    largestExp #(V, P, BIT, FPM, BFPM) l0(.clk(clk), .reset(reset), .invals(vector),  
                .invals_rdy(vector_valid), .valid_out(valid_outLE), .outvect(outvect),  
                .outExp(outExpLE));

    largestExp #(V, P, BIT, FPM, BFPM) l1(.clk(clk), .reset(reset), .invals(vector2),  
                .invals_rdy(vector_valid2), .valid_out(valid_outLE2), .outvect(outvect2),  
                .outExp(outExpLE2));

    mantissaAdj #(V, P, BIT, FPM, BFPM) m0(.clk(clk), .reset(reset), .invals_rdy(valid_outLE), 
        .valid_out(valid_outMA), .vect(outvect), .mants(mants), .inExp(outExpLE), 
        .outExp(outExpMA), .outSigns(signs1));

    mantissaAdj #(V, P, BIT, FPM, BFPM) m1(.clk(clk), .reset(reset), .invals_rdy(valid_outLE2), 
        .valid_out(valid_outMA2), .vect(outvect2), .mants(mants2), .inExp(outExpLE2), 
        .outExp(outExpMA2), .outSigns(signs2));

    vectProd #(V, P, BIT, FPM, BFPM) vp0(.clk(clk), .reset(reset), .invals(mants), .invals_rdy(valid_outMA), 
        .inExp(outExpMA), .invals2(mants2), .invals_rdy2(valid_outMA2), 
        .inExp2(outExpMA2), .valid_out(valid_outVP), .outVectProd(outVectProd), 
        .outExp(outExpVP), .inSigns(signs1), .inSigns2(signs2)   
    );


    BFPtoFPclz #(V, P, BIT, FPM, BFPM) b0(.clk(clk), .reset(reset), .inval(outVectProd), 
        .inval_rdy(valid_outVP), .inExp(outExpVP), .valid_out(valid_outBFPtoFP), .outExp(outExpBFPtoFP), 
        .outMant(outMant), .outSign(outSign), .outEnc(outEnc)
    );

    BFPtoFPshift #(V, P, BIT, FPM, BFPM) b1(.clk(clk), .reset(reset), .inMant(outMant), 
        .inval_rdy(valid_outBFPtoFP), .inExp(outExpBFPtoFP), .inSign(outSign), .inEnc(outEnc),
        .valid_out(valid_outFP), .outFP(outFP)
    );

endmodule
