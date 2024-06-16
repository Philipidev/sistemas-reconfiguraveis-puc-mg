library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity puc_241 is
    Port (
        -- Sinais de controle e clock
        nrst : in std_logic;                    -- Sinal de reset negativo
        clk : in std_logic;                     -- Sinal de clock de entrada

        -- Sinais de entrada
        rom_q : in std_logic_vector(15 downto 0); -- Sinal de sa�da da ROM

        -- Sinais de flags
        c_flag_reg : in std_logic;
        z_flag_reg : in std_logic;
        v_flag_reg : in std_logic;

        -- Sinais de sa�da de controle
        reg_do_a_on_dext : out std_logic;
        reg_di_sel : out std_logic;
        alu_b_in_sel : out std_logic;
        reg_wr_ena : out std_logic;
        c_flag_wr_ena : out std_logic;
        z_flag_wr_ena : out std_logic;
        v_flag_wr_ena : out std_logic;
        alu_op : out std_logic_vector(3 downto 0);
        stack_push : out std_logic;
        stack_pop : out std_logic;
        pc_ctrl : out std_logic_vector(1 downto 0);
        mem_wr_ena : out std_logic;
        mem_rd_ena : out std_logic;
        inp : out std_logic;
        outp : out std_logic
    );
end puc_241;

architecture Behavioral of puc_241 is
    -- Vari�veis para registradores e endere�o
    signal RA, RB : std_logic_vector(2 downto 0);
    signal instrucao : std_logic_vector(6 downto 0);
    
    -- Defini��o das opera��es
    constant INSTRUCAO_REG_REG  : std_logic_vector(1 downto 0) := "00";
    constant INSTRUCAO_REG_IMMED  : std_logic_vector(1 downto 0) := "01";
    constant INSTRUCAO_ALU_1_REG  : std_logic_vector(1 downto 0) := "10";
    constant INSTRUCAO_MEMORIA_ES  : std_logic_vector(2 downto 0) := "110";
    constant INSTRUCAO_DESVIO_INCONDICIONAL  : std_logic_vector(3 downto 0) := "1110";
    constant INSTRUCAO_SALTO_CONDICIONAL_RETORNO  : std_logic_vector(5 downto 1) := "11110";

    -- Instru��es Reg-Reg
    constant AND_OP  : std_logic_vector(2 downto 0) := "000";
    constant OR_OP   : std_logic_vector(2 downto 0) := "001";
    constant XOR_OP  : std_logic_vector(2 downto 0) := "010";
    constant MOV_OP  : std_logic_vector(2 downto 0) := "011";
    constant ADD_OP  : std_logic_vector(2 downto 0) := "100";
    constant ADDC_OP : std_logic_vector(2 downto 0) := "101";
    constant SUB_OP  : std_logic_vector(2 downto 0) := "110";
    constant SUBC_OP : std_logic_vector(2 downto 0) := "111";

    -- Instru��es Reg-Immed
    constant ANDI_OP  : std_logic_vector(2 downto 0) := "000";
    constant ORI_OP   : std_logic_vector(2 downto 0) := "001";
    constant XORI_OP  : std_logic_vector(2 downto 0) := "010";
    constant MOVI_OP  : std_logic_vector(2 downto 0) := "011";
    constant ADDI_OP  : std_logic_vector(2 downto 0) := "100";
    constant ADDCI_OP : std_logic_vector(2 downto 0) := "101";
    constant SUBI_OP  : std_logic_vector(2 downto 0) := "110";
    constant SUBCI_OP : std_logic_vector(2 downto 0) := "111";

    -- Instru��es ALU-1 Reg
    constant RL_OP   : std_logic_vector(2 downto 0) := "000";
    constant RR_OP   : std_logic_vector(2 downto 0) := "001";
    constant RLC_OP  : std_logic_vector(2 downto 0) := "010";
    constant RRC_OP  : std_logic_vector(2 downto 0) := "011";
    constant SLL_OP  : std_logic_vector(2 downto 0) := "100";
    constant SRL_OP  : std_logic_vector(2 downto 0) := "101";
    constant SRA_OP  : std_logic_vector(2 downto 0) := "110";
    constant NOT_OP  : std_logic_vector(2 downto 0) := "111";

    -- Instru��es de mem�ria e E/S
    constant LDM_OP  : std_logic_vector(1 downto 0) := "00";
    constant STM_OP  : std_logic_vector(1 downto 0) := "01";
    constant INP_OP  : std_logic_vector(1 downto 0) := "10";
    constant OUT_OP  : std_logic_vector(1 downto 0) := "11";

    -- Instru��es de desvio incondicional e chamada de sub-rotina
    constant JMP_OP  : std_logic_vector(0 downto 0) := "0";
    constant CALL_OP : std_logic_vector(0 downto 0) := "1";

    -- Instru��es de salto condicional E Instru��o de retorno
    constant SKIPC_OP : std_logic_vector(1 downto 0) := "00";
    constant SKIPZ_OP : std_logic_vector(1 downto 0) := "01";
    constant SKIPV_OP : std_logic_vector(1 downto 0) := "10";
    constant RET_OP   : std_logic_vector(1 downto 0) := "11";

