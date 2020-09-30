module largestExp(clk, reset, invals, invals_rdy, valid_out, outvect, outExp);

    parameter					V=8, P=8, BIT=32, FPM=23, BFPM=4;
	localparam					EXP=BIT-FPM-1;//-1 since we exclude sign bit
	localparam					LAYERS=$clog2(P)/2;
	localparam					DELAY=LAYERS+1+($clog2(P)%2);//(LAYERS%2);//how long it takes the comparator tree to finish the comparisons
	
    input							clk, reset, invals_rdy;
    input [P-1:0][BIT-1:0]			invals;
    output logic [P-1:0][BFPM+EXP:0]outvect;
    output logic [EXP-1:0]			outExp;
    output logic					valid_out;
    
    logic [P-1:0][EXP-1:0]			inExps;
    logic [P-1:0][BFPM-1:0]			inMants;
    logic [P-1:0]					inSigns;			
    logic [P-1:0][EXP-1:0]			intermmediateExps;
    logic [((DELAY-1)*V)-1:0][BFPM+EXP:0]		FIFOvect;
    logic [(DELAY)-1:0]					valid;
    logic [EXP-1:0]						outExp2;


	integer i, j, k;

	//this function is used by generate block to determine which intermediate wires to use
	function int index_a(input int width);
		index_a=0;
		for(int x=width; x<P; x=x*2)
    		index_a = index_a + x;  
  	endfunction
	
	//generates a comparator tree depending on how many values arrive at a time
	genvar g;
	generate
		for (g=P; g>1; g=g/2) begin : compGenerator // <-- example block name	
			if(g==P) begin
	    		compLayer #(g, BIT, FPM) c0(.invals(inExps), 
	    			.outvals(intermmediateExps[index_a(g/2)-1:index_a(g)]));
	    	end else begin
	    		if($clog2(P/g)%2==1) begin//make a comparator layer with FFs, for every other layer
		    		compLayerFF #(g, BIT, FPM) c1ff(.clk(clk), .invals(intermmediateExps[index_a(g)-1:index_a(2*g)]), 
		    			.outvals(intermmediateExps[index_a(g/2)-1:index_a(g)]));//same point as P-2
		    	end else begin
		    		compLayer #(g, BIT, FPM) c1(.invals(intermmediateExps[index_a(g)-1:index_a(2*g)]), 
		    			.outvals(intermmediateExps[index_a(g/2)-1:index_a(g)]));//same point as P-2
		    	end
	    	end
		end 
	endgenerate

	generate
		if($clog2(P)%2==0) begin
			outputExpLayer #(EXP) out0(.inExp(intermmediateExps[P-2]), .outExp(outExp2));
		end else begin
			outputExpLayerFF #(EXP) out1(.clk(clk), .inExp(intermmediateExps[P-2]), .outExp(outExp2));
		end	

	endgenerate

     
    always_ff @(posedge clk) begin
		if(reset) begin
			//valid_out<=0;//indicates when all the exps have been observed (and biased)
			//outExp<=0;//the largest found exp (biased)
			for(i=0;i<((DELAY-1)*V);i=i+1)
				FIFOvect[i]<=0;//the vector fifo
		end else begin

			for(j=0;j<V;j=j+1) begin
				inMants[j]<=invals[j][FPM-1 -:BFPM];
				inExps[j]<=invals[j][BIT-2: FPM]-(2**(EXP-1))+1;//subtracts bias of exponent, for 8bit exp, bias=(2^7)-1
				inSigns[j]<=invals[j][BIT-1];
			end

			for(j=0;j<V;j=j+1) begin//inExps is available 1 clk later than other 2 parts
				FIFOvect[j][BFPM-1 -:BFPM]<=inMants[j];//outputs a vector, P at a time
				FIFOvect[j][EXP+BFPM-1 -:EXP]<=inExps[j];//although is only done after
				FIFOvect[j][BFPM+EXP]<=inSigns[j];		//looking through all elements
			end

			for(j=V;j<((DELAY-1)*V);j=j+1) begin
				FIFOvect[j]<=FIFOvect[j-V];
			end

			valid[0]<=invals_rdy;

			for(j=1;j<(DELAY);j=j+1)
				valid[j]<=valid[j-1];

			//outExp<=intermmediateExps[P-2];			
		end
	end

	always_comb begin
		outvect=FIFOvect[((DELAY-2)*V) +: V];//outputs a portion of the vector fifo per clock
		valid_out=valid[DELAY-1];
		outExp=outExp2;
	end

endmodule

module outputExpLayer(inExp, outExp);

	parameter		EXP=8;

	input [EXP-1:0]					inExp;
	output logic [EXP-1:0]			outExp;

	always_comb begin
		outExp=inExp;
	end	

endmodule

module outputExpLayerFF(clk, inExp, outExp);

	parameter		EXP=8;

	input 							clk;
	input [EXP-1:0]					inExp;
	output logic [EXP-1:0]			outExp;

	always_ff @(posedge clk) begin
		outExp<=inExp;
	end	

endmodule

module compLayer(invals, outvals);//layer of comparators

	parameter							P=4, BIT=32, FPM=23;

	input [P-1:0][BIT-FPM-2:0]			invals;
	output logic [(P/2)-1:0][BIT-FPM-2:0]	outvals;
	integer i;

	always_comb begin
		for(i=0;i<P;i=i+2) begin
			if(invals[i]>invals[i+1])
				outvals[i/2]=invals[i];
			else
				outvals[i/2]=invals[i+1];
		end
	end

endmodule

module compLayerFF(clk, invals, outvals);//layer of comparators

	parameter							P=4, BIT=32, FPM=23;

	input								clk;
	input [P-1:0][BIT-FPM-2:0]			invals;
	output logic [(P/2)-1:0][BIT-FPM-2:0]	outvals;
	integer i;

	always_ff @(posedge clk) begin
		for(i=0;i<P;i=i+2) begin
			if(invals[i]>invals[i+1])
				outvals[i/2]<=invals[i];
			else
				outvals[i/2]<=invals[i+1];
		end
	end

endmodule




