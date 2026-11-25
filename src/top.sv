`default_nettype none

module top (
  input logic clk,
  input logic [1:0] buttons,
  output logic [5:0] leds
);

  localparam int unsigned TIMER_PERIOD_MS = 100;
  localparam int unsigned TIMER_TICKS = TIMER_PERIOD_MS * 27_000;

  logic [$clog2(TIMER_TICKS)-1:0] timer = '0;
  logic timer_flag = 1'b0;

  always_ff @(posedge clk) begin
    if (timer > TIMER_TICKS - 1) begin
      timer <= '0;
      timer_flag <= 1'b1;
    end
    else begin
      timer <= timer + 1'b1;
      timer_flag <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin 
    if (timer_flag) begin
      leds[0] <= ~leds[0];
    end

    if (buttons[0] && timer_flag) begin
      leds[5] <= ~leds[5];
    end

    if (buttons[1] && timer_flag) begin
      leds[4] <= ~leds[4];
    end
  end

endmodule
