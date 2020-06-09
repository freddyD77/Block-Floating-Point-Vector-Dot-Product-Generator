module BFPtoFP(clk, reset, inval, inval_rdy, inExp,
			valid_out, outVectProdFP
	);

	parameter					V, P, BIT, FPM, BFPM;
	localparam		  			ODD=((2*(BFPM+2))-1+$clog2(V))%2;

    input											clk, reset, inval_rdy;
    input [(2*(BFPM+2))-1+$clog2(V):0]				inval;
    input [BIT-FPM-2:0]								inExp;
    output logic [(2*(BFPM+2))-1+$clog2(V):0]		outVectProdFP;
    output logic									valid_out;
    
    logic [(((2*(BFPM+2))+$clog2(V))/2)-1:0][1:0]	TwoBitVals, TwoBitEncs;//2 bits, amount = half of bit count
    logic [(2*(BFPM+2))-1+$clog2(V)-1:0]			unsignedVal;//has 1 less bit that inval
    logic [(2*(BFPM+2))-1+$clog2(V):0]				unsignedValWithExtra0;//used incase there were odd bits
    logic [(2*(BFPM+2))-1+$clog2(V):0]				usedVal;//used incase there were odd bits
    logic 											sign; 

    logic [$clog2((2*(BFPM+2))-1+$clog2(V)):0]			resultEnc;
    logic [V-1:0] 				index;
    logic [P-1:0][(2*(BFPM+2))-1:0]	prods;//products are twice the bit width of operands
    logic [(((2*(BFPM+2))+$clog2(V))/2)-1:0][$clog2((2*(BFPM+2))+$clog2(V)):0]	intermmediateEncs;

	integer i, j, k;

	function int index_a(input int width);
		index_a=0;
		for(int x=width; x<P; x=x*2)
    		index_a = index_a + x;  
  	endfunction

	genvar g;
	generate
		for (g=P; g>1; g=g/2) begin : encGenerator // <-- example block name	
			if(g==P) begin
	    		clzi #(g, 2) clz0(.d(TwoBitEncs), 
	    			.q(intermmediateEncs[index_a(g/2)-1:index_a(g)]));
	    	end else begin
	    		clzi #(g, $clog2(P/g)+1) clz1(.d(intermmediateEncs[index_a(g)-1:index_a(2*g)]), 
	    			.q(intermmediateEncs[index_a(g/2)-1:index_a(g)]));//same point as P-2
	    	end
		end 
	endgenerate
     
    always_ff @(posedge clk) begin
		if(reset) begin
			valid_out<=0;
			index<=0;
			outVectProdFP<=0;
			resultEnc<=0;
		end else begin
			if(inval_rdy) begin
				index<=index+P;
				resultEnc<=intermmediateEncs[(((2*(BFPM+2))+$clog2(V))/2)-2];//last enc from enc tree
			end
		end
	end

	always_comb begin
		if(inval[(2*(BFPM+2))-1+$clog2(V)]==1) begin
			unsignedVal=(!inval)+1'b1;
			sign=1;
		end else begin
			unsignedVal=inval;
			sign=0;
		end
		unsignedValWithExtra0={0, unsignedVal};
		if(ODD)//is there a way to avoid this redundant mux? maybe put this if case in a generate block
			usedVal=unsignedValWithExtra0;
		else
			usedVal=unsignedVal;

		for(k=0;k<(2*(BFPM+2))-1+$clog2(V);k=k+2)
			TwoBitVals[k/2]=usedVal[k+:2];//seperate input into 2 bit vals

		for(i=0;i<((2*(BFPM+2))+$clog2(V))/2;i=i+1) begin
	  		case (TwoBitVals[i])
		        2'b00    :  TwoBitEncs[i] = 2'b10;
		        2'b01    :  TwoBitEncs[i] = 2'b01;
		        default  :  TwoBitEncs[i] = 2'b00;
	      	endcase
	    end
	end



endmodule

/*module enc
(
   input wire     [1:0]       d,
   output logic   [1:0]       q
);

   always_comb begin
      case (d[1:0])
         2'b00    :  q = 2'b10;
         2'b01    :  q = 2'b01;
         default  :  q = 2'b00;
      endcase
   end

endmodule // enc*/

module clzi #
(
   // external parameter
   parameter   P,
   parameter   N = 2,
   // internal parameters
   localparam   WI = 2 * N,
   localparam   WO = N + 1
)
(
   input wire     [P-1:0][WI-1:0]    		d,
   output logic   [(P/2)-1:0][WO-1:0]    	q
);

   always_comb begin
      if (d[N - 1 + N] == 1'b0) begin
         q[WO-1] = (d[N-1+N] & d[N-1]);
         q[WO-2] = 1'b0;
         q[WO-3:0] = d[(2*N)-2 : N];
      end else begin
         q[WO-1] = d[N-1+N] & d[N-1];
         q[WO-2] = ~d[N-1];
         q[WO-3:0] = d[N-2 : 0];
      end
   end

endmodule // clzi
