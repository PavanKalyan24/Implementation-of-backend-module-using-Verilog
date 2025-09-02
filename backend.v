
/* backend module:
 * Takes care of startup sequence and monitors  the mixed-signal IC
 * Submitted by: Pavan kalyan Reddy (241040052), Vishnu V Saseendran (241040098)
 * Group name  :gate keepers   
*/
module backend (
    // // Inputs coming into our module
    input i_resetbAll,          // Active low reset for the whole chip
    input i_clk,               // Main clock (500 MHz)
    input i_sclk,              // Serial clock for communication
    input i_sdin,              // Serial data input
    input i_RO_clk,            // Ring oscillator clock input
    input [3:0] i_ADCout,      // 4-bit ADC output from temperature sensor
    
    // Outputs  
    output reg o_Ibias_2x,     // Bias current control (2x when 1)
    output reg o_core_clk,     // Core clock output (i_clk or i_clk/4)
    output reg o_ready,        // Indicates startup sequence complete
    output reg o_resetb_amp,   // Active low reset for opamp
    output reg [2:0] o_gain,   // 3-bit gain control for opamp
    output reg o_enableRO,     // Enable signal for ring oscillator
    output reg o_resetb_core   // Active low reset for core logic
);

//============================================================================
// State Parameter declarations , to keep track of current states 
parameter sRESET    = 0;    // Reset state
parameter sWAIT_SER = 1;    // Wait for serial data
parameter sSET_GAIN = 2;    // Set gain value
parameter sEN_RO    = 3;    // Enable ring oscillator
parameter sWAIT1    = 4;    // Wait 5 cycles
parameter sFILTER   = 5;    // Process ADC filter
parameter sSET_RES  = 6;    // Set reset signals
parameter sWAIT2    = 7;    // Wait 5 cycles
parameter sREADY    = 8;    // Ready state

//============================================================================
// Internal registers and wires
reg [3:0] state;           // Current state
reg [3:0] next_state;      // Next state
reg [2:0] wait_count;      // Counter for wait states
reg [4:0] shift_reg;       // Shift register for serial data
reg [2:0] sclk_count;      // Counter for serial clock cycles
reg [3:0] filter_reg [0:3]; // 4-tap filter registers
reg [5:0] filter_sum;      // Sum for filter (4-bit input + 2 bits for 4 additions)
reg [3:0] ADCavg;          // Filtered ADC average
reg clk_div2, clk_div4;    // Clock dividers for i_clk/4

//============================================================================
//  State machine based  combinatinal logic for next state
always @(*) begin
    case(state)
        sRESET:    next_state = i_resetbAll ? sWAIT_SER : sRESET;
        sWAIT_SER: next_state = (sclk_count == 5) ? sSET_GAIN : sWAIT_SER;
        sSET_GAIN: next_state = sEN_RO;
        sEN_RO:    next_state = sWAIT1;
        sWAIT1:    next_state = (wait_count == 5) ? sFILTER : sWAIT1;
        sFILTER:   next_state = sSET_RES;
        sSET_RES:  next_state = sWAIT2;
        sWAIT2:    next_state = (wait_count == 5) ? sREADY : sWAIT2;
        sREADY:    next_state = i_resetbAll ? sREADY : sRESET;
        default:   next_state = sRESET;
    endcase
end

//============================================================================
// State machine based Sequential logic
always @(posedge i_clk or negedge i_resetbAll) begin
    if (!i_resetbAll)
        state <= sRESET;
    else
        state <= next_state;
end

//============================================================================
// Grabbing serial data into a shift register 
always @(posedge i_sclk or negedge i_resetbAll) begin
    if (!i_resetbAll) begin
        shift_reg <= 5'b0;
        sclk_count <= 3'b0;
    end
    else if (state == sWAIT_SER) begin
        shift_reg <= {shift_reg[3:0], i_sdin};
        sclk_count <= sclk_count + 1;
    end
end

//============================================================================
//  counter for waiting 
always @(posedge i_clk or negedge i_resetbAll) begin
    if (!i_resetbAll)
        wait_count <= 0;
    else if (state == sWAIT1 || state == sWAIT2)
        wait_count <= wait_count + 1;
    else
        wait_count <= 0;
end

//============================================================================
// Moving average filter - smooths out the noise on ADC
always @(posedge i_clk or negedge i_resetbAll) begin
    if (!i_resetbAll) begin
        filter_reg[0] <= 0;
        filter_reg[1] <= 0;
        filter_reg[2] <= 0;
        filter_reg[3] <= 0;
        filter_sum <= 0;
        ADCavg <= 0;
    end
    else begin
        // Shift in the new sample
        filter_reg[3] <= filter_reg[2];
        filter_reg[2] <= filter_reg[1];
        filter_reg[1] <= filter_reg[0];
        filter_reg[0] <= i_ADCout;
        
        // Calculate moving average
        filter_sum <= filter_reg[0] + filter_reg[1] + filter_reg[2] + filter_reg[3];
        ADCavg <= filter_sum[5:2]; // Divide by 4 (right shift by 2)
    end
end

//============================================================================
// Clock divider for i_clk/4
// First cut frequency in half
always @(posedge i_clk or negedge i_resetbAll) begin
    if (!i_resetbAll)
        clk_div2 <= 0;
    else
        clk_div2 <= ~clk_div2;
end

// Then cut it in half again - 1/4 frequency
always @(posedge clk_div2 or negedge i_resetbAll) begin
    if (!i_resetbAll)
        clk_div4 <= 0;
    else
        clk_div4 <= ~clk_div4;
end

//============================================================================
// Output control
always @(posedge i_clk or negedge i_resetbAll) begin
    if (!i_resetbAll) begin
        o_Ibias_2x <= 0;
        o_core_clk <= 0;
        o_ready <= 0;
        o_resetb_amp <= 0;
        o_gain <= 0;
        o_enableRO <= 0;
        o_resetb_core <= 0;
    end
    else begin
        case(state)
            sRESET: begin
                o_Ibias_2x <= 0;
                o_core_clk <= 0;
                o_ready <= 0;
                o_resetb_amp <= 0;
                o_gain <= 0;
                o_enableRO <= 0;
                o_resetb_core <= 0;
            end
            sSET_GAIN:
                o_gain <= {shift_reg[2], shift_reg[3], shift_reg[4]};
            sEN_RO:
                o_enableRO <= 1;
            sFILTER: begin
                if (ADCavg <= 12) begin
                    o_Ibias_2x <= 0;
                    o_core_clk <= i_clk;
                end
                else begin
                    o_Ibias_2x <= 1;
                    o_core_clk <= clk_div4;
                end
            end
            sSET_RES: begin
                o_resetb_amp <= 1;
                o_resetb_core <= 1;
            end
            sREADY: begin
                o_ready <= 1;
                //    monitoring temp even after startup
                if (ADCavg > 12) begin
                    o_Ibias_2x <= 1;
                    o_core_clk <= clk_div4;
                end
                else if (ADCavg < 8) begin
                    o_Ibias_2x <= 0;
                    o_core_clk <= i_clk;
                end
            end
        endcase
    end
end

//============================================================================
endmodule