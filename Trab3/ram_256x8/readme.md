### README para o Projeto VHDL

#### Visão Geral do Projeto

Este projeto consiste em código VHDL para duas entidades principais: `port_io` e `ram_256x8`. Esses componentes são projetados para lidar com operações de entrada/saída e armazenamento de memória, respectivamente. Abaixo está uma explicação detalhada de cada componente e suas funcionalidades.

---

#### Componentes

1. **port_io**
    - **Descrição da Entidade**: A entidade `port_io` é projetada para gerenciar operações de I/O com um endereço base configurável. Ela lida com reset assíncrono, entrada de clock do sistema, barramento de endereços, barramento de dados bidirecional, habilitação de escrita, habilitação de leitura e uma porta I/O bidirecional.
    - **Arquitetura**: A arquitetura inclui processos para lidar com resets assíncronos, escritas síncronas, manipulação de direção e dados, e operações de leitura. Os sinais internos incluem registrador de direção, registrador de porta, latch e sinal interno do barramento de dados.

    ```vhdl
    library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

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

    architecture Behavioral of port_io is
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
    ```

2. **ram_256x8**
    - **Descrição da Entidade**: A entidade `ram_256x8` é uma memória RAM de 256x8 bits que lida com reset assíncrono, entrada de clock do sistema, barramento de endereços, barramento de dados bidirecional, habilitação de escrita na memória e habilitação de leitura da memória.
    - **Arquitetura**: A arquitetura inclui processos para tratar reset assíncrono, escrita síncrona e leitura assíncrona. O tipo de dado da memória é definido como um array de 256 elementos de vetores de 8 bits.

    ```vhdl
    library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL; -- Use numeric_std para to_integer e unsigned

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

    architecture Behavioral of ram_256x8 is
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
    ```

---

### Como Usar

1. **Compilação**: Use um compilador VHDL como o Xilinx ISE, Altera Quartus ou GHDL para compilar os arquivos `port_io.vhd` e `ram_256x8.vhd`.
2. **Simulação**: Realize a simulação usando uma ferramenta de simulação VHDL para verificar a funcionalidade dos componentes.
3. **Síntese**: Utilize uma ferramenta de síntese para mapear os componentes para um FPGA ou outro dispositivo lógico programável.
4. **Testes**: Após a síntese, programe o FPGA e execute testes de hardware para garantir que os componentes funcionem conforme esperado.