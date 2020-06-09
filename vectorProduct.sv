module vectProd(clk, reset, invals, invals_rdy, prevModDone, inExp,
			invals2, invals_rdy2, prevModDone2, inExp2,
			valid_out, outVectProd, outExp	
	);

	parameter					V, P, BIT, FPM, BFPM;

    input								clk, reset, invals_rdy, prevModDone, invals_rdy2, prevModDone2;
    input [P-1:0][BFPM+1:0]				invals, invals2;//mantissa values include sign bit and invisible 1
    input [BIT-FPM-2:0]					inExp, inExp2;
    output logic [(2*(BFPM+2))-1+$clog2(V):0]	outVectProd;//is 2x size of mants, plus buffer bits for
    															//the adder tree
    output logic [BIT-FPM-2:0]			outExp;
    output logic						valid_out;
    
    logic [(2*(BFPM+2))-1+$clog2(V):0]			currentSum;
    logic [V-1:0] 				index;
    logic [P-1:0][(2*(BFPM+2))-1:0]	prods;//products are twice the bit width of operands
    logic [P-1:0][(2*(BFPM+2))-1+$clog2(P):0]	intermmediateSums;

	integer i, j, k;

	function int index_a(input int width);
		index_a=0;
		for(int x=width; x<P; x=x*2)
    		index_a = index_a + x;  
  	endfunction
	
	genvar g;
	generate
		for (g=P; g>1; g=g/2) begin : sumGenerator // <-- example block name	
			if(g==P) begin
	    		sumLayer #(g, 2*(BFPM+2), 0) s0(.invals(prods), 
	    			.outvals(intermmediateSums[index_a(g/2)-1:index_a(g)]));
	    	end else begin
	    		sumLayer #(g, 2*(BFPM+2), $clog2(P/g)) s1(.invals(intermmediateSums[index_a(g)-1:index_a(2*g)]), 
	    			.outvals(intermmediateSums[index_a(g/2)-1:index_a(g)]));//same point as P-2
	    	end
		end 
	endgenerate
     
    always_ff @(posedge clk) begin
		if(reset) begin
			valid_out<=0;
			index<=0;
			outExp<=0;
			currentSum<=0;
			outVectProd<=0;
		end else begin
			if(prevModDone & prevModDone2) begin
				outExp<=inExp+inExp2;
				valid_out<=1;
				index<=index;
				outVectProd<=currentSum;
			end else if(invals_rdy & invals_rdy2) begin
				index<=index+P;
				currentSum<=currentSum+intermmediateSums[P-2];//last sum from adder tree
			end
		end
	end

	always_comb begin
		for(k=0;k<P;k=k+1)
			prods[k]=invals[k]*invals2[k];
	end

endmodule

module sumLayer(invals, outvals);

	parameter							P, BIT, EXT;

	input [P-1:0][BIT+EXT-1:0]				invals;
	output logic [(P/2)-1:0][BIT+EXT:0]		outvals;//plus 1 bit after addition
	integer i;

	always_comb begin
		for(i=0;i<P;i=i+2) begin
			outvals[i/2]=invals[i]+invals[i+1];
		end
	end

endmodule
