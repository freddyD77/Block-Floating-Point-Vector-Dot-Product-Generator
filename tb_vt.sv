module tb_vt();

    parameter                   V=8, P=4, BIT=32;

    logic                       clk, reset, vector_rdy;
    logic [V-1:0][BIT-1:0]           vector;
    logic                       valid_out, done;
    logic [P-1:0][BIT-1:0]           outvals;

    integer i;

    vectTran #(V, P, BIT) v0(.clk(clk), .reset(reset), .vector_rdy(vector_rdy), .vector(vector), 
                .valid_out(valid_out), .outvals(outvals), .done(done));


    initial clk = 0;
	

    always begin
	#1 clk = !clk;


    end
    
    initial begin
	reset = 1;
	@(posedge clk); #1;
    vector[0]=32'b00111111110000000000000000000000;//shortreal'(i);
    vector[1]=32'b00111111111000000000000000000000;
    vector[2]=32'b00111111111100000000000000000000;
    vector[3]=32'b00111111111110000000000000000000;
    vector[4]=32'b00111111110000000000000000000000;//shortreal'(i);
    vector[5]=32'b00111111111000000000000000000000;
    vector[6]=32'b00111111111100000000000000000000;
    vector[7]=32'b00111111111110000000000000000000;
    vector_rdy=1;
	reset = 0;
    @(posedge clk); #1;
    @(posedge clk); #1;
    @(posedge clk); #1;
    vector_rdy=0;
    @(posedge clk); #1;
    @(posedge clk); #1;
    @(posedge clk); #1;

    end

    initial begin
	#20;
	$finish;
    end

endmodule
		











