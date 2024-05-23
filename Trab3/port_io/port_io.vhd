library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Biblioteca para opera��es aritm�ticas e tipos unsigned

entity port_io is
    generic (
        base_addr : std_logic_vector(7 downto 0) := x"00" -- Endere�o base para os registradores com valor padr�o
    );
    port (
        nrst     : in  std_logic; -- Entrada de reset ass�ncrono
        clk_in   : in  std_logic; -- Entrada de clock do sistema
        abus     : in  std_logic_vector(7 downto 0); -- Barramento de endere�os
        dbus     : inout std_logic_vector(7 downto 0); -- Barramento de dados bidirecional
        wr_en    : in  std_logic; -- Habilita��o para escrita
        rd_en    : in  std_logic; -- Habilita��o para leitura
        port_io  : inout std_logic_vector(7 downto 0) -- Porta de E/S bidirecional
    );
end port_io;

architecture Behavioral of port_io is
    -- Registradores internos
    signal dir_reg  : std_logic_vector(7 downto 0) := (others => '0'); -- Configura��o da dire��o dos pinos
    signal port_reg : std_logic_vector(7 downto 0) := (others => '0'); -- Armazena os dados de sa�da
    signal latch    : std_logic_vector(7 downto 0); -- Armazena os dados de entrada temporariamente

begin
    -- Processo de reset e escrita nos registradores
    process(nrst, clk_in)
    begin
        if nrst = '0' then
            -- Reset ass�ncrono: zera todos os registradores
            dir_reg  <= (others => '0');
            port_reg <= (others => '0');
        elsif rising_edge(clk_in) then
            if wr_en = '1' then
                if abus = base_addr then
                    -- Escreve no registrador port_reg
                    port_reg <= dbus;
                elsif abus = std_logic_vector(to_unsigned(to_integer(unsigned(base_addr)) + 1, 8)) then
                    -- Escreve no registrador dir_reg
                    dir_reg <= dbus;
                end if;
            end if;
        end if;
    end process;

    -- Processo de leitura dos registradores
    process(rd_en, abus, latch, dir_reg)
    begin
        if rd_en = '1' then
            if abus = base_addr then
                -- Leitura do latch (estado dos pinos de entrada)
                dbus <= latch;
            elsif abus = std_logic_vector(to_unsigned(to_integer(unsigned(base_addr)) + 1, 8)) then
                -- Leitura do registrador dir_reg (configura��o das dire��es)
                dbus <= dir_reg;
            else
                -- Alta imped�ncia se o endere�o n�o corresponder
                dbus <= (others => 'Z');
            end if;
        else
            -- Alta imped�ncia quando rd_en n�o est� ativo
            dbus <= (others => 'Z');
        end if;
    end process;

    -- L�gica de interfaceamento com a porta de E/S
    gen_io: for i in 0 to 7 generate
    begin
        process(dir_reg, port_reg, port_io)
        begin
            if dir_reg(i) = '1' then
                -- Configura o pino como sa�da
                port_io(i) <= port_reg(i);
            else
                -- Configura o pino como entrada e armazena o valor no latch
                latch(i) <= port_io(i);
                port_io(i) <= 'Z'; -- Alta imped�ncia quando � entrada
            end if;
        end process;
    end generate;

end Behavioral;
