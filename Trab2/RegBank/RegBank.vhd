library IEEE;
use IEEE.STD_LOGIC_1164.ALL;  -- Biblioteca para uso de tipos l�gicos padr�o
use IEEE.NUMERIC_STD.ALL;  -- Biblioteca para convers�es num�ricas e opera��es com std_logic_vector

-- Declara��o da entidade RegBank
entity RegBank is
    port (
        clk_in       : in  std_logic;  -- Entrada de clock para opera��es s�ncronas
        nrst         : in  std_logic;  -- Entrada de reset ass�ncrono, zera os registradores quando em n�vel baixo
        regn_di      : in  std_logic_vector(7 downto 0);  -- Dados de entrada para escrita nos registradores
        regn_wr_sel  : in  std_logic_vector(2 downto 0);  -- Seleciona qual registrador ser� escrito
        regn_wr_ena  : in  std_logic;  -- Habilita a escrita nos registradores quando em n�vel alto
        regn_rd_sel_a: in  std_logic_vector(2 downto 0);  -- Seleciona qual registrador ser� lido na sa�da A
        regn_rd_sel_b: in  std_logic_vector(2 downto 0);  -- Seleciona qual registrador ser� lido na sa�da B
        c_flag_in    : in  std_logic;  -- Entrada do valor para a flag C
        z_flag_in    : in  std_logic;  -- Entrada do valor para a flag Z
        v_flag_in    : in  std_logic;  -- Entrada do valor para a flag V
        c_flag_wr_ena: in  std_logic;  -- Habilita a escrita na flag C
        z_flag_wr_ena: in  std_logic;  -- Habilita a escrita na flag Z
        v_flag_wr_ena: in  std_logic;  -- Habilita a escrita na flag V
        regn_do_a    : out std_logic_vector(7 downto 0);  -- Sa�da A que mostra o valor do registrador selecionado
        regn_do_b    : out std_logic_vector(7 downto 0);  -- Sa�da B que mostra o valor do registrador selecionado
        c_flag_out   : out std_logic;  -- Sa�da da flag C
        z_flag_out   : out std_logic;  -- Sa�da da flag Z
        v_flag_out   : out std_logic   -- Sa�da da flag V
    );
end RegBank;

architecture Behavioral of RegBank is
    type reg_array is array (0 to 7) of std_logic_vector(7 downto 0);  -- Array de registradores
    signal registers : reg_array;  -- Sinal para armazenar os valores dos registradores
    signal c_flag, z_flag, v_flag : std_logic;  -- Sinais para as flags de status
begin
    -- Processo para escrita dos registradores e flags, controlado por clock e reset
    process (clk_in, nrst)
    begin
        if nrst = '0' then
            registers <= (others => (others => '0'));  -- Zera todos os registradores se reset estiver ativo
            c_flag <= '0';  -- Zera a flag C
            z_flag <= '0';  -- Zera a flag Z
            v_flag <= '0';  -- Zera a flag V
        elsif rising_edge(clk_in) then
            if regn_wr_ena = '1' then
                registers(to_integer(unsigned(regn_wr_sel))) <= regn_di;  -- Escreve nos registradores se habilitado
            end if;
            if c_flag_wr_ena = '1' then
                c_flag <= c_flag_in;  -- Atualiza a flag C se habilitado
            end if;
            if z_flag_wr_ena = '1' then
                z_flag <= z_flag_in;  -- Atualiza a flag Z se habilitado
            end if;
            if v_flag_wr_ena = '1' then
                v_flag <= v_flag_in;  -- Atualiza a flag V se habilitado
            end if;
        end if;
    end process;

    -- Leitura ass�ncrona dos registradores para as sa�das
    regn_do_a <= registers(to_integer(unsigned(regn_rd_sel_a)));  -- Atribui a sa�da A baseado no registrador selecionado
    regn_do_b <= registers(to_integer(unsigned(regn_rd_sel_b)));  -- Atribui a sa�da B baseado no registrador selecionado

    -- Sa�das das flags
    c_flag_out <= c_flag;  -- A sa�da da flag C reflete o estado atual da flag
    z_flag_out <= z_flag;  -- A sa�da da flag Z reflete o estado atual da flag
    v_flag_out <= v_flag;  -- A sa�da da flag V reflete o estado atual da flag
end Behavioral;
