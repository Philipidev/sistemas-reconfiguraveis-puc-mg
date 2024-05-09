library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Testbench para RegBank
entity RegBank_tb is
-- Declaração vazia, pois é um testbench
end RegBank_tb;

architecture test of RegBank_tb is
    -- Sinais para interconectar ao DUT (Device Under Test)
    signal clk_in       : std_logic := '0';
    signal nrst         : std_logic := '1';
    signal regn_di      : std_logic_vector(7 downto 0) := (others => '0');
    signal regn_wr_sel  : std_logic_vector(2 downto 0) := (others => '0');
    signal regn_wr_ena  : std_logic := '0';
    signal regn_rd_sel_a: std_logic_vector(2 downto 0) := (others => '0');
    signal regn_rd_sel_b: std_logic_vector(2 downto 0) := (others => '0');
    signal c_flag_in    : std_logic := '0';
    signal z_flag_in    : std_logic := '0';
    signal v_flag_in    : std_logic := '0';
    signal c_flag_wr_ena: std_logic := '0';
    signal z_flag_wr_ena: std_logic := '0';
    signal v_flag_wr_ena: std_logic := '0';
    signal regn_do_a    : std_logic_vector(7 downto 0);
    signal regn_do_b    : std_logic_vector(7 downto 0);
    signal c_flag_out   : std_logic;
    signal z_flag_out   : std_logic;
    signal v_flag_out   : std_logic;

    -- Instanciação do DUT
    begin
    uut: entity work.RegBank
        port map (
            clk_in => clk_in,
            nrst => nrst,
            regn_di => regn_di,
            regn_wr_sel => regn_wr_sel,
            regn_wr_ena => regn_wr_ena,
            regn_rd_sel_a => regn_rd_sel_a,
            regn_rd_sel_b => regn_rd_sel_b,
            c_flag_in => c_flag_in,
            z_flag_in => z_flag_in,
            v_flag_in => v_flag_in,
            c_flag_wr_ena => c_flag_wr_ena,
            z_flag_wr_ena => z_flag_wr_ena,
            v_flag_wr_ena => v_flag_wr_ena,
            regn_do_a => regn_do_a,
            regn_do_b => regn_do_b,
            c_flag_out => c_flag_out,
            z_flag_out => z_flag_out,
            v_flag_out => v_flag_out
        );

    -- Clock process
    clocking: process
    begin
        while TRUE loop
            clk_in <= '0';
            wait for 10 ns;
            clk_in <= '1';
            wait for 10 ns;
        end loop;
    end process;

    -- Processo do Stimulus para aplicar os testes nos vetores
    stimulus: process
    begin
        -- Testar resetar
        nrst <= '0';
        wait for 20 ns;
        nrst <= '1';
        
        -- Testar escrever no registrador
        regn_di <= "10101010";
        regn_wr_sel <= "000";
        regn_wr_ena <= '1';
        wait for 20 ns;
        
        -- Testar ler do mesmo registrador
        regn_rd_sel_a <= "000";
        wait for 10 ns;
        assert regn_do_a = "10101010"
            report "Register write/read test failed" severity error;
        
        -- Testar flag de escrever e de ler
        c_flag_in <= '1';
        c_flag_wr_ena <= '1';
        wait for 20 ns;
        assert c_flag_out = '1'
            report "Flag C test failed" severity error;
        
        -- Completar o teste
        wait;
    end process;
end test;
