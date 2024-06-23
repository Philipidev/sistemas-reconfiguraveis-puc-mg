library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Stack is
    port (
        clk_in     : in std_logic;                 -- Entrada de clock
        nrst       : in std_logic;                 -- Entrada de reset assíncrono
        stack_in   : in std_logic_vector(10 downto 0); -- Entrada de dados para a pilha
        stack_push : in std_logic;                 -- Sinal para habilitar a inserção (push) na pilha
        stack_pop  : in std_logic;                 -- Sinal para habilitar a remoção (pop) da pilha
        stack_out  : out std_logic_vector(10 downto 0) -- Saída que mostra o topo da pilha
    );
end Stack;

architecture Behavioral of Stack is
    type stack_array is array (0 to 7) of std_logic_vector(10 downto 0);
    signal stack : stack_array := (others => (others => '0'));  -- Array para armazenar os elementos da pilha
begin
    -- Processo sensível ao clock e ao reset para gerenciar a pilha
    process (clk_in, nrst)
    begin
        if nrst = '0' then
            stack <= (others => (others => '0'));  -- Reseta a pilha se o sinal de reset estiver ativo
        elsif rising_edge(clk_in) then
            if stack_push = '1' and stack_pop = '0' then
                -- Processo de push: move os elementos para cima para inserir um novo no topo
                for i in 6 downto 0 loop
                    stack(i + 1) <= stack(i);
                end loop;
                stack(0) <= stack_in;  -- Insere novo dado no topo da pilha
            elsif stack_pop = '1' and stack_push = '0' then
                -- Processo de pop: move os elementos para baixo, removendo o elemento do topo
                for i in 0 to 6 loop
                    stack(i) <= stack(i + 1);
                end loop;
                stack(7) <= (others => '0');  -- Limpa o elemento mais alto, agora inutilizado
            end if;
        end if;
    end process;

    -- A saída sempre reflete o elemento no topo da pilha
    stack_out <= stack(0);
end Behavioral;
