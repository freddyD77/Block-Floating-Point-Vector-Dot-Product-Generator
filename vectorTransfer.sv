module vectTran(clk, reset, vector, vector_rdy, valid_out, outvals, done);

	parameter					V=4, P=2, BIT=32;

    input						clk, reset, vector_rdy;
    input [V-1:0][BIT-1:0]			vector;
    output logic				valid_out, done;
    output logic [P-1:0][BIT-1:0]	outvals;

    logic [V-1:0] 				index;

	integer i, j;
     
    always_ff @(posedge clk) begin
		if(reset) begin
			valid_out<=0;
			index<=0;
			done<=0;
			for(i=0;i<P;i=i+1)
				outvals[i]<=0;
		end else begin
			if(vector_rdy) begin
				if(index==V) begin
					index<=0;
					valid_out<=0;
					done<=1;
				end else begin
					done<=0;
					index<=index+P;
					valid_out<=1;
					for(j=0;j<P;j=j+1)
						outvals[j]<=vector[index+j];
				end
			end
		end
	end

endmodule




