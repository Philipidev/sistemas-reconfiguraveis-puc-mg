LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all; -- Mudamos para numeric_std para melhor manipula��o de sinais

------------------------------
ENTITY ULA IS
 PORT (
     a_in, b_in : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
     c_in : IN STD_LOGIC;
     op_sel : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
     r_out : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
     c_out, z_out, v_out : OUT STD_LOGIC -- Inclus�o da sa�da v_out
 );
END ENTITY;

ARCHITECTURE arch OF ULA IS
SIGNAL aux : STD_LOGIC_VECTOR(8 DOWNTO 0);
SIGNAL a_signed, b_signed : SIGNED(7 DOWNTO 0); -- Convers�o dos inputs para signed
BEGIN
    a_signed <= SIGNED(a_in);
    b_signed <= SIGNED(b_in);

    WITH op_sel SELECT -- Incluimos o carry out na primeira posi��o do vetor auxiliar para o retorno
        aux <= '0' & a_in AND b_in WHEN "0000", -- AND
             '0' & a_in OR b_in WHEN "0001", -- OR
             '0' & a_in XOR b_in WHEN "0010", -- XOR
             '0' & NOT a_in WHEN "0011", -- COM
             std_logic_vector(('0' & a_signed) + ('0' & b_signed)) WHEN "0100", -- ADD
             std_logic_vector(('0' & a_signed) + ('0' & b_signed) + ("00000000" & c_in)) WHEN "0101", -- ADDC
             std_logic_vector(('0' & a_signed) - ('0' & b_signed)) WHEN "0110", -- SUB
             std_logic_vector(('0' & a_signed) - ('0' & b_signed) - ("00000000" & c_in)) WHEN "0111", -- SUBC
             (a_in(7 downto 0) & '0') WHEN "1000", -- RL
             (a_in(0) & '0' & a_in(7 downto 1)) WHEN "1001", -- RR
             (a_in(7 downto 0) & c_in) WHEN "1010", -- RLC
             (a_in(0) & c_in & a_in(7 downto 1)) WHEN "1011", -- RRC
             (a_in(7 downto 0) & '0') WHEN "1100", -- SLL
             ('0' & '0' & a_in(7 downto 1)) WHEN "1101",  -- SRL
             (a_in(7) & a_in(7) & a_in(7 downto 1)) WHEN "1110",  -- SRA
        ('0' & b_in) WHEN OTHERS;

        r_out <= aux(7 DOWNTO 0); -- Resultado encontrado ap�s as opera��es
        c_out <= aux(8); -- Carry out que foi inserido durante os c�lculos
        z_out <= '1' WHEN aux(7 DOWNTO 0) = "00000000" ELSE '0'; -- Identifica se o resultado das opera��es � zero
        v_out <= '1' WHEN ((a_signed(7) = b_signed(7)) AND (a_signed(7) /= aux(7))) ELSE '0'; -- C�lculo do overflow
        --Explica��o do v_out: 
        --O sinal de overflow (v_out) � calculado baseando-se na regra que 
        --dois n�meros com o mesmo sinal de entrada n�o devem ter um sinal 
        --diferente ap�s a soma ou subtra��o, a menos que ocorra um overflow.
END arch;
