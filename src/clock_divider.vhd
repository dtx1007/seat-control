LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY clock_divider IS
    PORT (
        clk_in : IN STD_LOGIC;
        enable : IN STD_LOGIC;
        clk_out_1KHz : OUT STD_LOGIC;
        clk_out_10Hz : OUT STD_LOGIC;
        clk_out_1Hz : OUT STD_LOGIC
    );
END ENTITY clock_divider;

ARCHITECTURE behavior OF clock_divider IS
    SIGNAL counter_1KHz : INTEGER := 0;
    SIGNAL counter_10Hz : INTEGER := 0;
    SIGNAL counter_1Hz : INTEGER := 0;

    SIGNAL clk_div_1KHz : STD_LOGIC := '0';
    SIGNAL clk_div_10Hz : STD_LOGIC := '0';
    SIGNAL clk_div_1Hz : STD_LOGIC := '0';

    CONSTANT DIV_1KHZ : INTEGER := 25000 - 1; -- 50 MHz / 1 kHz / 2 = 25000 iters
    CONSTANT DIV_10HZ : INTEGER := 2500000 - 1; -- 50 MHz / 10 Hz / 2 = 2500000 iters
    CONSTANT DIV_1HZ : INTEGER := 25000000 - 1; -- 50 MHz / 1 Hz / 2 = 25000000 iters
BEGIN
    PROCESS (clk_in)
    BEGIN
        IF rising_edge(clk_in) AND enable = '1' THEN
            -- 1 KHz (1ms)
            IF counter_1KHz = DIV_1KHZ THEN
                counter_1KHz <= 0;
                clk_div_1KHz <= NOT clk_div_1KHz;
            ELSE
                counter_1KHz <= counter_1KHz + 1;
            END IF;

            -- 10 Hz (100ms)
            IF counter_10Hz = DIV_10HZ THEN
                counter_10Hz <= 0;
                clk_div_10Hz <= NOT clk_div_10Hz;
            ELSE
                counter_10Hz <= counter_10Hz + 1;
            END IF;

            -- 1 Hz (1s)
            IF counter_1Hz = DIV_1HZ THEN
                counter_1Hz <= 0;
                clk_div_1Hz <= NOT clk_div_1Hz;
            ELSE
                counter_1Hz <= counter_1Hz + 1;
            END IF;
        END IF;
    END PROCESS;

    clk_out_1KHz <= clk_div_1KHz;
    clk_out_10Hz <= clk_div_10Hz;
    clk_out_1Hz <= clk_div_1Hz;

END ARCHITECTURE behavior;
