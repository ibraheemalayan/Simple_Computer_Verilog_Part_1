module CPU (
    MAR,
    MBR_in,
    MBR_out,
    Mem_EN,
    Mem_CS, // control signal 0 for read, 1 for write
    clk
);

// addresses are 8 bits
output reg [7:0] MAR; // Memory Address Register

// Memory Buffer Registers (words are 16 bits)
output reg [15:0] MBR_out;
input wire [15:0] MBR_in;

// program counter
reg [15:0] PC;

// Instruction register
reg [15:0] IR;

// register file contains 16 registers each is 16 bits
reg [15:0] Registar [0:15];

// clock
input wire clk;

// memory control bus (memory enable, memory control signal)
output reg Mem_EN, Mem_CS;

// 3 bits since we have 8 states TODO
reg [2:0] state;

// states
parameter 
    copy_pc_to_mar = 0,
    fetch_instruction = 1,
    decode_instruction = 2,
    fetch_operand = 3,
    execute = 4;

// memory operations
parameter 
    mem_read = 0,
    mem_write = 1;

// opcodes
parameter 
    load = 4'h3, 
    add = 4'h7, 
    store = 4'hB;

initial begin

    $display("(%0t) > initializing CPU ...", $time);

    PC=20; // to start the sample program (defined in the memory module from address 20)
    state=0;
    Mem_EN=0;
    Mem_CS=0;

end

always @(posedge clk ) begin

    #2; // just to organize the output of display statements

    case (state)

        // 0: get instruction address from PC and put it in MAR (and send a read signal to the memory)
        copy_pc_to_mar: begin

            $display("\n ~~~~~~~~~~~~~~ New Instruction Cycle ~~~~~~~~~~~~~~ \n");

            #1 $display("(%0t) CPU > get_instruction_addr, PC=%0d", $time, PC);

            MAR <= PC;
            Mem_EN=1;
            Mem_CS=mem_read;

            state=fetch_instruction;
        end

        // 1: finish fetching instruction from MBR to Instruction Registar
        fetch_instruction: begin

            $display("(%0t) CPU > fetch_instruction", $time);

            $display("(%0t) CPU > MBR_in = %0h", $time, MBR_in);

            Mem_EN=0;

            IR <= MBR_in; // reading instruction to Instruction register
            PC <= PC + 1; //increase program counter to point to the next instruction
            state=decode_instruction;
        end

        // 2: decode instruction ( prepare to fetch operand , copy operand address from instruction to MAR and send read CS)
        decode_instruction: begin

            $display("(%0t) CPU > IR = %0h", $time, IR);

            $display("(%0t) CPU > decode_instruction", $time);

            MAR <= IR [7:0]; // copy first 8 bits from the instruction (memory address)
            state=fetch_operand;
        end

        // 3: fetch operand
        fetch_operand: begin

            $display("(%0t) CPU > fetch_operand", $time);

            state=execute;

            case (IR[15:12]) // determine operation based on opcode

                load : begin
                    Mem_EN=1;
                    Mem_CS=mem_read;
                end
            
                add : begin
                    Mem_EN=1;
                    Mem_CS=mem_read;
                end

                store : begin
                    // no operand to fetch
                end  

                default: begin
                    Mem_EN=0;
                    state = 5; // raise some exception (unknown opcode)
                    $display("(%0t) Unknown Opcode !", $time);
                end
                
            endcase
        end

        // 4: execute
        execute: begin

            $display("(%0t) CPU > execute", $time);

            Mem_EN=0;

            case (IR[15:12]) // determine operation based on opcode which is bits 12-15 according to our format

                // perform the addition of Ri to MDR_in and save the sum in Ri
                add : begin
                    Registar [ IR[11:8] ] <= Registar [ IR[11:8] ] + MBR_in;
                    state = 0;
                end

                // copy the value of the Memory Buffer Register to Ri
                load : begin
                    Registar [ IR[11:8] ] <= MBR_in;
                    state = 0;
                end

                // copy Ri to MBR_out and send enable, write signals to the memory to store it
                store : begin
                    MBR_out <= Registar [ IR[11:8] ];
                    Mem_EN=1;
                    Mem_CS=mem_write;
                    state=0;
                end

                default: begin
                    Mem_EN=0;
                    state = 5; // TODO raise some exception (unknown opcode)
                    $display("(%0t) Unknown Opcode !", $time);
                end
                    
            endcase
        end

    endcase
end

endmodule