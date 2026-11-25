`default_nettype none

module top (
  input clk,
  input [1:0] buttons,
  output [5:0] leds
);

  localparam COUNTER_INTERVAL_MS = 100;
  localparam COUNTER_INTERVAL = COUNTER_INTERVAL_MS * 27_000;

  reg [24:0] counter;
  reg counter_flag;

  always @(posedge clk) begin
    if (counter > COUNTER_INTERVAL - 1) begin
      counter <= 25'b0;
      counter_flag <= 1'b1;
    end
    else begin
      counter <= counter + 1'b1;
      counter_flag <= 1'b0;
    end
  end

  always @(posedge clk) begin 
    if (counter_flag) begin
      leds[0] <= ~leds[0];
    end

    if (buttons[0] && counter_flag) begin
      leds[5] <= ~leds[5];
    end

    if (buttons[1] && counter_flag) begin
      leds[4] <= ~leds[4];
    end
  end

endmodule
