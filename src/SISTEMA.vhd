LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY sistema IS
    PORT (
        clk, key_0, key_1 : IN STD_LOGIC;
        pulsadores1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        dip : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        leds : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END ENTITY;
ARCHITECTURE sistema_arq OF sistema IS

    COMPONENT clock_divider IS
        PORT (
            clk_in : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            clk_out_1KHz : OUT STD_LOGIC;
            clk_out_10Hz : OUT STD_LOGIC;
            clk_out_1Hz : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL clk_div_1KHz : STD_LOGIC := '0';
    SIGNAL clk_div_10Hz : STD_LOGIC := '0';
    SIGNAL clk_div_1Hz : STD_LOGIC := '0';

    COMPONENT profile_memory IS
        PORT (
            clk : IN STD_LOGIC;
            write_en : IN STD_LOGIC;
            sel_prof : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            rs_pos_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            bn_pos_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);

            rs_pos_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            bn_pos_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL mem_rs_pos_in : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL mem_bn_pos_in : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL mem_rs_pos_out : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL mem_bn_pos_out : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    COMPONENT selector_perfiles IS
        PORT (
            clk : IN STD_LOGIC;
            select_mem : IN STD_LOGIC;
            mem_pos : IN STD_LOGIC;
            pos_m1 : IN STD_LOGIC;
            pos_m2 : IN STD_LOGIC;

            selected_prof : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            load_prof : OUT STD_LOGIC;
            write_prof : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL inv_key_0 : STD_LOGIC := NOT key_0;
    SIGNAL inv_key_1 : STD_LOGIC := NOT key_1;
    SIGNAL sel_selected_prof : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    SIGNAL sel_load_prof : STD_LOGIC := '0';
    SIGNAL sel_write_prof : STD_LOGIC := '0';

    COMPONENT motor_control IS
        PORT (
            clk : IN STD_LOGIC;
            frwd_btn : IN STD_LOGIC;
            bckw_btn : IN STD_LOGIC;

            frwd_out : OUT STD_LOGIC;
            bckw_out : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL mc_rs_frwd_in : STD_LOGIC := '0';
    SIGNAL mc_rs_bckw_in : STD_LOGIC := '0';
    SIGNAL mc_bn_frwd_in : STD_LOGIC := '0';
    SIGNAL mc_bn_bckw_in : STD_LOGIC := '0';

    SIGNAL mc_rs_imp : STD_LOGIC := '0';
    SIGNAL mc_bn_imp : STD_LOGIC := '0';

    SIGNAL mc_rs_frwd_out : STD_LOGIC := '0';
    SIGNAL mc_rs_bckw_out : STD_LOGIC := '0';
    SIGNAL mc_bn_frwd_out : STD_LOGIC := '0';
    SIGNAL mc_bn_bckw_out : STD_LOGIC := '0';

    -- Señales generales

    -- posición y movimiento
    SIGNAL curr_rs_pos : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL curr_bn_pos : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    SIGNAL desired_rs_pos : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL desired_bn_pos : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL desired_rs_reached : STD_LOGIC := '0';
    SIGNAL desired_bn_reached : STD_LOGIC := '0';

    SIGNAL loading_rs : STD_LOGIC := '0';
    SIGNAL loading_bn : STD_LOGIC := '0';

    SIGNAL should_move_rs_frwd : STD_LOGIC := '0';
    SIGNAL should_move_rs_bckw : STD_LOGIC := '0';
    SIGNAL should_move_bn_frwd : STD_LOGIC := '0';
    SIGNAL should_move_bn_bckw : STD_LOGIC := '0';

    SIGNAL prev_rs_imp_val : STD_LOGIC := '0';
    SIGNAL prev_bn_imp_val : STD_LOGIC := '0';

    -- limites
    SIGNAL limit_switch_rs : STD_LOGIC := '0';
    CONSTANT hard_limit_rs_bottom : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000";
    SIGNAL hard_limit_rs_bottom_reached : STD_LOGIC := '0';
    CONSTANT soft_limit_rs_top : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00001111"; -- 15
    CONSTANT soft_limit_rs_bottom : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000001";
    SIGNAL soft_limit_rs_top_reached : STD_LOGIC := '0';
    SIGNAL soft_limit_rs_bottom_reached : STD_LOGIC := '0';

    SIGNAL limit_switch_bn : STD_LOGIC := '0';
    CONSTANT hard_limit_bn_bottom : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000";
    SIGNAL hard_limit_bn_bottom_reached : STD_LOGIC := '0';
    CONSTANT soft_limit_bn_top : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00001111"; -- 15
    CONSTANT soft_limit_bn_bottom : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000001";
    SIGNAL soft_limit_bn_top_reached : STD_LOGIC := '0';
    SIGNAL soft_limit_bn_bottom_reached : STD_LOGIC := '0';

    SIGNAL soft_limit_led : STD_LOGIC := '0';

    -- calibración
    TYPE CALIBRATION_STATE IS (IDLE, HARD_LIMIT, SOFT_LIMIT);
    SIGNAL calibration_state_rs : CALIBRATION_STATE := IDLE;
    SIGNAL calibration_state_bn : CALIBRATION_STATE := IDLE;

    SIGNAL request_calibration : STD_LOGIC := '0';
    SIGNAL calibrating_led : STD_LOGIC := '0';

BEGIN

    CLK_DIV_COMP : clock_divider PORT MAP(
        clk_in => clk,
        enable => '1',
        clk_out_1KHz => clk_div_1KHz,
        clk_out_10Hz => clk_div_10Hz,
        clk_out_1Hz => clk_div_1Hz
    );

    PROF_SEL : selector_perfiles PORT MAP(
        clk => clk_div_1KHz,
        select_mem => inv_key_1,
        mem_pos => inv_key_0,
        pos_m1 => dip(1),
        pos_m2 => dip(2),

        selected_prof => sel_selected_prof,
        load_prof => sel_load_prof,
        write_prof => sel_write_prof
    );

    PROF_MEM : profile_memory PORT MAP(
        clk => clk_div_1KHz,
        write_en => sel_write_prof,
        sel_prof => sel_selected_prof,

        rs_pos_in => mem_rs_pos_in,
        bn_pos_in => mem_bn_pos_in,
        rs_pos_out => mem_rs_pos_out,
        bn_pos_out => mem_bn_pos_out
    );

    MOTOR_CTRL_RS : motor_control PORT MAP(
        clk => clk_div_1KHz,
        frwd_btn => mc_rs_frwd_in,
        bckw_btn => mc_rs_bckw_in,

        frwd_out => mc_rs_frwd_out,
        bckw_out => mc_rs_bckw_out
    );

    MOTOR_CTRL_BN : motor_control PORT MAP(
        clk => clk_div_1KHz,
        frwd_btn => mc_bn_frwd_in,
        bckw_btn => mc_bn_bckw_in,

        frwd_out => mc_bn_frwd_out,
        bckw_out => mc_bn_bckw_out
    );

    -- Asignación pulsadores y leds
    request_calibration <= dip(0);

    mc_rs_frwd_in <= pulsadores1(3);
    mc_rs_bckw_in <= pulsadores1(2);
    mc_rs_imp <= pulsadores1(1);
    limit_switch_rs <= pulsadores1(0);

    mc_bn_frwd_in <= pulsadores1(7);
    mc_bn_bckw_in <= pulsadores1(6);
    mc_bn_imp <= pulsadores1(5);
    limit_switch_bn <= pulsadores1(4);

    leds(0) <= sel_selected_prof(0);
    leds(1) <= sel_selected_prof(1);

    leds(2) <= calibrating_led;

    leds(3) <= soft_limit_led;

    leds(6) <= mc_rs_frwd_out OR should_move_rs_frwd;
    leds(7) <= mc_rs_bckw_out OR should_move_rs_bckw;

    leds(4) <= mc_bn_frwd_out OR should_move_bn_frwd;
    leds(5) <= mc_bn_bckw_out OR should_move_bn_bckw;

    POS_CTRL : PROCESS (clk_div_1KHz)
        VARIABLE new_rs_pos : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
        VARIABLE new_bn_pos : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    BEGIN
        IF rising_edge(clk_div_1KHz) THEN
            IF desired_rs_reached = '1' THEN
                loading_rs <= '0';
            END IF;
            IF desired_bn_reached = '1' THEN
                loading_bn <= '0';
            END IF;

            IF calibration_state_rs = IDLE AND calibration_state_bn = IDLE THEN
                IF sel_load_prof = '1' THEN
                    new_rs_pos := mem_rs_pos_out;
                    new_bn_pos := mem_bn_pos_out;

                    IF new_rs_pos /= curr_rs_pos THEN
                        desired_rs_pos <= new_rs_pos;
                        loading_rs <= '1';
                    END IF;

                    IF new_bn_pos /= curr_bn_pos THEN
                        desired_bn_pos <= new_bn_pos;
                        loading_bn <= '1';
                    END IF;
                ELSIF sel_write_prof = '1' THEN
                    mem_rs_pos_in <= curr_rs_pos;
                    mem_bn_pos_in <= curr_bn_pos;
                END IF;
            ELSE
                -- calibración
                IF calibration_state_rs = HARD_LIMIT THEN
                    new_rs_pos := hard_limit_rs_bottom;
                ELSIF calibration_state_rs = SOFT_LIMIT THEN
                    new_rs_pos := soft_limit_rs_bottom;
                END IF;

                IF calibration_state_bn = HARD_LIMIT THEN
                    new_bn_pos := hard_limit_bn_bottom;
                ELSIF calibration_state_bn = SOFT_LIMIT THEN
                    new_bn_pos := soft_limit_bn_bottom;
                END IF;

                IF new_rs_pos /= curr_rs_pos THEN
                    desired_rs_pos <= new_rs_pos;
                    loading_rs <= '1';
                END IF;

                IF new_bn_pos /= curr_bn_pos THEN
                    desired_bn_pos <= new_bn_pos;
                    loading_bn <= '1';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    CALIBRATION_STATE_CTRL : PROCESS (clk_div_1KHz)
    BEGIN
        -- empezamos en idle
        -- si se solicita calibración, pasamos a hard limit
        -- una vez rs y bn están en hard limit, pasamos a soft limit
        -- una vez rs y bn están en soft limit, volvemos a idle

        IF rising_edge(clk_div_1KHz) THEN
            IF request_calibration = '1' THEN
                calibration_state_rs <= HARD_LIMIT;
                calibration_state_bn <= HARD_LIMIT;
            END IF;

            IF calibration_state_rs = HARD_LIMIT THEN
                IF hard_limit_rs_bottom_reached = '1' THEN
                    calibration_state_rs <= SOFT_LIMIT;
                END IF;
            ELSIF calibration_state_rs = SOFT_LIMIT THEN
                IF soft_limit_rs_bottom_reached = '1' THEN
                    calibration_state_rs <= IDLE;
                END IF;
            END IF;

            IF calibration_state_bn = HARD_LIMIT THEN
                IF hard_limit_bn_bottom_reached = '1' THEN
                    calibration_state_bn <= SOFT_LIMIT;
                END IF;
            ELSIF calibration_state_bn = SOFT_LIMIT THEN
                IF soft_limit_bn_bottom_reached = '1' THEN
                    calibration_state_bn <= IDLE;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    CALIBRATION_LED_CTRL : PROCESS (clk_div_1Hz)
    BEGIN
        IF rising_edge(clk_div_1Hz) THEN
            IF calibration_state_rs /= IDLE OR calibration_state_bn /= IDLE THEN
                calibrating_led <= NOT calibrating_led;
            ELSE
                calibrating_led <= '0';
            END IF;
        END IF;
    END PROCESS;

    RS_LED_CTRL : PROCESS (desired_rs_pos, curr_rs_pos, loading_rs)
    BEGIN
        IF loading_rs = '1' THEN
            IF desired_rs_pos > curr_rs_pos THEN
                should_move_rs_bckw <= '0';
                should_move_rs_frwd <= '1';
            ELSIF desired_rs_pos < curr_rs_pos THEN
                should_move_rs_frwd <= '0';
                should_move_rs_bckw <= '1';
            END IF;
        ELSE
            should_move_rs_frwd <= '0';
            should_move_rs_bckw <= '0';
        END IF;
    END PROCESS;

    BN_LED_CTRL : PROCESS (desired_bn_pos, curr_bn_pos, loading_bn)
    BEGIN
        IF loading_bn = '1' THEN
            IF desired_bn_pos > curr_bn_pos THEN
                should_move_bn_bckw <= '0';
                should_move_bn_frwd <= '1';
            ELSIF desired_bn_pos < curr_bn_pos THEN
                should_move_bn_frwd <= '0';
                should_move_bn_bckw <= '1';
            END IF;
        ELSE
            should_move_bn_frwd <= '0';
            should_move_bn_bckw <= '0';
        END IF;
    END PROCESS;

    DESIRED_RS_POS_RESET : PROCESS (curr_rs_pos, desired_rs_pos, loading_rs)
    BEGIN
        IF loading_rs = '0' THEN
            desired_rs_reached <= '0';
        ELSIF curr_rs_pos = desired_rs_pos THEN
            desired_rs_reached <= '1';
        END IF;
    END PROCESS;

    DESIRED_BN_POS_RESET : PROCESS (curr_bn_pos, desired_bn_pos, loading_bn)
    BEGIN
        IF loading_bn = '0' THEN
            desired_bn_reached <= '0';
        ELSIF curr_bn_pos = desired_bn_pos THEN
            desired_bn_reached <= '1';
        END IF;
    END PROCESS;

    RS_MOV_CTRL : PROCESS (clk_div_1KHz)
    BEGIN
        IF rising_edge(clk_div_1KHz) THEN
            IF limit_switch_rs = '1' THEN
                curr_rs_pos <= hard_limit_rs_bottom;
            ELSIF (desired_rs_pos > curr_rs_pos) OR mc_rs_frwd_out = '1' THEN
                IF soft_limit_rs_top_reached = '1' THEN
                    -- No permitir que el motor avance más allá del límite superior
                ELSIF mc_rs_imp = '1' AND prev_rs_imp_val = '0' THEN
                    curr_rs_pos <= curr_rs_pos + 1;
                END IF;
            ELSIF (desired_rs_pos < curr_rs_pos) OR mc_rs_bckw_out = '1' THEN
                IF soft_limit_rs_bottom_reached = '1' OR
                    hard_limit_rs_bottom_reached = '1' THEN
                    -- No permitir que el motor avance más allá del límite inferior
                ELSIF mc_rs_imp = '1' AND prev_rs_imp_val = '0' THEN
                    curr_rs_pos <= curr_rs_pos - 1;
                END IF;
            END IF;
            prev_rs_imp_val <= mc_rs_imp;
        END IF;
    END PROCESS;

    BN_MOV_CTRL : PROCESS (clk_div_1KHz)
    BEGIN
        IF rising_edge(clk_div_1KHz) THEN
            IF limit_switch_bn = '1' THEN
                curr_bn_pos <= hard_limit_bn_bottom;
            ELSIF (desired_bn_pos > curr_bn_pos) OR mc_bn_frwd_out = '1' THEN
                IF soft_limit_bn_top_reached = '1' THEN
                    -- No permitir que el motor avance más allá del límite superior 
                ELSIF mc_bn_imp = '1' AND prev_bn_imp_val = '0' THEN
                    curr_bn_pos <= curr_bn_pos + 1;
                END IF;
            ELSIF (desired_bn_pos < curr_bn_pos) OR mc_bn_bckw_out = '1' THEN
                IF soft_limit_bn_bottom_reached = '1' OR
                    hard_limit_bn_bottom_reached = '1' THEN
                    -- No permitir que el motor avance más allá del límite inferior
                ELSIF mc_bn_imp = '1' AND prev_bn_imp_val = '0' THEN
                    curr_bn_pos <= curr_bn_pos - 1;
                END IF;
            END IF;
            prev_bn_imp_val <= mc_bn_imp;
        END IF;
    END PROCESS;

    -- TODO: revisar si es posible tener 2 señales de reloj en el mismo process
    -- 1Hz para el led que parpadea y 1KHz para el resto
    LIM_LED_CTRL : PROCESS (clk_div_10Hz)
    BEGIN
        IF rising_edge(clk_div_10Hz) THEN
            -- Parpadea si estamos en el final de carrera
            -- Luz sólida si estamos en algún límite por software
            IF hard_limit_rs_bottom_reached = '1' OR
                hard_limit_bn_bottom_reached = '1' THEN
                soft_limit_led <= NOT soft_limit_led;
            ELSIF soft_limit_rs_top_reached = '1' OR
                soft_limit_rs_bottom_reached = '1' OR
                soft_limit_bn_top_reached = '1' OR
                soft_limit_bn_bottom_reached = '1' THEN
                soft_limit_led <= '1';
            ELSE
                soft_limit_led <= '0';
            END IF;
        END IF;
    END PROCESS;

    LIM_RS_CTRL : PROCESS (curr_rs_pos)
    BEGIN
        IF curr_rs_pos = hard_limit_rs_bottom THEN
            hard_limit_rs_bottom_reached <= '1';
        ELSE
            hard_limit_rs_bottom_reached <= '0';
        END IF;

        IF curr_rs_pos = soft_limit_rs_top THEN
            soft_limit_rs_top_reached <= '1';
        ELSE
            soft_limit_rs_top_reached <= '0';
        END IF;

        IF curr_rs_pos = soft_limit_rs_bottom THEN
            soft_limit_rs_bottom_reached <= '1';
        ELSE
            soft_limit_rs_bottom_reached <= '0';
        END IF;
    END PROCESS;

    LIM_BN_CTRL : PROCESS (curr_bn_pos)
    BEGIN
        IF curr_bn_pos = hard_limit_bn_bottom THEN
            hard_limit_bn_bottom_reached <= '1';
        ELSE
            hard_limit_bn_bottom_reached <= '0';
        END IF;

        IF curr_bn_pos = soft_limit_bn_top THEN
            soft_limit_bn_top_reached <= '1';
        ELSE
            soft_limit_bn_top_reached <= '0';
        END IF;

        IF curr_bn_pos = soft_limit_bn_bottom THEN
            soft_limit_bn_bottom_reached <= '1';
        ELSE
            soft_limit_bn_bottom_reached <= '0';
        END IF;
    END PROCESS;

END ARCHITECTURE sistema_arq;
