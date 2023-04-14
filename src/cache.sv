module cache#(parameter n=13)(
    input read,
    input write,
    input clk,
    input rst,
    input [31:0] write_data,
    input [31:0] load_address,
    input [31:0] write_address,
    input [7:0] mem_data_out[0:3],

    output reg [31:0] load_data,
    output reg hit,
    output reg ready,
    output reg [7:0] mem_data_in[0:3],
    output reg mem_write_en
);
    parameter n_of_blocks= 1 << (n-7);
    reg [31:0] memory[n_of_blocks-1:0];
// each block has 1 word. each word has 32 bits. => each block has 32 bits = 1 words. cache has 2**(n-7) blocks. default is 2**(13-7) = 64 blocks
    reg valid[n_of_blocks-1:0]; // valid bits
    reg dirty[n_of_blocks-1:0]; // dirty bits
    reg [32-n:0] tag[n_of_blocks-1:0]; // tag bits . It has 32-n bits for each block. because each block has n bytes and address is 32 bits

    integer counter = 0;
    integer d_counter = 0;
    reg ram_data_ready;
    reg dirty_replace_ok;


    integer i;

    initial begin
        for (i = 0; i < n_of_blocks; i = i+1) begin
            valid[i] = 1'b0;
            dirty[i] = 1'b0;
            memory[i] = 32'bz;
        end
        ram_data_ready = 1'b0;
        dirty_replace_ok = 1'b0;
    end

    always @(negedge rst) begin
        ready = 1'b0;
    end


    always @(posedge clk) begin // p

        $display("posedge clk at time = %t.", $time);

        if (counter == 0 || (counter != 0 && d_counter != 0)) begin // i

            if (d_counter == 0) begin // j

                if (read) begin // h
                    if (valid[load_address[n-1:n-6]] == 1'b0 || load_address[31:n] != tag[load_address[n-1:n-6]]) // r
                        begin // r

                            if (dirty[load_address[n-1:n-6]] == 1'b1) begin
                                if (dirty_replace_ok == 1'b0) begin
                                    $display("dirty_replace not ok. setting d_counter = 1. time = %t", $time);
                                    mem_write_en = 1'b1;
                                    // todo: load only needed data: mabe we need only one Byte: use load_address[1:0]
                                    mem_data_in[3] = memory[load_address[n-1:n-6]][31:24];
                                    mem_data_in[2] = memory[load_address[n-1:n-6]][23:16];
                                    mem_data_in[1] = memory[load_address[n-1:n-6]][15:7];
                                    mem_data_in[0] = memory[load_address[n-1:n-6]][7:0];
                                    d_counter = 1;
                                end
                            end

                            if (ram_data_ready) begin // m
                                $display("ram data ready. now i'm writing mem_data_out in load_address. mem_data_out[0] = %b, mem_data_out[1] = %b, mem_data_out[2] = %b, mem_data_out[3] = %b. time = %t", mem_data_out[0], mem_data_out[1], mem_data_out[2], mem_data_out[3], $time);
                                // todo: store only needed data: mabe we need only one Byte: use load_address[1:0]
                                memory[load_address[n-1:n-6]][31:24] = mem_data_out[3];
                                memory[load_address[n-1:n-6]][23:16] = mem_data_out[2];
                                memory[load_address[n-1:n-6]][15:7] = mem_data_out[1];
                                memory[load_address[n-1:n-6]][7:0] = mem_data_out[0];
                                tag[load_address[n-1:n-6]] = load_address[31:n];
                                valid[load_address[n-1:n-6]] = 1'b1;
                                dirty[load_address[n-1:n-6]] = 1'b0;
                                hit = 1'b1;
                                ready = 1'b1;
                                load_data = memory[load_address[n-1:n-6]];
                                ram_data_ready = 1'b0;
                                dirty_replace_ok = 1'b0;
                            end // m
                            else begin // m
                                $display("ram data not ready. setting counter = 1. time = %t", $time);
                                ready = 1'b0;
                                hit = 1'b0;
                                load_data = 32'bz;
                                counter = 1;
                            end // m

                        end // r
                    else begin // r
                        ready = 1'b1;
                        hit = 1'b1;
                        load_data = memory[load_address[n-1:n-6]];
                        $display("successful hit. loading value %b to load_data. at time = %t", load_data, $time);
                    end // r
                end // h
                else if (write) begin // h
                    $display("writing write_data = %b in address load_address[n-1:n-6] = %b at time %t", write_data, load_address[n-1:n-6], $time);
                    memory[load_address[n-1:n-6]] = write_data;
                    dirty[load_address[n-1:n-6]] = 1'b1;
                end // h

            end // j
            else begin // j
                $display("d_counter is %d and now its going to increase. time = %t", d_counter, $time);
                d_counter = d_counter+1;
                if (d_counter == 2) begin
                    mem_write_en = 1'b0;
                end
                if (d_counter == 6) begin
                    $display("d_counter was 6 so now its 0. time = %t", $time);
                    dirty_replace_ok = 1'b1;
                    d_counter = 0;
                end
            end // j

        end // i
        else begin  // i
            $display("counter is %d and now its going to increase. time = %t", counter, $time);
            counter = counter+1;
            if (counter == 5) begin
                $display("counter was 5 so now its 0. time = %t", $time);
                counter = 0;
                // todo: we need to return this reg to the outside of the module??
                ram_data_ready = 1'b1;
            end
        end // i
    end // p
endmodule : cache

