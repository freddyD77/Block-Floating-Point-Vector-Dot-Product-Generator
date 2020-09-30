module mantissaAdj(clk, reset, invals_rdy, valid_out, mants, vect, inExp, outExp, outSigns);

	parameter					V=16, P=16, BIT=32, FPM=23, BFPM=4;
	localparam					EXP=BIT-FPM-1;//-1 since we exclude sign bit

    input							clk, reset, invals_rdy;
    input [P-1:0][BFPM+EXP:0]		vect;
    input [EXP-1:0]					inExp;
    output logic					valid_out;
    output logic [P-1:0][BFPM:0]	mants;//mantissas include invisible 1
    output logic [EXP-1:0]			outExp;
    output logic [P-1:0]			outSigns;
    
    logic [P-1:0][BFPM:0]			realMantsIn, shiftedMants;//mantissas including invisible 1
    logic [$clog2(V):0]				cnt;

	integer i, j, k;

    always_ff @(posedge clk) begin
		if(reset) begin
			valid_out<=0;//indicates when output is valid
			outExp<=0;//the block exp (largest exp)
			cnt<=0;//counts the vector partitions
			for(i=0;i<P;i=i+1)
				mants[i]<=0;//the adjusted mantissa vector
		end else begin
			valid_out<=invals_rdy;
			outExp<=inExp;
			for(i=0;i<P;i=i+1) begin//truncate bits that don't fit into new mantissa size
				mants[i]<=shiftedMants[i];//adjusted mantissas
				outSigns[i]<=vect[i][BFPM+EXP];//vector of the sign bits
			end
		end
	end

	always_comb begin
		for(k=0;k<P;k=k+1)//extend with the invisible 1
			realMantsIn[k]={1,vect[k][BFPM-1 -:BFPM]};
		for(j=0;j<P;j=j+1)//right shift mantissas by largest Exp - Exp of operand
			shiftedMants[j]=(realMantsIn[j] >> (inExp-vect[j][EXP+BFPM-1 -:EXP]));
	end

endmodule





