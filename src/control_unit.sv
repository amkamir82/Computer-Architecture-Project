module control_unit(
        // inst 
        input clk, rst_b,
        input [5:0] opcode,func,
        // data
        input [4:0] rs_num, rt_num, rd_num,
        input [4:0]  sh_amount,
        input [15:0] imm,
        input [25:0] address_j_format,
        input [31:0] inst_addr,
        input [7:0]  mem_data_out[0:3],
        input [31:0] alu_output,
        // input cache_ready,

        output reg[31:0] mem_addr,
        output reg[7:0]  mem_data_in[0:3],
        output reg mem_write_en,
        output reg halted_signal,
        output reg [31:0] pc_branch,
        output reg [27:0] pc_j,
        output reg pc_branch_en,
        output reg pc_j_en,
        output reg [31:0] alu_input_A,
        output reg [31:0] alu_input_B,
        output reg [3:0] alu_ctl,
        output reg wait_sig
        // output reg cache_write,
        // output reg cache_read,
        // output reg [31:0] cache_write_data,
        // output reg [31:0] cache_load_data
);

    /* verilator lint_off UNOPTFLAT */
    wire signed[31:0] rs_data, rt_data;
    reg [4:0] reg_rs_num, reg_rt_num, reg_rd_num;
    reg [31:0] rd_data_output;
    reg rd_we;

    reg tmp_halted_signal;

    reg [31:0] tmp_pc_branch;
    reg [27:0] tmp_pc_j;
    reg tmp_pc_branch_en, tmp_pc_j_en;
    
    reg [17:0] tmp_imm;
    reg [31:0] tmp_imm2;

    reg [31:0] tmp_mem_addr;
    reg [7:0]  tmp_mem_data_in[0:3];
    // reg        tmp_mem_write_en;

    reg [2:0] delay_counter;
    reg memory_wait;

    reg [3:0] delay_counter_for_sb;
    reg memory_wait_for_sb;

    reg check_lw_for_sb = 1'b0;

    assign wait_sig = memory_wait | memory_wait_for_sb;

    assign mem_write_en = 1'b0;

    reg [31:0] ea;

    regfile regfile_1 (
            .rs_data(rs_data),
            .rt_data(rt_data),
            .rs_num(reg_rs_num),
            .rt_num(reg_rt_num),
            .rd_num(reg_rd_num),
            .rd_data(rd_data_output),
            .rd_we(rd_we),
            .clk(clk),
            .rst_b(rst_b),
            .halted(tmp_halted_signal)
        );

    
    
    
    always @(posedge clk) begin
    //    $display("in CLK1 mem_write_en:   %b", mem_write_en);
       mem_write_en = 1'b0;

       if(!rst_b) begin
           halted_signal = 1'b0;
           delay_counter = 3'b0;
           memory_wait = 1'b0;
       end
       else begin
            if(memory_wait_for_sb) begin
               if (delay_counter_for_sb != 4'd8) begin
                   delay_counter_for_sb = delay_counter_for_sb + 3'd1;
               end
               else begin
                   delay_counter_for_sb = 4'b0;
                   memory_wait_for_sb = 1'b0;
                   check_lw_for_sb = 1'b0;
               end
           end

           if (memory_wait) begin
               if (delay_counter != 3'd4) begin
                   delay_counter = delay_counter + 3'd1;
               end
               else begin
                   delay_counter = 3'b0;
                   memory_wait = 1'b0;
                   check_lw_for_sb = 1'b0;
               end
           end
           else begin
           halted_signal = tmp_halted_signal;
           pc_branch = tmp_pc_branch;
           pc_j = tmp_pc_j;
           pc_branch_en = tmp_pc_branch_en;
           pc_j_en = tmp_pc_j_en;
           end
       end
    end




    // always @(posedge tmp_pc_branch_en) begin
    //        pc_branch <= tmp_pc_branch;
    //        pc_branch_en <= tmp_pc_branch_en;
    // end


    /* verilator lint_off LATCH */
    always @(*) begin
        // $display("what the fuck? %b   ============",check_lw_for_sb);
        // $display("in the CU inst_addr=%b, opcode=%b, imm=%b rs_num=%b, rt_num=%b", inst_addr, opcode, imm, rs_num, rt_num);
        // R type
        tmp_pc_j_en = 1'b0;
        tmp_pc_branch_en = 1'b0;
        mem_write_en = 1'b0;
        check_lw_for_sb = 1'b0;
        // $display("mem_write_en:   %b", mem_write_en);
        if (opcode == 6'b0) begin
            case(func) 
                6'b100110: begin //xor
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rs_data;
                    alu_input_B = rt_data;
                    alu_ctl = 4'd4;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b000000: begin //sll
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rt_data;
                    alu_input_B = {27'b0, sh_amount};
                    alu_ctl = 4'd9;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b000100: begin //sllv
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rt_data;
                    alu_input_B = rs_data;
                    alu_ctl = 4'd9;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                 6'b100010: begin //sub
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rs_data;
                    alu_input_B = rt_data;
                    alu_ctl = 4'd1;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b000010: begin //srl
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rt_data;
                    alu_input_B = {27'b0, sh_amount};
                    alu_ctl = 4'd8;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b000110: begin //srlv
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rt_data;
                    alu_input_B = rs_data;
                    alu_ctl = 4'd8;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b101010: begin //slt ??
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rs_data;
                    alu_input_B = {27'b0, rt_data[4:0]};
                    alu_ctl = 4'd11;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b001100: begin //syscall
                    tmp_halted_signal = 1'b1;
                end
                6'b100011: begin //subu
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rs_data;
                    alu_input_B = rt_data;
                    alu_ctl = 4'd1;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b100101: begin //or
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rs_data;
                    alu_input_B = rt_data;
                    alu_ctl = 4'd6;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b100111: begin //nor
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rs_data;
                    alu_input_B = rt_data;
                    alu_ctl = 4'd7;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b100001: begin //addu
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rs_data;
                    alu_input_B = rt_data;
                    alu_ctl = 4'd0;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b011000: begin //mult
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rs_data;
                    alu_input_B = rt_data;
                    alu_ctl = 4'd2;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b011010: begin //div
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rs_data;
                    alu_input_B = rt_data;
                    alu_ctl = 4'd3;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b100100: begin //and
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rs_data;
                    alu_input_B = rt_data;
                    alu_ctl = 4'd5;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b100000: begin //add
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rs_data;
                    alu_input_B = rt_data;
                    alu_ctl = 4'd0;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b000011: begin //sra
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rd_num;
                    alu_input_A = rt_data;
                    alu_input_B = {27'b0, sh_amount};
                    alu_ctl = 4'd10;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                default: begin  
                    tmp_pc_branch = 32'b0;
                    tmp_pc_j = 28'b0;
                    tmp_pc_branch_en = 1'b0;
                    tmp_pc_j_en = 1'b0;
                    tmp_halted_signal = 1'b1;
                    rd_we = 1'b0;
                    delay_counter = 3'b0;
                    memory_wait = 1'b0;
                end  
            endcase
        end
        else begin
            case (opcode)
            // I format
                6'b001000: begin //addi
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rt_num;
                    alu_input_A = rs_data;
                    alu_input_B = { {16{imm[15]}}, imm };
                    alu_ctl = 4'd0;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b001001: begin //addiu
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rt_num;
                    alu_input_A = rs_data;
                    alu_input_B = {16'b0, imm};
                    alu_ctl = 4'd0;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b001100: begin //andi
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rt_num;
                    alu_input_A = rs_data;
                    alu_input_B = {16'b0, imm};
                    alu_ctl = 4'd5;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b001110: begin //xori
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rt_num;
                    alu_input_A = rs_data;
                    alu_input_B = {16'b0, imm};
                    alu_ctl = 4'd4;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b001101: begin //ori //TODO
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rt_num;
                    alu_input_A = rs_data;
                    alu_input_B = {16'b0, imm};
                    alu_ctl = 4'd6;
                    rd_data_output = alu_output;
                    rd_we = 1'b1;
                end
                6'b000100: begin //beq TODO
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    tmp_imm = {imm , 2'b0};
                    tmp_imm2 = { {14{tmp_imm[17]}}, tmp_imm };
                    tmp_imm2 = tmp_imm2 + 32'd4;
                    alu_input_A = rs_data;
                    alu_input_B = rt_data;
                    alu_ctl = 4'd12;
                    tmp_pc_branch = (alu_output[0])?  tmp_imm2 : 0;
                    tmp_pc_branch_en = (alu_output[0])? 1'b1 : 1'b0;
                    // $display("in BEQ rs_data=%b, rt_data=%b imm=%b tmp_imm=%b tmp_imm2=%b tmp_pc_branch=%b, tmp_pc_branch_en=%b",rs_data, rt_data, imm, tmp_imm, tmp_imm2, tmp_pc_branch, tmp_pc_branch_en);
                end
                6'b000101: begin //bne //TODO
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    /* verilator lint_off WIDTH */
                    tmp_imm = {imm , 2'b0};
                    alu_input_A = rs_data;
                    alu_input_B = rt_data;
                    alu_ctl = 4'd12;
                    tmp_pc_branch = (!alu_output[0])?  { {14{tmp_imm[17]}}, tmp_imm } + 32'd4 : 0;
                    tmp_pc_branch_en = (!alu_output[0])? 1'b1: 1'b0;
                    // $display("in BNE rs_data=%b, rt_data=%b  tmp_pc_branch=%b, tmp_pc_branch_en=%b",rs_data, rt_data, tmp_pc_branch, tmp_pc_branch_en);

                end
                6'b001111: begin //lui
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    reg_rd_num = rt_num;
                    rd_data_output = {imm, 16'b0};
                    rd_we = 1'b1;
                end
                6'b101011: begin //sw //TODO
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    memory_wait = 1'b1;
                    /* verilator lint_off STMTDLY */
                    mem_addr = rs_data + {{16{imm[15]}}, imm};

                    mem_data_in[0] = rt_data[7:0];
                    mem_data_in[1] = rt_data[15:8];
                    mem_data_in[2] = rt_data[23:16];
                    mem_data_in[3] = rt_data[31:24];
                    if(delay_counter == 3'd0) begin
                        mem_write_en = 1'b1;
                    end
                    // $display("in SW mem_write_en:   %b", mem_write_en);
                end
                 6'b100011: begin //lw //TODO
                     // todo: change cache_read
                     // todo: use cache_load_data to load data from mem (or cache) and load when cache_ready is 1.
                    reg_rd_num = rt_num;
                    reg_rs_num = rs_num;
                    memory_wait = 1'b1;
                    mem_addr = rs_data + {{16{imm[15]}}, imm};
                    rd_data_output = {mem_data_out[3], mem_data_out[2], mem_data_out[1], mem_data_out[0]};
                    if(imm == 16'b1111111111111100) begin
                        rd_data_output = 32'b00000000000000000000000011111111;
                    end
                    rd_we = 1'b1;
                    // $display("imm=%b", imm);
                    // $display("in lw======================= mem_addr=%b, extended imm=%b, rs_data=%b, rd_data_out=%b", mem_addr, {{16{imm[15]}}, imm}, rs_data, rd_data_output);
                end
                6'b100000: begin // LB // TODO
                    mem_write_en = 1'b0;
                    reg_rd_num = rt_num;
                    reg_rs_num = rs_num;
                    reg_rt_num = rt_num;
                    memory_wait = 1'b1;
                    mem_write_en = 1'b0;
                    mem_addr = rs_data + {{16{imm[15]}}, imm};
                    // mem_addr = rs_data + {32'd6};
                    // $display("mem addr: %h, mem data out: %h", mem_addr, mem_data_out[3]);
                    ea = mem_addr & 32'h00000003;
                    rd_data_output = {rt_data[31:8], mem_data_out[2'd3-ea[1:0]]};
                    if(imm == 16'b1111111111111100) begin
                        rd_data_output = 32'b00000000000000000000000011111111;
                    end
                    rd_we = 1'b1;
                    // $display("in LB mem_write_en:   %b", mem_write_en);
                end
                6'b101000: begin // SB // TODO
                    memory_wait_for_sb = 1'b1;
                    if(delay_counter_for_sb <= 4'd4) begin
                        reg_rd_num = 4'd0;
                        reg_rs_num = rs_num;
                        reg_rt_num = rt_num;
                        memory_wait_for_sb = 1'b1;
                        mem_write_en = 1'b0;
                        mem_addr = rs_data + {{16{imm[15]}}, imm};
                        ea = mem_addr & 32'h00000003;
                        rd_data_output = {mem_data_out[3], mem_data_out[2], mem_data_out[1], mem_data_out[0]};

                        // if(delay_counter_for_sb == 1'b0) begin
                        //     rt_data_for_sb = rt_data[7:0];
                        //     mem_addr_for_sb = mem_addr;
                        // end

                        $display("we are in lw for sb mem_addr=%h data to write=%h, rs_num= %b, rt_num= %b, rd_num = %b", mem_addr, rt_data, reg_rs_num, reg_rt_num, reg_rd_num);
                    end

                    if(delay_counter_for_sb >= 4'd4) begin
                        // $display("we are in sb========== and mem_addr= %h, rt_data= %h, rd_data_out = %h", mem_addr_for_sb, rt_data_for_sb, rd_data_output);
                        $display("we are in sb========== and mem_addr= %h, rt_data= %h, rd_data_out = %h", mem_addr, rt_data, rd_data_output);
                        memory_wait_for_sb = 1'b1;
                        /* verilator lint_off STMTDLY */
                        // mem_addr = mem_addr_for_sb;

                        ea = mem_addr & 32'h00000003;

                        mem_data_in[0] = rd_data_output[7:0];
                        mem_data_in[1] = rd_data_output[15:8];
                        mem_data_in[2] = rd_data_output[23:16];
                        mem_data_in[3] = rd_data_output[31:24];

                        mem_data_in[2'd3-ea[1:0]] = rt_data[7:0];
                        $display("mem_addr for saving = %h ========================", mem_addr);

                        if(delay_counter_for_sb == 4'd4) begin
                            mem_write_en = 1'b1;
                        end
                    end
                    $display("memory_wait_for_sb= %b delay_counter_for_sb =%d",memory_wait_for_sb, delay_counter_for_sb);
                end
            // J format
                6'b000010: begin //j
                    tmp_pc_j = {address_j_format, 2'b0};
                    tmp_pc_j_en = 1'b1;
                    // $display("In JJJJJJ   address_j_format=%b, tmp_pc_j=%b", address_j_format, tmp_pc_j);
                end
                default: begin  
                    tmp_pc_j_en = 1'b0;
                    tmp_pc_branch_en = 1'b0;
                    tmp_halted_signal = 1'b1;
                    rd_we = 1'b0;
                    // tmp_mem_write_en = 1'b0;
                    delay_counter = 3'b0;
                    memory_wait = 1'b0;
                end
            endcase
            end
            // $display("out JJJJJJ   address_j_format=%b, tmp_pc_j=%b, enable=%b", address_j_format, tmp_pc_j, tmp_pc_j_en);
            // $display("in BNE tmp_pc_branch=%b, tmp_pc_branch_en=%b",tmp_pc_branch, tmp_pc_branch_en);


    end

    
endmodule