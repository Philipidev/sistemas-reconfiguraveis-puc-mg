### README para o Projeto de Sistemas Reconfiguráveis

#### Visão Geral do Projeto

Este projeto apresenta a concepção, implementação e simulação de três módulos fundamentais em VHDL: um banco de registradores (`reg_bank`), uma pilha de dados (`stack`) e um contador programável (`Prog_cnt`). Cada módulo foi projetado para operar com sinais do tipo `std_logic` ou `std_logic_vector`, e foi desenvolvido utilizando a linguagem VHDL com a ferramenta Quartus na versão 9.1sp2.

---

#### Componentes do Projeto

1. **reg_bank**
    - **Descrição da Implementação**: O `reg_bank` simula um banco de registradores contendo oito registradores de 8 bits cada. O registrador R7 é utilizado para armazenar flags de status como carry (C), zero (Z) e overflow (V). As principais operações incluem escrita sincrônica e leitura assíncrona.
    - **Operações**:
        - **Escrita**: Sincronizada com o clock do sistema quando o sinal `regn_wr_ena` está ativo. A seleção do registrador destino é feita pelo sinal `regn_wr_sel`.
        - **Leitura**: Executada de maneira assíncrona através das saídas `regn_do_a` e `regn_do_b`.
    - **Resultados da Simulação**: Demonstrou capacidade de armazenamento e recuperação de dados, com integridade e precisão. As flags de status foram atualizadas corretamente.

    ```vhdl
    library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

    entity RegBank is
        port (
            clk_in : in std_logic;
            nrst : in std_logic;
            regn_di : in std_logic_vector(7 downto 0);
            regn_wr_sel : in std_logic_vector(2 downto 0);
            regn_wr_ena : in std_logic;
            regn_rd_sel_a : in std_logic_vector(2 downto 0);
            regn_rd_sel_b : in std_logic_vector(2 downto 0);
            c_flag_in : in std_logic;
            z_flag_in : in std_logic;
            v_flag_in : in std_logic;
            c_flag_wr_ena : in std_logic;
            z_flag_wr_ena : in std_logic;
            v_flag_wr_ena : in std_logic;
            regn_do_a : out std_logic_vector(7 downto 0);
            regn_do_b : out std_logic_vector(7 downto 0);
            c_flag_out : out std_logic;
            z_flag_out : out std_logic;
            v_flag_out : out std_logic
        );
    end RegBank;

    architecture Behavioral of RegBank is
        type reg_array is array (0 to 7) of std_logic_vector(7 downto 0);
        signal registers : reg_array;
        signal c_flag, z_flag, v_flag : std_logic;
    begin
        process (clk_in, nrst)
        begin
            if nrst = '0' then
                registers <= (others => (others => '0'));
                c_flag <= '0';
                z_flag <= '0';
                v_flag <= '0';
            elsif rising_edge(clk_in) then
                if regn_wr_ena = '1' then
                    registers(to_integer(unsigned(regn_wr_sel))) <= regn_di;
                end if;
                if c_flag_wr_ena = '1' then
                    c_flag <= c_flag_in;
                end if;
                if z_flag_wr_ena = '1' then
                    z_flag <= z_flag_in;
                end if;
                if v_flag_wr_ena = '1' then
                    v_flag <= v_flag_in;
                end if;
            end if;
        end process;

        regn_do_a <= registers(to_integer(unsigned(regn_rd_sel_a)));
        regn_do_b <= registers(to_integer(unsigned(regn_rd_sel_b)));
        c_flag_out <= c_flag;
        z_flag_out <= z_flag;
        v_flag_out <= v_flag;
    end Behavioral;
    ```

