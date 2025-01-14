LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY motor_control IS
    PORT (
        CLK : IN STD_LOGIC;
        FRWD_BTN : IN STD_LOGIC;
        BCKW_BTN : IN STD_LOGIC;

        FRWD_OUT : OUT STD_LOGIC;
        BCKW_OUT : OUT STD_LOGIC
    );
END ENTITY motor_control;

ARCHITECTURE motor_control_arch OF motor_control IS
BEGIN
    MOTOR_CTRL : PROCESS (CLK)
    BEGIN
        IF rising_edge(CLK) THEN
            IF FRWD_BTN = '1' THEN
                FRWD_OUT <= '1';
                BCKW_OUT <= '0';
            ELSIF BCKW_BTN = '1' THEN
                FRWD_OUT <= '0';
                BCKW_OUT <= '1';
            ELSE
                FRWD_OUT <= '0';
                BCKW_OUT <= '0';
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE motor_control_arch;
