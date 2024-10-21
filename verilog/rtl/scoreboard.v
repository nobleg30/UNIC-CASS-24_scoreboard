module scoreboard (
    input wire clk,                   // Clock signal
    input wire reset,                 // Reset signal
    input wire team1_inc,             // Team 1 increment button
    input wire team1_dec,             // Team 1 decrement button
    input wire team2_inc,             // Team 2 increment button
    input wire team2_dec,             // Team 2 decrement button
    input wire team1_clear,           // Team 1 clear button
    input wire team2_clear,           // Team 2 clear button
    input wire [2:0] inc_adjust,      // Increment adjust (3-bit value)
    output reg [7:0] seg_out1,         // Seven-segment outputs (A-G, DP)
    output reg [7:0] seg_out2,         // Seven-segment outputs (A-G, DP)
    output reg [3:0] team1_control,   // Control for Team 1 digits (3 digits)
    output reg [3:0] team2_control    // Control for Team 2 digits (3 digits)
);

    reg [15:0] score_team1;           // Store Team 1 score (4 digits)
    reg [15:0] score_team2;           // Store Team 2 score (4 digits)
    reg [2:0] current_digit;          // Current digit for multiplexing (0-6)

    // Clock Divider for Multiplexing (slow down for persistence of vision)
    reg [15:0] clk_div;
    wire slow_clk = clk_div[15];  // Slow clock for multiplexing

    always @(posedge clk or posedge reset) begin
        if (reset)
            clk_div <= 0;
        else
            clk_div <= clk_div + 1;
    end

    // Debouncing logic (50ms debounce time)
    reg [15:0] debounce_count;
    reg team1_inc_debounced, team2_inc_debounced;
    reg team1_dec_debounced, team2_dec_debounced;
    reg team1_clear_debounced, team2_clear_debounced;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            debounce_count <= 0;
            team1_inc_debounced <= 0;
            team2_inc_debounced <= 0;
            team1_dec_debounced <= 0;
            team2_dec_debounced <= 0;
            team1_clear_debounced <= 0;
            team2_clear_debounced <= 0;
        end else begin
            if (debounce_count < 16'hFFFF)
                debounce_count <= debounce_count + 1;
            else
                debounce_count <= 0;

            // Debouncing for buttons
            if (debounce_count == 0) begin
                team1_inc_debounced <= team1_inc;
                team2_inc_debounced <= team2_inc;
                team1_dec_debounced <= team1_dec;
                team2_dec_debounced <= team2_dec;
                team1_clear_debounced <= team1_clear;
                team2_clear_debounced <= team2_clear;
            end
        end
    end

    // Register the previous button states for edge detection
    reg team1_inc_prev, team2_inc_prev;
    reg team1_dec_prev, team2_dec_prev;
    reg team1_clear_prev, team2_clear_prev;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            team1_inc_prev <= 0;
            team2_inc_prev <= 0;
            team1_dec_prev <= 0;
            team2_dec_prev <= 0;
            team1_clear_prev <= 0;
            team2_clear_prev <= 0;
        end else begin
            team1_inc_prev <= team1_inc_debounced;
            team2_inc_prev <= team2_inc_debounced;
            team1_dec_prev <= team1_dec_debounced;
            team2_dec_prev <= team2_dec_debounced;
            team1_clear_prev <= team1_clear_debounced;
            team2_clear_prev <= team2_clear_debounced;
        end
    end
  reg [3:0] inc_adjust_value;
    // Handle Reset, Clear, and Increment for Team 1 (with edge detection)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            score_team1 <= 16'b0;
        end else if (team1_clear_debounced && !team1_clear_prev) begin
            // Clear the score when clear button is pressed (on rising edge)
            score_team1 <= 16'b0;
        end else if (team1_inc_debounced && !team1_inc_prev) begin
            // Increment the score when inc button is pressed (on rising edge)
            if (score_team1 + {12'b0, inc_adjust_value} <= 9999)
                score_team1 <= score_team1 + {12'b0, inc_adjust_value};
            else
                score_team1 <= 9999; // Cap at 999
        end else if (team1_dec_debounced && !team1_dec_prev) begin
             // Decrement Team 1 score
             if (score_team1 >= {12'b0, inc_adjust_value})
                 score_team1 <= score_team1 - {12'b0, inc_adjust_value};
             else
                 score_team1 <= 0;  // Prevent negative scores
        end
    end

    // Handle Reset, Clear, and Increment for Team 2 (with edge detection)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            score_team2 <= 16'b0;
        end else if (team2_clear_debounced && !team2_clear_prev) begin
            // Clear the score when clear button is pressed (on rising edge)
            score_team2 <= 16'b0;
        end else if (team2_inc_debounced && !team2_inc_prev) begin
            // Increment the score when inc button is pressed (on rising edge)
            if (score_team2 + {12'b0, inc_adjust_value} <= 9999)
                score_team2 <= score_team2 + {12'b0, inc_adjust_value};
            else
                score_team2 <= 9999; // Cap at 999
        end else if (team2_dec_debounced && !team2_dec_prev) begin
            // Decrement Team 2 score
            if (score_team2 >= {12'b0, inc_adjust_value})
                score_team2 <= score_team2 - {12'b0, inc_adjust_value};
            else
                score_team2 <= 0;  // Prevent negative scores
        end
    end

    // Determine the increment value based on the 3-bit inc_adjust input
  
    always @(*) begin
        case (inc_adjust)
            3'b000: inc_adjust_value = 1;
            3'b001: inc_adjust_value = 2;
            3'b010: inc_adjust_value = 3;
            3'b011: inc_adjust_value = 4;
            3'b100: inc_adjust_value = 5;
            3'b101: inc_adjust_value = 6;
            3'b110: inc_adjust_value = 7;
            3'b111: inc_adjust_value = 8;
            default: inc_adjust_value = 1;
        endcase
    end

    // Multiplexing logic for Team 1 and Team 2 displays
    always @(posedge slow_clk or posedge reset) begin
        if (reset) begin
            current_digit <= 3'b000;
        end else if (current_digit == 3'b111) begin
            current_digit <= 3'b000;  // Wrap around to 000 after reaching 101
        end else begin
            current_digit <= current_digit + 1;
        end
    end

    // Instantiate Binary to BCD conversion for team1 and team2
    wire [3:0] team1_ones, team1_tens, team1_hundreds, team1_thousands;
    wire [3:0] team2_ones, team2_tens, team2_hundreds, team2_thousands;

    bin_to_bcd team1_bcd_converter(
        .bin(score_team1),
        .thousands(team1_thousands),
        .hundreds(team1_hundreds),
        .tens(team1_tens),
        .ones(team1_ones)
    );

    bin_to_bcd team2_bcd_converter(
        .bin(score_team2),
        .thousands(team2_thousands),
        .hundreds(team2_hundreds),
        .tens(team2_tens),
        .ones(team2_ones)
    ); 

    // 7-segment display digit decoder
    function [7:0] seven_seg_decoder(input [3:0] digit);
    begin
        case(digit)
            4'd0: seven_seg_decoder = 8'b00000011; // "0"
            4'd1: seven_seg_decoder = 8'b10011111; // "1"
            4'd2: seven_seg_decoder = 8'b00100101; // "2"
            4'd3: seven_seg_decoder = 8'b00001101; // "3"
            4'd4: seven_seg_decoder = 8'b10011001; // "4"
            4'd5: seven_seg_decoder = 8'b01001001; // "5"
            4'd6: seven_seg_decoder = 8'b01000001; // "6"
            4'd7: seven_seg_decoder = 8'b00011111; // "7"
            4'd8: seven_seg_decoder = 8'b00000001; // "8"
            4'd9: seven_seg_decoder = 8'b00001001; // "9"
            default: seven_seg_decoder = 8'b11111111; // Blank
        endcase
    end
    endfunction

    // Display update based on current digit for multiplexing
    always @(posedge slow_clk or posedge reset) begin
        if (reset) begin
            seg_out1 <= 8'b11111111;   // Turn off all segments
            seg_out2 <= 8'b11111111;   // Turn off all segments
        end else begin
            case (current_digit)
                3'b000: begin
                    // Team 1 Digit 1
                    seg_out1 <= seven_seg_decoder(team1_ones);
                    team1_control <= 4'b1110; // Activate digit 1 for Team 1
                   // team2_control <= 4'b1111;
                end
                3'b001: begin
                    // Team 1 Digit 2
                    seg_out1 <= seven_seg_decoder(team1_tens);
                    team1_control <= 4'b1101; // Activate digit 2 for Team 1
                    //team2_control <= 4'b1111;
                end
                3'b010: begin
                    // Team 1 Digit 3
                    seg_out1 <= seven_seg_decoder(team1_hundreds);
                    team1_control <= 4'b1011; // Activate digit 3 for Team 1
                   // team2_control <= 4'b1111;
                end
                3'b011: begin
                    // Team 1 Digit 3
                    seg_out1 <= seven_seg_decoder(team1_thousands);
                    team1_control <= 4'b0111; // Activate digit 4 for Team 1
                   // team2_control <= 4'b1111;
                end
                3'b100: begin
                    // Team 2 Digit 1
                    seg_out2 <= seven_seg_decoder(team2_ones);
                   // team1_control <= 4'b1111;
                    team2_control <= 4'b1110; // Activate digit 1 for Team 2
                end
                3'b101: begin
                    // Team 2 Digit 2
                    seg_out2 <= seven_seg_decoder(team2_tens);
                   // team1_control <= 4'b1111;
                    team2_control <= 4'b1101; // Activate digit 2 for Team 2
                end
                3'b110: begin
                    // Team 2 Digit 3
                    seg_out2 <= seven_seg_decoder(team2_hundreds);
                 //   team1_control <= 4'b1111;
                    team2_control <= 4'b1011; // Activate digit 3 for Team 2
                end
                 3'b111: begin
                    // Team 2 Digit 3
                    seg_out2 <= seven_seg_decoder(team2_thousands);
                 //   team1_control <= 4'b1111;
                    team2_control <= 4'b0111; // Activate digit 4 for Team 2
                end               
 
          //      default: begin
              //      seg_out <= 8'b11111111;   // Turn off all segments
               //     team1_control <= 3'b111;
                //    team2_control <= 3'b111;
               // end
            endcase
        end
    end
endmodule

// Binary to BCD converter module for 12-bit input (used for both teams)
module bin_to_bcd (
    input [15:0] bin,
    output reg [3:0] thousands,
    output reg [3:0] hundreds,
    output reg [3:0] tens,
    output reg [3:0] ones
);

    integer i;
    always @(*) begin
        // Reset BCD digits
         thousands = 4'd0;
        hundreds = 4'd0;
        tens = 4'd0;
        ones = 4'd0;
        
        // Conversion algorithm
        for (i = 15; i >= 0; i = i - 1) begin
             if (thousands >= 5)
                thousands = thousands + 3;
            if (hundreds >= 5)
                hundreds = hundreds + 3;
            if (tens >= 5)
                tens = tens + 3;
            if (ones >= 5)
                ones = ones + 3;
            
            // Shift left by 1
            thousands = thousands << 1;
            thousands[0] = hundreds[3];
            hundreds = hundreds << 1;
            hundreds[0] = tens[3];
            tens = tens << 1;
            tens[0] = ones[3];
            ones = ones << 1;
            ones[0] = bin[i];
        end
    end
endmodule
