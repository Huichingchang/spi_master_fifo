`timescale 1ns/1ps
module spi_master_tb;

	//===參數===
	parameter DATA_WIDTH = 8;
	parameter FIFO_DEPTH = 16;
	
	//===測試用訊號===
	reg clk;
	reg rst_n;
	reg start;
	wire busy;
	
	wire sclk;
	wire mosi;
	wire cs_n;
	
	reg fifo_wr_en;
	reg [DATA_WIDTH-1:0] fifo_wr_data;
	wire fifo_empty;
	wire fifo_full;
	
	//=== Instantiate DUT ===
	spi_master #(
		.DATA_WIDTH(DATA_WIDTH),
		.FIFO_DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(4)
	) dut (
		.clk(clk),
		.rst_n(rst_n),
		.start(start),
		.busy(busy),
		.sclk(sclk),
		.mosi(mosi),
		.cs_n(cs_n),
		.fifo_wr_en(fifo_wr_en),
		.fifo_wr_data(fifo_wr_data),
		.fifo_empty(fifo_empty),
		.fifo_full(fifo_full)
	);
	
	//===時脈產生===
	always #5 clk=~clk;  //100MHz
	
	//===測試流程===
	initial begin
		$display("=== SPI Master + FIFO Testbench 開始 ===");
		
		//初始化
		clk = 0;
		rst_n = 0;
		start = 0;
		fifo_wr_en = 0;
		fifo_wr_data = 8'h00;
		
		//重置
		#20;
		rst_n = 1;
		
		//寫入資料到FIFO
		#10;
		fifo_wr_data = 8'hA5;
		fifo_wr_en = 1;
		#10;
		fifo_wr_data = 8'h3C;
		#10;
		fifo_wr_en = 0;
	
	   //啟動傳輸
		#20;
		start = 1;
		#10;
		start = 0;
		
		//等待傳輸完成
		wait (busy == 0);
		#50;
		
		$display("===傳輸完成,模擬結束===");
		$finish;
	end
endmodule
