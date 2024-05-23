library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Biblioteca para opera��es aritm�ticas

entity ram_256x8 is
    port (
        nrst      : in  std_logic;                      -- Entrada de reset ass�ncrono
        clk_in    : in  std_logic;                      -- Entrada de clock do sistema
        addr      : in  std_logic_vector(7 downto 0);   -- Entrada de endere�amento
        dio       : inout std_logic_vector(7 downto 0); -- Barramento de dados bidirecional
        mem_wr_en : in  std_logic;                      -- Habilita��o para escrita
        mem_rd_en : in  std_logic                       -- Habilita��o para leitura
    );
end ram_256x8;

architecture Behavioral of ram_256x8 is
    -- Declara��o da mem�ria RAM como uma matriz de 256 x 8 bits
    type ram_type is array (255 downto 0) of std_logic_vector(7 downto 0);
    signal ram : ram_type := (others => (others => '0')); -- Inicializa toda a mem�ria com zeros

begin
    -- Processo de escrita na mem�ria e reset
    process(nrst, clk_in)
    begin
        if nrst = '0' then
            -- Reset ass�ncrono: zera todas as posi��es de mem�ria
            for i in 0 to 255 loop
                ram(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk_in) then
            if mem_wr_en = '1' then
                -- Escrita na mem�ria na posi��o especificada por addr
                ram(to_integer(unsigned(addr))) <= dio;
            end if;
        end if;
    end process;

    -- Processo de leitura da mem�ria
    process(mem_rd_en, addr)
    begin
        if mem_rd_en = '1' then
            -- Leitura da mem�ria na posi��o especificada por addr
            dio <= ram(to_integer(unsigned(addr)));
        else
            -- Alta imped�ncia quando a leitura n�o est� habilitada
            dio <= (others => 'Z');
        end if;
    end process;
end Behavioral;
