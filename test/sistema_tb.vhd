LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY sistema_tb IS
END ENTITY sistema_tb;

ARCHITECTURE test OF sistema_tb IS
    COMPONENT sistema_sin_clk_div IS
        PORT (
            clk, key_0, key_1 : IN STD_LOGIC;
            pulsadores1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            dip : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            leds : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL clk, key_0, key_1 : STD_LOGIC;
    SIGNAL pulsadores1 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL dip : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL leds : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN
    SYS : sistema_sin_clk_div PORT MAP(
        clk => clk,
        key_0 => key_0,
        key_1 => key_1,
        pulsadores1 => pulsadores1,
        dip => dip,
        leds => leds
    );

    -- Asignación pulsadores y leds

    -- request_calibration <= dip(0);

    -- mc_rs_frwd_in <= pulsadores1(3);
    -- mc_rs_bckw_in <= pulsadores1(2);
    -- mc_rs_imp <= pulsadores1(1);
    -- limit_switch_rs <= pulsadores1(0);

    -- mc_bn_frwd_in <= pulsadores1(7);
    -- mc_bn_bckw_in <= pulsadores1(6);
    -- mc_bn_imp <= pulsadores1(5);
    -- limit_switch_bn <= pulsadores1(4);

    -- leds(0) <= sel_selected_prof(0);
    -- leds(1) <= sel_selected_prof(1);

    -- leds(2) <= calibrating_led;

    -- leds(3) <= soft_limit_led;

    -- leds(6) <= mc_rs_frwd_out OR should_move_rs_frwd;
    -- leds(7) <= mc_rs_bckw_out OR should_move_rs_bckw;

    -- leds(4) <= mc_bn_frwd_out OR should_move_bn_frwd;
    -- leds(5) <= mc_bn_bckw_out OR should_move_bn_bckw;

    CLK_GEN : PROCESS
    BEGIN
        IF now < 100 ns THEN
            clk <= '0';
            WAIT FOR 0.5 ns;
            clk <= '1';
            WAIT FOR 0.5 ns;
        ELSE
            WAIT;
        END IF;
    END PROCESS;

    TEST : PROCESS
    BEGIN
        -- init
        key_0 <= '0';
        key_1 <= '0';
        pulsadores1 <= (OTHERS => '0');
        dip <= (OTHERS => '0');

        -- Subir a la posición inicial
        pulsadores1(3) <= '1'; -- subir rs
        pulsadores1(7) <= '1'; -- subir bn
        WAIT FOR 1 ns;

        pulsadores1(1) <= '1'; -- dar impulso rs
        pulsadores1(5) <= '1'; -- dar impulso bn
        WAIT FOR 1 ns;

        pulsadores1(1) <= '0';
        pulsadores1(5) <= '0';
        WAIT FOR 1 ns;

        pulsadores1(3) <= '0';
        pulsadores1(7) <= '0';
        WAIT FOR 3 ns;

        -- Probar calibración
        dip(0) <= '1'; -- pedir calibración
        WAIT FOR 1 ns;
        dip(0) <= '0';
        WAIT FOR 3 ns;

        ASSERT leds(2) = '1' REPORT "No se activa el led de calibración tras pedir la calibración." SEVERITY failure;

        ASSERT leds(7) = '1' REPORT "No se manda la orden de bajar el respaldo a pesar de estar calibrando." SEVERITY failure;

        ASSERT leds(5) = '1' REPORT "No se manda la orden de bajar la banqueta a pesar de estar calibrando." SEVERITY failure;

        pulsadores1(0) <= '1'; -- activar final de carrera rs
        pulsadores1(4) <= '1'; -- activar final de carrera bn
        WAIT FOR 1 ns;
        pulsadores1(0) <= '0';
        pulsadores1(4) <= '0';
        WAIT FOR 3 ns;

        ASSERT leds(2) = '1' REPORT "No se activa el led de calibración tras pedir la calibración." SEVERITY failure;

        ASSERT leds(7) = '0' REPORT "No se desactiva la orden de bajar el respaldo tras llegar al final de carrera durante la calibración." SEVERITY failure;

        ASSERT leds(5) = '0' REPORT "No se desactiva la orden de bajar la banqueta tras llegar al final de carrera durante la calibración." SEVERITY failure;

        ASSERT leds(6) = '1' REPORT "No se manda la orden de subir el respaldo a pesar de estar calibrando." SEVERITY failure;

        ASSERT leds(4) = '1' REPORT "No se manda la orden de subir la banqueta a pesar de estar calibrando." SEVERITY failure;

        pulsadores1(1) <= '1'; -- dar impulso rs
        pulsadores1(5) <= '1'; -- dar impulso bn
        WAIT FOR 1 ns;
        pulsadores1(1) <= '0';
        pulsadores1(5) <= '0';
        WAIT FOR 3 ns;

        ASSERT leds(2) = '0' REPORT "No se desactiva el led de calibración tras terminar la calibración." SEVERITY failure;

        ASSERT leds(6) = '0' REPORT "No se desactiva la orden de subir el respaldo tras terminar la calibración." SEVERITY failure;

        ASSERT leds(4) = '0' REPORT "No se desactiva la orden de subir la banqueta tras terminar la calibración." SEVERITY failure;

        -- Comprobar límite inferior
        pulsadores1(2) <= '1'; -- bajar rs
        pulsadores1(6) <= '1'; -- bajar bn

        FOR i IN 0 TO 4 LOOP -- 5 pulsos a cada uno
            pulsadores1(1) <= '1';
            pulsadores1(5) <= '1';
            WAIT FOR 1 ns;
            pulsadores1(1) <= '0';
            pulsadores1(5) <= '0';
            WAIT FOR 1 ns;
        END LOOP;

        pulsadores1(2) <= '0';
        pulsadores1(6) <= '0';
        WAIT FOR 3 ns;

        ASSERT leds(3) = '1' REPORT "No se respeta el límite inferior." SEVERITY failure;

        -- Movernos y guardar en el perfil 1
        pulsadores1(3) <= '1';
        WAIT FOR 1 ns;

        FOR i IN 0 TO 2 LOOP -- subir 3 veces el rs
            pulsadores1(1) <= '1';
            WAIT FOR 1 ns;
            pulsadores1(1) <= '0';
            WAIT FOR 1 ns;
        END LOOP;

        pulsadores1(7) <= '1';
        WAIT FOR 1 ns;

        FOR i IN 0 TO 3 LOOP -- subir 4 veces el bn
            pulsadores1(5) <= '1';
            WAIT FOR 1 ns;
            pulsadores1(5) <= '0';
            WAIT FOR 1 ns;
        END LOOP;

        pulsadores1(3) <= '0';
        pulsadores1(7) <= '0';
        WAIT FOR 1 ns;

        key_1 <= '1'; -- seleccionar perfil 1
        WAIT FOR 3 ns;
        key_1 <= '0';
        WAIT FOR 1 ns;

        key_0 <= '1'; -- guardar perfil
        WAIT FOR 3 ns;
        key_0 <= '0';
        WAIT FOR 1 ns;

        -- Moverse fuera de la posición guardada
        pulsadores1(3) <= '1';
        WAIT FOR 1 ns;

        FOR i IN 0 TO 1 LOOP -- subir 2 veces el rs
            pulsadores1(1) <= '1';
            WAIT FOR 1 ns;
            pulsadores1(1) <= '0';
            WAIT FOR 1 ns;
        END LOOP;

        pulsadores1(7) <= '1';
        WAIT FOR 1 ns;

        FOR i IN 0 TO 2 LOOP -- subir 3 veces el bn
            pulsadores1(5) <= '1';
            WAIT FOR 1 ns;
            pulsadores1(5) <= '0';
            WAIT FOR 1 ns;
        END LOOP;

        pulsadores1(3) <= '0';
        pulsadores1(7) <= '0';
        WAIT FOR 1 ns;

        -- Cargar perfil 1 y comprobar que se nos pide movernos de forma correcta
        dip(1) <= '1'; -- cargar perfil 1
        WAIT FOR 3 ns;

        ASSERT leds(7) = '1' REPORT "No se manda la orden de bajar el respaldo a pesar de estar cargando una posición." SEVERITY failure;

        ASSERT leds(5) = '1' REPORT "No se manda la orden de bajar la banqueta a pesar de estar cargando una posición." SEVERITY failure;

        -- Bajar el rs a la posición deseada
        FOR i IN 0 TO 1 LOOP -- bajar 2 veces el rs
            pulsadores1(1) <= '1';
            WAIT FOR 1 ns;
            pulsadores1(1) <= '0';
            WAIT FOR 1 ns;
        END LOOP;

        WAIT FOR 3 ns;

        ASSERT leds(7) = '0' REPORT "No se desactiva la orden de bajar el respaldo tras llegar a la posición deseada." SEVERITY failure;

        ASSERT leds(5) = '1' REPORT "Se desactiva la orden de bajada de la banqueta cuando esta no ha sido movida a su posición deseada." SEVERITY note;

        -- Bajar la banqueta a la posición deseada
        FOR i IN 0 TO 2 LOOP -- bajar 3 veces la banqueta
            pulsadores1(5) <= '1';
            WAIT FOR 1 ns;
            pulsadores1(5) <= '0';
            WAIT FOR 1 ns;
        END LOOP;

        WAIT FOR 3 ns;

        ASSERT leds(5) = '0' REPORT "No se desactiva la orden de bajar la banqueta tras llegar a la posición deseada." SEVERITY failure;

        dip(1) <= '0';
        WAIT FOR 1 ns;

        WAIT;
    END PROCESS;

END ARCHITECTURE test;
