module cache_tb();
reg read, write;
reg clk; 
wire[1023:0] load_data; 
reg[1023:0] write_data; 
reg[31:0] load_address;
reg[31:0] write_address;
wire hit;
wire ready; 
wire [7:0] mem_data_in[0:3];
reg [7:0] mem_data_out[0:3];
wire mem_write_en;
reg rst;
cache#(.n(13)) a_cache( read, write, clk, load_data, write_data, load_address, write_address,  hit, ready, mem_data_in, mem_data_out, mem_write_en, rst);
always #(5) clk = ~clk;
initial begin
read = 1;
write = 0;
clk = 0;
load_address = 32'b0;
#5; // 1st clk                5
#10; // 2nd clk               15
#10; // 3rd clk                  25
#10; // 4th clk               35
#5; 
mem_data_out[0] = 8'b1;
mem_data_out[1] = 8'b1;
mem_data_out[2] = 8'b1;
mem_data_out[3] = 8'b1;
#5; // 5th clk, now mem_data_out is ready to go into cache.  45
#5; // 50
#5; // 6th clk                       55
// ( last clk ] you can read = 0 but it needs read = 1 at posedge
//$display(mem_data_in);
#5; // 60 
read = 0;
#5; // 7th clk                      65
read = 1;
#10; // 8th clk now we should have hit cache        75
#10; //                                           85
read = 0;
write = 1;
write_data = 1024'b1;
#10; // 9th clk now we should write              95
write = 0;
read = 1;
load_address = 32'b01000000000000000000000000000000;

mem_data_out[0] = 8'b00000011;
mem_data_out[1] = 8'b00000000;
mem_data_out[2] = 8'b00000000;
mem_data_out[3] = 8'b00000000;
#10; // 10th clk we are loading sth that's not in cache          105
#10; // 11th                                                      115
#10; // 12th
#10; // 13th
#10; // 14th
#10; // 15th 6th of write back and same as first in read
#10; // 16th
#10; // 17th
#10; // 18th
#10; // 19th                                                      195   at this momemnt we should see that hit occurs
#10; // 20th                                                      205
$stop;
end
endmodule

