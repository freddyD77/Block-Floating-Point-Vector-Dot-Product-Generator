module largestExp(clk, reset, invals, invals_rdy, valid_out, outvect, outExp, prevModDone);

	parameter					V, P, BIT, FPM;

    input							clk, reset, invals_rdy, prevModDone;
    input [P-1:0][BIT-1:0]			invals;
    output logic [V-1:0][BIT-1:0]	outvect;
    output logic [BIT-FPM-2:0]		outExp;
    output logic					valid_out;
    
    logic [BIT-FPM-2:0]			currentLargest;
    logic [V-1:0] 				index;
    logic [P-1:0][BIT-FPM-2:0]	inExps;
    logic [P-1:0][BIT-FPM-2:0]	intermmediateExps;

	integer i, j, k;

	//compLayer #(P, BIT, FPM) c0(.invals(inExps), .outvals(outvect[1:0]));
	function int index_a(input int width);
		index_a=0;
		for(int x=width; x<P; x=x*2)
    		index_a = index_a + x;  
  	endfunction
	
	genvar g;
	generate
		for (g=P; g>1; g=g/2) begin : compGenerator // <-- example block name	
			if(g==P) begin
	    		compLayer #(g, BIT, FPM) c0(.invals(inExps), 
	    			.outvals(intermmediateExps[index_a(g/2)-1:index_a(g)]));
	    	end else begin
	    		compLayer #(g, BIT, FPM) c1(.invals(intermmediateExps[index_a(g)-1:index_a(2*g)]), 
	    			.outvals(intermmediateExps[index_a(g/2)-1:index_a(g)]));//same point as P-2
	    	end
		end 
	endgenerate
     
    always_ff @(posedge clk) begin
		if(reset) begin
			valid_out<=0;
			index<=0;
			outExp<=0;
			currentLargest<=0;
			for(i=0;i<V;i=i+1)
				outvect[i]<=0;
		end else begin
			if(prevModDone) begin
				outExp<=currentLargest;
				valid_out<=1;
				index<=index;
			end else if(invals_rdy) begin
				index<=index+P;
				for(j=0;j<P;j=j+1) begin
					outvect[index+j][FPM-1:0]<=invals[j][FPM-1:0];//outputs a vector, P at a time
					outvect[index+j][BIT-2:FPM]<=inExps[j];
					outvect[index+j][BIT-1]<=invals[j][BIT-1];
				end
				if(intermmediateExps[P-2]>currentLargest)
					currentLargest<=intermmediateExps[P-2];//last exp from comparison tree
			end
		end
	end

	always_comb begin
		for(k=0;k<P;k=k+1)
			inExps[k]=invals[k][BIT-2: FPM]-(2**(BIT-FPM-2))+1;//need to parameterize this bias
	end

endmodule

module compLayer(invals, outvals);

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




