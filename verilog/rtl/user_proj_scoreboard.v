// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_scoreboard #(
    parameter BITS = 16
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    input wb_clk_i,
    input wb_rst_i,

   // IOs
    input  [8:0] io_in,
    output [23:0] io_out,
    output [23:0] io_oeb

);

  //    wire [6:0] led_out;
  //    seven_segment_seconds seven_segment_seconds(
  //       .clk(wb_clk_i),
  //       .reset(wb_rst_i),
  //       .update_compare(1'b0),
  //      .compare_in(24'h100),
  //     .led_out(led_out)
  //  );
      
  //   assign io_out = {11'h0, led_out};
  //  assign io_oeb = 16'h0;
     
     
     wire [7:0] seg_out1;
     wire [7:0] seg_out2;
     wire [3:0] team1_control;
     wire [3:0] team2_control;
     
     scoreboard scoreboard_inst(
        .clk(wb_clk_i),
        .reset(wb_rst_i),
        .team1_inc(io_in[0]),
        .team1_dec(io_in[1]),
        .team2_inc(io_in[2]),
        .team2_dec(io_in[3]),
        .team1_clear(io_in[4]),
        .team2_clear(io_in[5]),
        .inc_adjust(io_in[8:6]),
        .seg_out1(seg_out1),       
        .seg_out2(seg_out2),       
        .team1_control(team1_control), 
        .team2_control(team2_control)  
    );
 
     assign io_out = {seg_out1, seg_out2, team1_control, team2_control};
     assign io_oeb = 24'h0;
     
endmodule
`default_nettype wire
