// Sync 128 cell of 16 bits memory

module MEMORY(
    MAR,
    data_in,
    data_out,
    EN, // enable (excute) read or write (according to CS)
    CS, // control signal 0 for read, 1 for write
    clk // clock
);

input wire EN, CS, clk;

// addresses are 8 bits
input wire [7:0] MAR;

// data registers (words are 16 bits)
input wire [15:0] data_in;
output reg [15:0] data_out;

// memory is 256 byte ( 128 cell, each cell is 2 bytes )
reg [15:0] Cells [0:127];

always @(posedge clk) begin

    #1;
    if (EN) begin

        if (CS) begin
            // write operation
            Cells[MAR] <= data_in;
            $display("(%0t) Memory Write operation data_written=%0h at %0d ", $time, data_in, MAR);
            
        end else begin
            // read operation
            data_out <= Cells[MAR];
            $display("(%0t) Memory Read operation data_read=%0h from address %0d ", $time, Cells[MAR], MAR);
            
        end
        
    end
    
end

initial begin
    
    $display("(%0t) > initializing memory ...", $time);

    // For testing
    // sample program

    // (instruction) Load R1, [30]
    // 0011 0001 00011110
    Cells [20] = 16'h311E;

    // (instruction) Add R1, [31]
    // 0111 0001 00011111
    Cells [21] = 16'h711F;

    // (instruction) Store R1, [32]
    // 1011 0001 00100000
    Cells [22] = 16'hB120;
   

    // (data) 5 at 30 / 8 at 31
    Cells [30] = 16'd5;
    Cells [31] = 16'd8;

    // to check if the simulation went right, the expected value of Cells[32] is "13" decimal ("D" hexadecimal)
    #200 $display("(%0t) > value of cell[32] (hexadecimal) is %0h ", $time, Cells[32]);

end
    
endmodule