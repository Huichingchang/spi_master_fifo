module spi_master #(
	parameter DATA_WIDTH = 8,
	parameter FIFO_DEPTH = 16,
	parameter ADDR_WIDTH = 4
)(
	
	input wire clk,  
	input wire rst_n,  
	
	//控制訊號
	input wire start,  //開始傳輸
	output reg busy,  //傳輸進行中標誌
	
	// SPI實體介面
	output reg sclk,
	output reg mosi,
	output reg cs_n,
	
	// FIFO寫入介面(外部寫入資料進來)
	input wire fifo_wr_en,
	input wire [DATA_WIDTH-1:0] fifo_wr_data,
	
	//狀態輸出
	output wire fifo_empty,
	output wire fifo_full
);

	//---狀態定義---
	reg [2:0] state;
	reg [2:0] next_state;
	localparam IDLE = 3'd0;
	localparam LOAD = 3'd1;
	localparam TRANS = 3'd2;
	localparam DONE = 3'd3;
	
	//---位元計數器---
	reg [2:0] bit_cnt;
	
	//---資料暫存器---
	reg [DATA_WIDTH-1:0] shift_reg;
	
	//---FIFO讀使能---
	reg fifo_rd_en;
	wire [DATA_WIDTH-1:0] fifo_rd_data;
	
	//---FIFO模組實例---
	tx_fifo #(
		.DATA_WIDTH(DATA_WIDTH),
		.FIFO_DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(ADDR_WIDTH)		
	) tx_fifo_inst(
		.clk(clk),
		.rst_n(rst_n),
		.write_en(fifo_wr_en),
		.write_data(fifo_wr_data),
		.read_en(fifo_rd_en),
		.read_data(fifo_rd_data),
		.empty(fifo_empty),
		.full(fifo_full)
	);
	
	//---FSM狀態轉移---
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			state <= IDLE;
		else
			state <= next_state;
	end
	
	always @(*) begin
		case (state)
			IDLE: next_state = (!fifo_empty && start)? LOAD : IDLE;
			LOAD: next_state = TRANS;
			TRANS: next_state = (bit_cnt == 7)? DONE : TRANS;
			DONE: next_state = (!fifo_empty)? LOAD : IDLE;
			default: next_state = IDLE;
		endcase
	end
	
	//--- FSM動作---
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			cs_n <= 1'b1;
			sclk <= 1'b0;
			bit_cnt <= 3'd0;
			mosi <= 1'b0;
			shift_reg <= 8'd0;
			fifo_rd_en <= 1'b0;
			busy <= 1'b0;
		end else begin
			fifo_rd_en <= 1'b0;  //預設關閉,只有在LOAD啟動
			
			case (state)
				IDLE: begin
					busy <= 1'b0;
					cs_n <= 1'b1;
					sclk <= 1'b0;
				end
				
				LOAD: begin
				   fifo_rd_en <= 1'b1;
				   shift_reg <= fifo_rd_data;
				   bit_cnt <= 3'd0;
				   busy <= 1'b1;
				   cs_n <= 1'b0;
				end
				
				TRANS: begin
					mosi <= shift_reg [7];
					sclk <= ~sclk;
					
					if (sclk) begin
						shift_reg <= {shift_reg[6:0], 1'b0};  //左移
						bit_cnt <= bit_cnt + 1;
					end
				end
				
				DONE: begin
					cs_n <= 1'b1;
					busy <= 1'b0;
				end
			endcase
		end
	end
endmodule
	
