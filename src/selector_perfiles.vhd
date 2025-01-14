LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY selector_perfiles IS
    PORT (
        CLK : IN STD_LOGIC;
        SELECT_MEM : IN STD_LOGIC;
        MEM_POS : IN STD_LOGIC;
        POS_M1 : IN STD_LOGIC;
        POS_M2 : IN STD_LOGIC;

        SELECTED_PROF : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        LOAD_PROF : OUT STD_LOGIC;
        WRITE_PROF : OUT STD_LOGIC
    );
END ENTITY selector_perfiles;

ARCHITECTURE selector_arch OF selector_perfiles IS
    TYPE PROFILE IS (NONE, M1, M2);
    SIGNAL current_profile : PROFILE := NONE;
    SIGNAL profile_output : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";

    SIGNAL load_signal : STD_LOGIC := '0';
    SIGNAL write_signal : STD_LOGIC := '0';
    SIGNAL prev_select_mem : STD_LOGIC := '0';
BEGIN
    P_BTN_CTRL : PROCESS (CLK)
    BEGIN
        IF rising_edge(CLK) THEN
            IF SELECT_MEM = '1' AND prev_select_mem = '0' THEN
                CASE current_profile IS
                    WHEN NONE =>
                        current_profile <= M1;
                    WHEN M1 =>
                        current_profile <= M2;
                    WHEN M2 =>
                        current_profile <= NONE;
                END CASE;
            END IF;

            prev_select_mem <= SELECT_MEM;
        END IF;
    END PROCESS;

    STATUS_CTRL : PROCESS (current_profile)
    BEGIN
        CASE current_profile IS
            WHEN NONE =>
                profile_output <= "00";
            WHEN M1 =>
                profile_output <= "01";
            WHEN M2 =>
                profile_output <= "10";
        END CASE;
    END PROCESS;

    M_P1_P2_BTN_CTRL : PROCESS (CLK)
    BEGIN
        IF rising_edge(CLK) THEN
            IF MEM_POS = '1' THEN
                load_signal <= '0';
                write_signal <= '1';
            ELSIF (POS_M1 = '1' AND current_profile = M1) OR
                  (POS_M2 = '1' AND current_profile = M2) THEN
                write_signal <= '0';
                load_signal <= '1';
            ELSE
                write_signal <= '0';
                load_signal <= '0';
            END IF;
        END IF;
    END PROCESS;

    SELECTED_PROF <= profile_output;
    LOAD_PROF <= load_signal;
    WRITE_PROF <= write_signal;

END ARCHITECTURE selector_arch;
