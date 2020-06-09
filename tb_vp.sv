module tb_vp();

    parameter                   V=8, P=4, BIT=32, FPM=23, BFPM=4;

    logic                       clk, reset, vector_rdy;
    logic [V-1:0][BIT-1:0]           vector, outvect;
    logic                       valid_out, valid_out2, valid_out3, valid_out3_cpy, done, done2, done2_cpy,
                                valid_out4;
    logic [P-1:0][BIT-1:0]           outvals;
    logic [BIT-FPM-2:0]         outExp, outExp2, outExp2_cpy, outExp3;
    logic [P-1:0][BFPM+1:0]     mants, mants_cpy;
    logic [(2*(BFPM+2))-1+$clog2(V):0] outVectProd;

    integer i;

    vectTran #(V, P, BIT) v0(.clk(clk), .reset(reset), .vector_rdy(vector_rdy), .vector(vector), 
                .valid_out(valid_out), .outvals(outvals), .done(done));

    largestExp #(V, P, BIT, FPM) l0(.clk(clk), .reset(reset), .invals(outvals),  
                .invals_rdy(valid_out), .valid_out(valid_out2), .outvect(outvect),  
                .outExp(outExp), .prevModDone(done));

    mantissaAdj #(V, P, BIT, FPM, BFPM) m0(.clk(clk), .reset(reset), .invals_rdy(valid_out2), 
        .valid_out(valid_out3), .vect(outvect), .mants(mants), .inExp(outExp), 
        .done(done2), .outExp(outExp2));

    mantissaAdj #(V, P, BIT, FPM, BFPM) m1(.clk(clk), .reset(reset), .invals_rdy(valid_out2), 
        .valid_out(valid_out3_cpy), .vect(outvect), .mants(mants_cpy), .inExp(outExp), 
        .done(done2_cpy), .outExp(outExp2_cpy));

    vectProd #(V, P, BIT, FPM, BFPM) vp0(.clk(clk), .reset(reset), .invals(mants), .invals_rdy(valid_out3), 
        .prevModDone(done2), .inExp(outExp2), .invals2(mants_cpy), .invals_rdy2(valid_out3_cpy), 
        .prevModDone2(done2_cpy), .inExp2(outExp2_cpy), .valid_out(valid_out4), .outVectProd(outVectProd), 
        .outExp(outExp3)  
    );


    initial clk = 0;
	

    always begin
	   #1 clk = !clk;
    end

    always_comb begin
        if(reset) begin
            vector_rdy=0;
        end else begin
            if(done)
                vector_rdy=0;
            else
                vector_rdy=1;
        end
    end
    
    initial begin
	reset = 1;
	@(posedge clk); #1;
    vector[0]=32'b00111111110000000000000000000000;//shortreal'(i);
    vector[1]=32'b01000000001000000000000000000000;
    vector[2]=32'b01000000011000000000000000000000;
    vector[3]=32'b01000000100100000000000000000000;
    vector[4]=32'b00111111110000000000000000000000;//shortreal'(i);
    vector[5]=32'b01000000001000000000000000000000;
    vector[6]=32'b01000000011000000000000000000000;
    vector[7]=32'b01000000100100000000000000000000;
    //vector_rdy=1;
	reset = 0;
    @(posedge clk); #1;
    @(posedge clk); #1;
    @(posedge clk); #1;
    //vector_rdy=0;
    @(posedge clk); #1;
    @(posedge clk); #1;
    @(posedge clk); #1;

    end

    initial begin
	#30;
	$finish;
    end

endmodule
		











