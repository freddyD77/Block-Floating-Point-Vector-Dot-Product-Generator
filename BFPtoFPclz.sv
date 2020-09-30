module BFPtoFPclz(clk, reset, inval, inval_rdy, inExp,
			valid_out, outMant, outExp, outEnc, outSign
	);

	parameter					V=16, P=16, BIT=32, FPM=23, BFPM=4;
	localparam					EXP=BIT-FPM-1;//-1 since we exclude sign bit
	localparam					LONGBFPM=(2*(BFPM+1))+1;//mantissa+sign+invisible1, times 2
	localparam		  			ODD=(LONGBFPM-1+$clog2(V))%2;
	localparam					TREE_WIDTH=2**($clog2((LONGBFPM+$clog2(V))/2));
	localparam					ENC_WIDTH=$clog2((LONGBFPM+$clog2(V))/2)+2;


    input								clk, reset, inval_rdy;
    input [LONGBFPM-1+$clog2(V):0]		inval;
    input [EXP-1:0]						inExp;
    output logic [(2*TREE_WIDTH)-1:0]	outMant;
    output logic						valid_out;
    output logic [EXP-1:0]				outExp;
    output logic [ENC_WIDTH-1:0]		outEnc;
    output logic 						outSign; 
    
    logic [TREE_WIDTH-1:0][1:0]			TwoBitVals, TwoBitEncs;//2 bits, amount = half of bit count
    logic [LONGBFPM-1+$clog2(V)-1:0]	unsignedVal;//has 1 less bit than inval
    logic [LONGBFPM-1+$clog2(V):0]		unsignedValWithExtra0;//used incase there were odd bits
    logic [LONGBFPM-1+$clog2(V):0]		usedVal;//used incase there were odd bits
    logic								sign;
    logic [(2*TREE_WIDTH)-(LONGBFPM+$clog2(V))-1:0]	zeroBuffer;

	integer i, j, k;

	function int index_a(input int width);
		index_a=0;
		for(int x=width; x<TREE_WIDTH; x=x*2)
    		index_a = index_a + x;  
  	endfunction



///////////////////////////////////////////////ALL IN ONE GEN

	logic [TREE_WIDTH-1:0][ENC_WIDTH-1:0]	intermmediateEncs;
	genvar g;
	generate
		for (g=TREE_WIDTH; g>1; g=g/2) begin : encGenerator // <-- example block name	
			if(g==TREE_WIDTH) begin
	    		clziLayer #($clog2(TREE_WIDTH/g)+2, g) clz0(.encIN(TwoBitEncs), 
	    			.encOUT(intermmediateEncs[index_a(g/2)-1:index_a(g)]));
	    	end else begin
	    		clziLayer #($clog2(TREE_WIDTH/g)+2, g) clz1(.encIN(intermmediateEncs[index_a(g)-1:index_a(2*g)]), 
	    			.encOUT(intermmediateEncs[index_a(g/2)-1:index_a(g)]));//same point as P-2
	    	end
		end 
	endgenerate
//////////////////////////////////////////////ALL IN ONE GEN END

     
    always_ff @(posedge clk) begin
		if(reset) begin
			valid_out<=0;
			outMant<=0;
			outEnc<=0;
			outExp<=0;
			outSign<=0;
		end else begin
			outEnc<=intermmediateEncs[TREE_WIDTH-2];//last enc from enc tree 
			valid_out<=inval_rdy;
			outMant<={zeroBuffer,usedVal};//include filler zeros that are represented in encoding
			outExp<=inExp;
			outSign<=sign;
		end
	end

	always_comb begin
		if(inval[LONGBFPM-1+$clog2(V)]==1) begin//revert signed property to tradional FP notation
			unsignedVal=(~inval)+1'b1;
			sign=1;
		end else begin
			unsignedVal=inval;
			sign=0;
		end
		unsignedValWithExtra0={0, unsignedVal};//duplicate value incase a zero filler is needed when inserting into clz tree
		
		if(ODD)//this may belong in a generate block instead
			usedVal=unsignedValWithExtra0;//use extended value if there are odd number of bits
		else
			usedVal=unsignedVal;

		for(k=0;k<LONGBFPM-1+$clog2(V);k=k+2)
			TwoBitVals[k/2]=usedVal[k+:2];//seperate input into 2 bit vals
		for(k=LONGBFPM-1+$clog2(V);k<2*TREE_WIDTH;k=k+2)//clz tree expects a 2^x input width,
			TwoBitVals[k/2]=2'b00;//so we fill up empty spots with zeros

		for(i=0;i<TREE_WIDTH;i=i+1) begin//convert to encodings
	  		case (TwoBitVals[i])
		        2'b00    :  TwoBitEncs[i] = 2'b10;
		        2'b01    :  TwoBitEncs[i] = 2'b01;
		        default  :  TwoBitEncs[i] = 2'b00;
	      	endcase
	    end

	    zeroBuffer = 0;

	end

endmodule


module clzi #//this module expects there to be 2^x encodings, this solution was found at https://electronics.stackexchange.com/questions/196914/verilog-synthesize-high-speed-leading-zero-count/196992
(
   parameter   N = 2,
   localparam   WI = 2 * N,
   localparam   WO = N + 1
)
(
   input wire     [WI-1:0]    		d,
   output logic   [WO-1:0]    		q
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

module clziLayer(encIN, encOUT);

	parameter 					N=2, IN=8;
	localparam					OUT=2**($clog2(IN)-1);

	input [IN-1:0][N-1:0]		encIN;
	output logic [OUT-1:0][N:0]	encOUT;

	genvar g;
	generate
		for (g=0; g<OUT; g=g+1) begin : encLayerGen 	
			clzi #(N) clz(.d({encIN[IN-1-(2*g)], encIN[IN-2-(2*g)]}), 
    			.q(encOUT[OUT-1-g]));
		end 
	endgenerate

endmodule
