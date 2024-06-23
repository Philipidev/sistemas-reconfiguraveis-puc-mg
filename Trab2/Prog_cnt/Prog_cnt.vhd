library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Prog_cnt is
    Port ( clk_in : in  STD_LOGIC;
           nrst : in  STD_LOGIC;
           pc_ctrl : in  STD_LOGIC_VECTOR (1 downto 0);
           new_pc_in : in  STD_LOGIC_VECTOR (10 downto 0);
           from_stack : in  STD_LOGIC_VECTOR (10 downto 0);
           pc_out : out  STD_LOGIC_VECTOR (10 downto 0);
           next_pc_out : out  STD_LOGIC_VECTOR (10 downto 0));
end Prog_cnt;

architecture Behavioral of Prog_cnt is
    signal pc_reg : STD_LOGIC_VECTOR (10 downto 0) := (others => '0');
    signal next_pc : STD_LOGIC_VECTOR (10 downto 0);
begin

    process(pc_ctrl, new_pc_in, from_stack, pc_reg)
    begin
        case pc_ctrl is
            when "00" => -- Permanece como está
                next_pc <= pc_reg;
            when "01" => -- Carrega um novo valor (new_pc_in)
                next_pc <= new_pc_in;
            when "10" => -- Carrega o valor do topo da pilha (from_stack)
                next_pc <= from_stack;
            when "11" => -- Incrementa o contador
                next_pc <= pc_reg + 1;
            when others =>
                next_pc <= pc_reg;
        end case;
    end process;

    next_pc_out <= next_pc;

    process(clk_in, nrst)
    begin
        if nrst = '0' then
            pc_reg <= (others => '0');
        elsif rising_edge(clk_in) then
            pc_reg <= next_pc;
        end if;
    end process;

    pc_out <= pc_reg;

end Behavioral;