2. **Stack**
    - **Descrição da Implementação**: A `Stack` funciona como uma pilha de dados com 8 registradores de 11 bits cada, operando sob o princípio LIFO (Last In, First Out). As principais operações incluem push e pop.
    - **Operações**:
        - **Push**: Inserção de dados na borda de subida do clock quando o sinal `stack_push` está ativo.
        - **Pop**: Remoção de dados na borda de subida do clock quando o sinal `stack_pop` está ativo.
    - **Resultados da Simulação**: Validou a capacidade de armazenamento e recuperação de dados de forma correta e sequencial, respeitando o princípio LIFO.

    ```vhdl
    library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

    entity Stack is
        port (
            clk_in : in std_logic;
            nrst : in std_logic;
            stack_in : in std_logic_vector(10 downto 0);
            stack_push : in std_logic;
            stack_pop : in std_logic;
            stack_out : out std_logic_vector(10 downto 0)
        );
    end Stack;

    architecture Behavioral of Stack is
        type stack_array is array (0 to 7) of std_logic_vector(10 downto 0);
        signal stack : stack_array := (others => (others => '0'));
    begin
        process (clk_in, nrst)
        begin
            if nrst = '0' then
                stack <= (others => (others => '0'));
            elsif rising_edge(clk_in) then
                if stack_push = '1' and stack_pop = '0' then
                    for i in 6 downto 0 loop
                        stack(i + 1) <= stack(i);
                    end loop;
                    stack(0) <= stack_in;
                elsif stack_pop = '1' and stack_push = '0' then
                    for i in 0 to 6 loop
                        stack(i) <= stack(i + 1);
                    end loop;
                    stack(7) <= (others => '0');
                end if;
            end if;
        end process;

        stack_out <= stack(0);
    end Behavioral;
    ```

3. **Prog_cnt**
    - **Descrição da Implementação**: O `Prog_cnt` é um contador programável que conta até 2047 (módulo 2048) e possui funcionalidades de carregamento e incremento controladas por sinais de entrada.
    - **Operações**:
        - **Incremento**: Incrementa automaticamente em cada borda de subida do clock se `pc_ctrl` estiver configurado para "11".
        - **Carregamento Direto**: Carrega um valor específico (`new_pc_in`) diretamente no contador se `pc_ctrl` estiver configurado para "01".
        - **Carregamento da Pilha**: Carrega valores do topo de uma pilha (`from_stack`) diretamente no contador se `pc_ctrl` estiver configurado para "10".
    - **Resultados da Simulação**: Validou as múltiplas funções do contador, confirmando que responde corretamente aos comandos de controle.

    ```vhdl
    library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

    entity Prog_cnt is
        port (
            clk_in : in std_logic;
            nrst : in std_logic;
            pc_ctrl : in std_logic_vector(1 downto 0);
            new_pc_in : in std_logic_vector(10 downto 0);
            from_stack : in std_logic_vector(10 downto 0);
            next_pc_out : buffer std_logic_vector(10 downto 0);
            pc_out : out std_logic_vector(10 downto 0)
        );
    end Prog_cnt;

    architecture Behavioral of Prog_cnt is
        signal pc : std_logic_vector(10 downto 0) := (others => '0');
    begin
        with pc_ctrl select
            next_pc_out <= pc when "00",
                           new_pc_in when "01",
                           from_stack when "10",
                           std_logic_vector(unsigned(pc) + 1) when "11",
                           pc when others;

        process (clk_in, nrst)
        begin
            if nrst = '0' then
                pc <= (others => '0');
            elsif rising_edge(clk_in) then
                pc <= next_pc_out;
            end if;
        end process;

        pc_out <= pc;
    end Behavioral;
    ```

---

### Como Usar

1. **Compilação**: Use um compilador VHDL como o Quartus para compilar os arquivos de código VHDL fornecidos.
2. **Simulação**: Realize a simulação utilizando uma ferramenta de simulação VHDL para verificar a funcionalidade dos módulos.
3. **Síntese**: Utilize uma ferramenta de síntese para mapear os módulos para um FPGA ou outro dispositivo lógico programável.
4. **Testes**: Após a síntese, programe o FPGA e execute testes de hardware para garantir que os módulos funcionem conforme especificado.

---
