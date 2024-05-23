library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Biblioteca para operações aritméticas

entity ram_256x8 is
    port (
        nrst      : in  std_logic;                      -- Entrada de reset assíncrono
        clk_in    : in  std_logic;                      -- Entrada de clock do sistema
        addr      : in  std_logic_vector(7 downto 0);   -- Entrada de endereçamento
        dio       : inout std_logic_vector(7 downto 0); -- Barramento de dados bidirecional
        mem_wr_en : in  std_logic;                      -- Habilitação para escrita
        mem_rd_en : in  std_logic                       -- Habilitação para leitura
    );
end ram_256x8;

architecture Behavioral of ram_256x8 is
    -- Declaração da memória RAM como uma matriz de 256 x 8 bits
    type ram_type is array (255 downto 0) of std_logic_vector(7 downto 0);
    signal ram : ram_type := (others => (others => '0')); -- Inicializa toda a memória com zeros

begin
    -- Processo de escrita na memória e reset
    process(nrst, clk_in)
    begin
        if nrst = '0' then
            -- Reset assíncrono: zera todas as posições de memória
            for i in 0 to 255 loop
                ram(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk_in) then
            if mem_wr_en = '1' then
                -- Escrita na memória na posição especificada por addr
                ram(to_integer(unsigned(addr))) <= dio;
            end if;
        end if;
    end process;

    -- Processo de leitura da memória
    process(mem_rd_en, addr)
    begin
        if mem_rd_en = '1' then
            -- Leitura da memória na posição especificada por addr
            dio <= ram(to_integer(unsigned(addr)));
        else
            -- Alta impedância quando a leitura não está habilitada
            dio <= (others => 'Z');
        end if;
    end process;
end Behavioral;
