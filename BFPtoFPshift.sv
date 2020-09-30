module BFPtoFPshift(clk, reset, inMant, inval_rdy, inExp, inSign, inEnc,
			valid_out, outFP
	);

	parameter					V=16, P=16, BIT=32, FPM=23, BFPM=4;
	localparam					EXP=BIT-FPM-1;//-1 since we exclude sign bit
	localparam					LONGBFPM=(2*(BFPM+1))+1;//mantissa+sign+invisible1, times 2
	localparam					TREE_WIDTH=2**($clog2((LONGBFPM+$clog2(V))/2));
	localparam		  			RADIX=2*BFPM;
	localparam					TMP=FPM-RADIX;//23-8
	localparam					ENC_WIDTH=$clog2((LONGBFPM+$clog2(V))/2)+2;

    input							clk, reset, inval_rdy, inSign;
    input [(2*TREE_WIDTH)-1:0]		inMant;
    input [EXP-1:0]					inExp;
    input [ENC_WIDTH-1:0]			inEnc;
    output logic					valid_out;
    output logic [BIT-1:0]			outFP;

    logic [FPM-1:0]					fpMant;
    logic [(2*TREE_WIDTH)-1+FPM:0]	tempMant, shiftedMant;
    logic [EXP-1:0]					fpExp;
    logic [TMP-1:0]					zeroBuffer;
    
    
    


	integer i, j, k;

     
    always_ff @(posedge clk) begin
		if(reset) begin
			valid_out<=0;
			outFP<=0;
		end else begin
			valid_out<=inval_rdy;
			outFP<={inSign, fpExp, fpMant};//concatenates each section together
		end
	end

	always_comb begin
		zeroBuffer=0;
		if(FPM>RADIX) begin//mantissa reconversion depends if the current mant size is bigger than the target mant size
			tempMant={inMant, zeroBuffer};//15=TMP, buffer mantissa used to keep precision after shift
			fpMant=tempMant[(FPM-1+((2*TREE_WIDTH)-RADIX-1-inEnc))-:FPM];
		end else begin
			tempMant=inMant;
			fpMant=tempMant[(RADIX-1+((2*TREE_WIDTH)-RADIX-1-inEnc))-:FPM];
		end
		fpExp=inExp + ((2*TREE_WIDTH)-RADIX-1-inEnc) + (2**(EXP-1))-1;//re-applies exp bias
	end




endmodule
