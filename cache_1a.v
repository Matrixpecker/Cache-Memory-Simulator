// cache 1a (write through + direct mapped)

`timescale 1ns / 1ps

module cache_1a(
  // with cpu
  input isRead,
  input [9:0] address,
  input [31:0] writeData,
  output reg [31:0] readData,
  output reg isHit,
  // with main memory
  output reg isMemRead,
  output reg [127:0] memWriteData,
  output reg isLock,
  input [127:0] memReadData
);

  reg [154:0] block [3:0];

  integer i;
  initial begin
    for (i=0; i<4; i=i+1) begin
      block[i] = 0;
    end
    isMemRead = 1;
    memWriteData = 0;
    isLock = 1;
  end

  reg [25:0] tag;
  reg [1:0] index;
  reg [1:0] wordOffset;
  always @(*) begin
    /* parse the address */
    tag = {0,address[9:6]};
    index = address [5:4];
    wordOffset = address[3:2];

    if (isRead == 1) begin // read
      /* check the cache block */
      isMemRead = 1;
      if (block[index][154]==1 && block[index][153:128]==tag) begin // hit
        isHit = 1;
      end else begin // miss
        /* call main memory */
        isHit = 0;
        isLock = 0;
        #1; // wait for main memory to respond
        isLock = 1;
        /* update the block */
        block[index][154] = 1;
        block[index][153:128] = tag;
        block[index][127:0] = memReadData; // we update the whole block
      end
      /* update the output */
      case(wordOffset)
        2'b00: readData = block[index][127:96];
        2'b01: readData = block[index][95:64];
        2'b10: readData = block[index][63:32];
        2'b11: readData = block[index][31:0];
      endcase
    end else begin // write
      isMemRead = 0;
      // readData = 0; // do not clear readData if the mode is switched to write
      if (block[index][154]==1 && block[index][153:128]==tag) begin // hit
        isHit = 1;
        case(wordOffset)
          2'b00: block[index][127:96] = writeData;
          2'b01: block[index][95:64] = writeData;
          2'b10: block[index][63:32] = writeData;
          2'b11: block[index][31:0] = writeData;
        endcase
      end else begin
        isHit = 0;
      end
        memWriteData = block[index][127:0]; // we write the whole block
        isLock = 0;
        #1;
        isLock = 1;
    end
  end

endmodule
