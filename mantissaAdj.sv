module mantissaAdj(clk, reset, invals_rdy, valid_out, mants, vect, inExp, done, outExp);

	parameter					V, P, BIT, FPM, BFPM;

    input							clk, reset, invals_rdy;
    input [V-1:0][BIT-1:0]			vect;
    input [BIT-FPM-2:0]				inExp;
    output logic					valid_out, done;
    output logic [P-1:0][BFPM+1:0]	mants;//mantissas include invisible 1 and sign bit
    output logic [BIT-FPM-2:0]		outExp;
    
    logic [P-1:0][FPM:0]		realMantsIn, shiftedMants;//mantissas including invisible 1
    logic [P-1:0][FPM+1:0]		signedMants;//signed mantissas
    logic [V-1:0] 				index;

	integer i, j, k;

    always_ff @(posedge clk) begin
		if(reset) begin
			valid_out<=0;
			index<=0;
			done<=0;
			outExp<=0;
			for(i=0;i<P;i=i+1)
				mants[i]<=0;
		end else begin
			if(invals_rdy) begin
				if(index==V) begin
					index<=0;
					valid_out<=0;
					done<=1;
				end else begin
					done<=0;
					index<=index+P;
					valid_out<=1;
					outExp<=inExp;
					for(i=0;i<P;i=i+1)//truncate bits that don't fit into new mantissa size
						mants[i]<=signedMants[i][FPM+1:FPM-BFPM];//includes sign bit
				end
			end
		end
	end

	always_comb begin
		for(k=0;k<P;k=k+1)//extend with the invisible 1
			realMantsIn[k]={1,vect[index+k][FPM-1:0]};
		for(j=0;j<P;j=j+1)//right shift mantissas by largest Exp - Exp of operand
			shiftedMants[j]=(realMantsIn[j] >> (inExp-vect[index+j][BIT-2:FPM]));
		for(j=0;j<P;j=j+1)//2's complement mantissa depending on sign, and extend with sign bit
			//signedMants[j][FPM+1]=vect[index+j][BIT-1];
			if(vect[index+j][BIT-1]==1)
				signedMants[j]={1,(!shiftedMants[j])+1'b1};
			else
				signedMants[j]={0,shiftedMants[j]};
	end

endmodule





