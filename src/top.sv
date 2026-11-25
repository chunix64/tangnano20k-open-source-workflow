`default_nettype none

module top (
  input logic clk,
  input logic [1:0] buttons,
  output logic [5:0] leds
);

  localparam int unsigned COUNTER_INTERVAL_MS = 100;
  localparam int unsigned COUNTER_INTERVAL = COUNTER_INTERVAL_MS * 27_000;

  logic [24:0] counter = '0;
  logic counter_flag = 1'b0;

  always_ff @(posedge clk) begin
    if (counter > COUNTER_INTERVAL - 1) begin
      counter <= '0;
      counter_flag <= 1'b1;
    end
    else begin
      counter <= counter + 1'b1;
      counter_flag <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin 
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
