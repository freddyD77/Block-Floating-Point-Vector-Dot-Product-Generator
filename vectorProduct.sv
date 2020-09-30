module vectProd(clk, reset, invals, invals_rdy, inExp,
			invals2, invals_rdy2, inExp2,
			valid_out, outVectProd, outExp, inSigns, inSigns2	
	);

	parameter					V=8, P=8, BIT=32, FPM=23, BFPM=4;
	localparam					EXP=BIT-FPM-1;//-1 since we exclude sign bit
	localparam					LONGBFPM=(2*(BFPM+1))+1;//mantissa+sign+invisible1, times 2
	localparam					DELAY=$clog2(P)+1;//+1 for the extra multiplier pipeline, and signed mants

    input									clk, reset, invals_rdy, invals_rdy2;
    input [P-1:0][BFPM:0]					invals, invals2;//mantissa values include sign bit and invisible 1
    input [EXP-1:0]							inExp, inExp2;
    input [P-1:0]							inSigns, inSigns2;
    output logic [LONGBFPM-1+$clog2(V):0]	outVectProd;//is 2x size of mants, plus buffer bits for
    															//the adder tree
    output logic [EXP-1:0]					outExp;
    output logic							valid_out;
    
    logic [P-1:0][LONGBFPM-2:0]				uns_prods;//products are twice the bit width of operands
    logic [P-1:0][LONGBFPM-1:0]				prods;
    logic [P-1:0][LONGBFPM-1+$clog2(P):0]	intermmediateSums;
    logic [(DELAY+1)-1:0]					valid;
    logic [(DELAY+1)-1:0][EXP-1:0]			exp;

	integer i, j, k;

	//this function is used by generate block to determine which intermediate wires to use
	function int index_a(input int width);
		index_a=0;
		for(int x=width; x<P; x=x*2)
    		index_a = index_a + x;  
  	endfunction
	
	//generate adder tree depending on parallelism P
	genvar g;
	generate
		for (g=P; g>1; g=g/2) begin : sumGenerator // <-- example block name	
			if(g==P) begin
	    		sumLayerFF #(g, LONGBFPM, 0) s0(.clk(clk), .invals(prods), 
	    			.outvals(intermmediateSums[index_a(g/2)-1:index_a(g)]));
	    	end else begin
	    		sumLayerFF #(g, LONGBFPM, $clog2(P/g)) s1(.clk(clk), .invals(intermmediateSums[index_a(g)-1:index_a(2*g)]), 
	    			.outvals(intermmediateSums[index_a(g/2)-1:index_a(g)]));//same point as P-2
	    	end
		end
		if(BFPM<=4) begin//use packed multiplier if possible
			packedMultFF #(P, BFPM) pm0(.clk(clk), .invals(invals), .invals2(invals2), .outvals(uns_prods));
		end else begin
			normMultFF #(P, BFPM) nm0(.clk(clk), .invals(invals), .invals2(invals2), .outvals(uns_prods));
		end 
	endgenerate

	
     
    always_ff @(posedge clk) begin
		if(reset) begin
			//outVectProd<=0;//the result of the vector product
		end else begin

			//outVectProd<=/*$signed(outVectProd)+*/$signed(intermmediateSums[P-2]);//final sum from the adder tree
				
			for(k=0;k<P;k=k+1) begin
				if(inSigns[k] != inSigns2[k])//need to add a bit when incorporating sign, to get desired represented range
					prods[k]<={1'b1,(~uns_prods[k])+1'b1};
				else
					prods[k]<={1'b0,uns_prods[k]};
			end

			valid[0]<=invals_rdy & invals_rdy2;
			for(j=1;j<(DELAY+1);j=j+1)
				valid[j]<=valid[j-1];

			exp[0]<=inExp+inExp2;
			for(j=1;j<(DELAY+1);j=j+1)
				exp[j]<=exp[j-1];

		end
	end

	always_comb begin
		valid_out=valid[DELAY];
		outExp=exp[DELAY];
		outVectProd=/*$signed(outVectProd)+*/$signed(intermmediateSums[P-2]);//final sum from the adder tree
	end

endmodule

(* use_dsp = "simd" *) module sumLayer(invals, outvals);//single layer of adder tree

	parameter							P=2, BIT=2, EXT=0;//bit extension is different for each layer

	input [P-1:0][BIT+EXT-1:0]				invals;
	output logic [(P/2)-1:0][BIT+EXT:0]		outvals;//plus 1 bit after addition
	integer i;

	always_comb begin
		for(i=0;i<P;i=i+2) begin
			outvals[i/2]=$signed(invals[i])+$signed(invals[i+1]);
		end
	end

endmodule

(* use_dsp = "simd" *) module sumLayerFF(clk, invals, outvals);//single layer of adder tree

	parameter							P=2, BIT=2, EXT=0;//bit extension is different for each layer

	input 									clk;
	input [P-1:0][BIT+EXT-1:0]				invals;
	output logic [(P/2)-1:0][BIT+EXT:0]		outvals;//plus 1 bit after addition
	integer i;

	always_ff @(posedge clk) begin
		for(i=0;i<P;i=i+2) begin
			outvals[i/2]<=$signed(invals[i])+$signed(invals[i+1]);
		end
	end

endmodule

(* use_dsp = "yes" *) module packedMultFF(clk, invals, invals2, outvals);//packed multiplier

	parameter							P=2, BFPM=4;
	localparam							LONGBFPM=(2*(BFPM+1))+1;//length of actual products inside the packed products
	localparam							PACKEDPROD=2*((3*BFPM)+4);//length of the packed products

	input 									clk;
	input [P-1:0][BFPM:0]					invals, invals2;
	output logic [P-1:0][LONGBFPM-2:0]		outvals;
	logic [(P/2)-1:0][PACKEDPROD-1:0]		packedProds;
	logic [BFPM+1:0]						zero;//zero-bits filler in between proper operands
	integer i, k;

	assign zero = 0;

	always_ff @(posedge clk) begin
		for(i=0;i<P;i=i+2) begin
			packedProds[i/2]<=$unsigned({invals[i], zero, invals[i+1]})
								*$unsigned({invals2[i], zero, invals2[i+1]});
		end
	end

	always_comb begin
		for(k=0;k<P;k=k+2) begin
			outvals[k]=packedProds[(k/2)][PACKEDPROD-1 -:(LONGBFPM-1)];
			outvals[k+1]=packedProds[(k/2)][LONGBFPM-2:0];
		end
	end

endmodule

(* use_dsp = "yes" *) module normMultFF(clk, invals, invals2, outvals);//normal multiplier

	parameter							P=2, BFPM=4;
	localparam							LONGBFPM=(2*(BFPM+1))+1;

	input 									clk;
	input [P-1:0][BFPM:0]					invals, invals2;
	output logic [P-1:0][LONGBFPM-2:0]		outvals;
	integer i;

	always_ff @(posedge clk) begin
		for(i=0;i<P;i=i+1) begin
			outvals[i]<=$unsigned(invals[i])*$unsigned(invals2[i]);
		end
	end

endmodule
