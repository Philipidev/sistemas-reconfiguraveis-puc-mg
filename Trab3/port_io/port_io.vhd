library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Definição da entidade port_io
entity port_io is
    generic (
        base_addr : std_logic_vector(7 downto 0) := "00000000"  -- Endereço base configurável
    );
    port (
        nrst   : in  std_logic;  -- Entrada de reset assíncrono
        clk_in : in  std_logic;  -- Entrada de clock do sistema
        abus   : in  std_logic_vector(7 downto 0);  -- Barramento de endereços
        dbus   : inout std_logic_vector(7 downto 0);  -- Barramento bidirecional de dados
        wr_en  : in  std_logic;  -- Habilitação de escrita
        rd_en  : in  std_logic;  -- Habilitação de leitura
        port_io: inout std_logic_vector(7 downto 0)  -- Porta bidirecional
    );
end port_io;

-- Arquitetura comportamental da entidade port_io
architecture Behavioral of port_io is
    -- Sinais internos para os registradores
    signal dir_reg : std_logic_vector(7 downto 0) := (others => '0');  -- Registrador de direção
    signal port_reg: std_logic_vector(7 downto 0) := (others => '0');  -- Registrador de porta
    signal latch   : std_logic_vector(7 downto 0);  -- Latch para leitura dos pinos
    signal dbus_internal: std_logic_vector(7 downto 0);  -- Sinal interno para o barramento de dados
begin
    -- Processo para tratar o reset assíncrono e as escritas síncronas
    process(nrst, clk_in)
    begin
        if nrst = '0' then
            -- Reset assíncrono: zera os registradores
            dir_reg <= (others => '0');
            port_reg <= (others => '0');
        elsif rising_edge(clk_in) then
            if wr_en = '1' then
                -- Escreve no registrador de porta ou de direção dependendo do endereço
                if abus = base_addr then
                    port_reg <= dbus;
                elsif abus = base_addr + 1 then
                    dir_reg <= dbus;
                end if;
            end if;
        end if;
    end process;

    -- Processo para tratar a direção e os dados da porta
    process(dir_reg, port_reg)
    begin
        for i in 0 to 7 loop
            if dir_reg(i) = '0' then
                port_io(i) <= 'Z';  -- Alta impedância quando configurado como entrada
            else
                port_io(i) <= port_reg(i);  -- Valor de saída quando configurado como saída
            end if;
        end loop;
    end process;

    -- Processo para travar as entradas de port_io quando configuradas como entradas
    process(port_io, dir_reg)
    begin
        for i in 0 to 7 loop
            if dir_reg(i) = '0' then
                latch(i) <= port_io(i);  -- Lê o valor dos pinos de entrada
            else
                latch(i) <= '0';
            end if;
        end loop;
    end process;

    -- Processo para tratar as operações de leitura
    process(rd_en, abus)
    begin
        if rd_en = '1' then
            -- Leitura dos registradores ou latch dependendo do endereço
            if abus = base_addr then
                dbus_internal <= latch;
            elsif abus = base_addr + 1 then
                dbus_internal <= dir_reg;
            else
                dbus_internal <= (others => 'Z');
            end if;
        else
            dbus_internal <= (others => 'Z');
        end if;
    end process;

    -- Buffer tri-state para o barramento de dados
    dbus <= dbus_internal when rd_en = '1' else (others => 'Z');
    
end Behavioral;
