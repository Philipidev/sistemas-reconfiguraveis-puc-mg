library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Use numeric_std para to_integer e unsigned

-- Definição da entidade ram_256x8
entity ram_256x8 is
    port (
        nrst       : in  std_logic;  -- Entrada de reset assíncrono
        clk_in     : in  std_logic;  -- Entrada de clock do sistema
        addr       : in  std_logic_vector(7 downto 0);  -- Barramento de endereços
        dio        : inout std_logic_vector(7 downto 0);  -- Barramento bidirecional de dados
        mem_wr_en  : in  std_logic;  -- Habilitação de escrita na memória
        mem_rd_en  : in  std_logic   -- Habilitação de leitura da memória
    );
end ram_256x8;

-- Arquitetura comportamental da entidade ram_256x8
architecture Behavioral of ram_256x8 is
    -- Definição do tipo de dado para a memória
    type memory_type is array (255 downto 0) of std_logic_vector(7 downto 0);
    signal memory : memory_type := (others => (others => '0'));  -- Sinal que representa a memória
    signal data_out : std_logic_vector(7 downto 0);  -- Sinal para os dados de saída
begin
    -- Processo para tratar o reset assíncrono e a escrita síncrona
    process(nrst, clk_in)
    begin
        if nrst = '0' then
            -- Reset assíncrono: zera todas as posições da memória
            memory <= (others => (others => '0'));
        elsif rising_edge(clk_in) then
            if mem_wr_en = '1' then
                -- Escreve na memória na posição especificada por addr
                memory(to_integer(unsigned(addr))) <= dio;
            end if;
        end if;
    end process;

    -- Processo para tratar a leitura assíncrona
    process(addr, mem_rd_en)
    begin
        if mem_rd_en = '1' then
            -- Lê o valor da memória na posição especificada por addr
            data_out <= memory(to_integer(unsigned(addr)));
        else
            data_out <= (others => 'Z');  -- Alta impedância quando não está lendo
        end if;
    end process;

    -- Buffer tri-state para o barramento de dados
    dio <= data_out when mem_rd_en = '1' else (others => 'Z');
    
end Behavioral;