begin
    process (clk, nrst)
    begin
        if nrst = '0' then
            -- Reset todos os sinais de controle
            reg_do_a_on_dext <= '0';
            reg_di_sel <= '0';
            alu_b_in_sel <= '0';
            reg_wr_ena <= '0';
            c_flag_wr_ena <= '0';
            z_flag_wr_ena <= '0';
            v_flag_wr_ena <= '0';
            alu_op <= (others => '0');
            stack_push <= '0';
            stack_pop <= '0';
            pc_ctrl <= (others => '0');
            mem_wr_ena <= '0';
            mem_rd_ena <= '0';
            inp <= '0';
            outp <= '0';
        elsif rising_edge(clk) then
            -- Decodifica��o da instru��o
            instrucao <= rom_q(15 downto 9);
            RA <= rom_q(10 downto 8);
            RB <= rom_q(7 downto 5);

            -- Reset flags de controle
            reg_do_a_on_dext <= '0';
            reg_di_sel <= '0';
            alu_b_in_sel <= '0';
            reg_wr_ena <= '0';
            c_flag_wr_ena <= '0';
            z_flag_wr_ena <= '0';
            v_flag_wr_ena <= '0';
            stack_push <= '0';
            stack_pop <= '0';
            mem_wr_ena <= '0';
            mem_rd_ena <= '0';
            inp <= '0';
            outp <= '0';

            -- Decodifica��o e execu��o da instru��o
            if instrucao(6 downto 5) = INSTRUCAO_REG_REG then
                if instrucao(4 downto 2) = AND_OP then
                    alu_op <= "0000"; -- AND
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = OR_OP then
                    alu_op <= "0001"; -- OR
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = XOR_OP then
                    alu_op <= "0010"; -- XOR
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = MOV_OP then
                    alu_op <= "0011"; -- MOV
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = ADD_OP then
                    alu_op <= "0100"; -- ADD
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = ADDC_OP then
                    alu_op <= "0101"; -- ADDC
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = SUB_OP then
                    alu_op <= "0110"; -- SUB
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = SUBC_OP then
                    alu_op <= "0111"; -- SUBC
                    reg_wr_ena <= '1';
                else
                    alu_op <= "1111"; -- NOP
                end if;
            elsif instrucao(6 downto 5) = INSTRUCAO_REG_IMMED then
                if instrucao(4 downto 2) = ANDI_OP then
                    alu_op <= "1000"; -- ANDI
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = ORI_OP then
                    alu_op <= "1001"; -- ORI
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = XORI_OP then
                    alu_op <= "1010"; -- XORI
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = MOVI_OP then
                    alu_op <= "1011"; -- MOVI
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = ADDI_OP then
                    alu_op <= "1100"; -- ADDI
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = ADDCI_OP then
                    alu_op <= "1101"; -- ADDCI
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = SUBI_OP then
                    alu_op <= "1110"; -- SUBI
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = SUBCI_OP then
                    alu_op <= "1111"; -- SUBCI
                    reg_wr_ena <= '1';
                else
                    alu_op <= "1111"; -- NOP
                end if;
            elsif instrucao(6 downto 5) = INSTRUCAO_ALU_1_REG then
                if instrucao(4 downto 2) = RL_OP then
                    alu_op <= "0000"; -- RL
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = RR_OP then
                    alu_op <= "0001"; -- RR
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = RLC_OP then
                    alu_op <= "0010"; -- RLC
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = RRC_OP then
                    alu_op <= "0011"; -- RRC
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = SLL_OP then
                    alu_op <= "0100"; -- SLL
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = SRL_OP then
                    alu_op <= "0101"; -- SRL
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = SRA_OP then
                    alu_op <= "0110"; -- SRA
                    reg_wr_ena <= '1';
                elsif instrucao(4 downto 2) = NOT_OP then
                    alu_op <= "0111"; -- NOT
                    reg_wr_ena <= '1';
                else
                    alu_op <= "1111"; -- NOP
                end if;
            elsif instrucao(6 downto 3) = INSTRUCAO_MEMORIA_ES then
                if instrucao(2 downto 1) = LDM_OP then
                    mem_rd_ena <= '1';
                elsif instrucao(2 downto 1) = STM_OP then
                    mem_wr_ena <= '1';
                elsif instrucao(2 downto 1) = INP_OP then
                    inp <= '1';
                elsif instrucao(2 downto 1) = OUT_OP then
                    outp <= '1';
                else
                    null;
                end if;
            elsif instrucao(6 downto 3) = INSTRUCAO_DESVIO_INCONDICIONAL then
                if instrucao(2 downto 2) = JMP_OP then
                    pc_ctrl <= "10"; -- Desvio incondicional
                elsif instrucao(2 downto 2) = CALL_OP then
                    pc_ctrl <= "10"; -- Chamada de sub-rotina
                    stack_push <= '1';
                else
                    alu_op <= "1111"; -- NOP
                end if;
            elsif instrucao(6 downto 2) = INSTRUCAO_SALTO_CONDICIONAL_RETORNO then
                if instrucao(1 downto 0) = SKIPC_OP then
                    if c_flag_reg = '1' then
                        pc_ctrl <= "01"; -- Salta se carry
                    end if;
                elsif instrucao(1 downto 0) = SKIPZ_OP then
                    if z_flag_reg = '1' then
                        pc_ctrl <= "01"; -- Salta se zero
                    end if;
                elsif instrucao(1 downto 0) = SKIPV_OP then
                    if v_flag_reg = '1' then
                        pc_ctrl <= "01"; -- Salta se overflow
                    end if;
                elsif instrucao(1 downto 0) = RET_OP then
                    pc_ctrl <= "11"; -- Retorno de sub-rotina
                    stack_pop <= '1';
                else
                    alu_op <= "1111"; -- NOP
                end if;
            else
                alu_op <= "1111"; -- NOP para qualquer outra instru��o
            end if;
        end if;
    end process;
end Behavioral;
