LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY profile_memory IS
    PORT (
        CLK : IN STD_LOGIC;
        WRITE_EN : IN STD_LOGIC;
        SEL_PROF : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        RS_POS_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        BN_POS_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);

        RS_POS_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        BN_POS_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END ENTITY profile_memory;

ARCHITECTURE mem_arch OF profile_memory IS
    SIGNAL P1_RS_POS : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL P1_BN_POS : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL P2_RS_POS : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL P2_BN_POS : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
BEGIN
    MEM_CTRL : PROCESS (CLK)
    BEGIN
        IF rising_edge(CLK) THEN
            CASE SEL_PROF IS
                WHEN "01" =>
                    IF WRITE_EN = '1' THEN
                        P1_RS_POS <= RS_POS_IN;
                        P1_BN_POS <= BN_POS_IN;
                    ELSE
                        RS_POS_OUT <= P1_RS_POS;
                        BN_POS_OUT <= P1_BN_POS;
                    END IF;
                WHEN "10" =>
                    IF WRITE_EN = '1' THEN
                        P2_RS_POS <= RS_POS_IN;
                        P2_BN_POS <= BN_POS_IN;
                    ELSE
                        RS_POS_OUT <= P2_RS_POS;
                        BN_POS_OUT <= P2_BN_POS;
                    END IF;
                WHEN OTHERS =>
                    NULL;
            END CASE;
        END IF;
    END PROCESS;
END ARCHITECTURE mem_arch;
