module tb_le();

    parameter                   V=8, P=2, BIT=32, FPM=23, BFPM=23;

    logic                       clk, reset, vector_rdy;
    logic [V-1:0][BIT-1:0]           vector, outvect;
    logic                       valid_out, valid_out2, valid_out3, done, done2;
    logic [P-1:0][BIT-1:0]           outvals;
    logic [BIT-FPM-2:0]         outExp;
    logic [P-1:0][BFPM-1:0]     mants;

    integer i;

    vectTran #(V, P, BIT) v0(.clk(clk), .reset(reset), .vector_rdy(vector_rdy), .vector(vector), 
                .valid_out(valid_out), .outvals(outvals), .done(done));

    largestExp #(V, P, BIT, FPM) l0(.clk(clk), .reset(reset), .invals(outvals),  
                .invals_rdy(valid_out), .valid_out(valid_out2), .outvect(outvect),  
                .outExp(outExp), .prevModDone(done));


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
	#20;
	$finish;
    end

endmodule
		











