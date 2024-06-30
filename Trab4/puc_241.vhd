library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity puc_241 is
    Port (
		-- Sinais de controle e clock
        nrst : in std_logic;                    -- Sinal de reset negativo
        clk : in std_logic;                     -- Sinal de clock de entrada

        -- Sinais de entrada
        rom_q : in std_logic_vector(15 downto 0); -- Sinal de saída da ROM, contendo a instrução atual

        -- Sinais de flags
        c_flag_reg : in std_logic;              -- Sinal de entrada do flag C
        z_flag_reg : in std_logic;              -- Sinal de entrada do flag Z
        v_flag_reg : in std_logic;              -- Sinal de entrada do flag V

        -- Sinais de saída de controle
        reg_do_a_on_dext : out std_logic;       -- Sinal para ativar a saída do registrador A para a extensão de dados
        reg_di_sel : out std_logic;             -- Sinal para selecionar o valor imediato na entrada do registrador
        alu_b_in_sel : out std_logic;           -- Sinal para selecionar a entrada B da ALU
        reg_wr_ena : out std_logic;             -- Habilitação de escrita nos registradores
        c_flag_wr_ena : out std_logic;          -- Habilitação de escrita do flag C
        z_flag_wr_ena : out std_logic;          -- Habilitação de escrita do flag Z
        v_flag_wr_ena : out std_logic;          -- Habilitação de escrita do flag V
        alu_op : out std_logic_vector(3 downto 0); -- Operação selecionada da ALU
        stack_push : out std_logic;             -- Sinal para empurrar valor na pilha
        stack_pop : out std_logic;              -- Sinal para retirar valor da pilha
        pc_ctrl : out std_logic_vector(1 downto 0); -- Controle do contador do programa
        mem_wr_ena : out std_logic;             -- Habilitação de escrita na memória
        mem_rd_ena : out std_logic;             -- Habilitação de leitura na memória
        inp : out std_logic;                    
        outp : out std_logic;         
        debug : out std_logic_vector(10 downto 0)
    );
end puc_241;

architecture Behavioral of puc_241 is
    type state_type is (rst, fetch_only, fetch_dec_ex);
    signal pres_state, next_state : state_type;
    
    constant INSTRUCAO_REG_REG  : std_logic_vector(1 downto 0) := "00";
    constant INSTRUCAO_REG_IMMED  : std_logic_vector(1 downto 0) := "01";
    constant INSTRUCAO_ALU_1_REG  : std_logic_vector(1 downto 0) := "10";
    constant INSTRUCAO_MEMORIA_ES  : std_logic_vector(2 downto 0) := "110";
    constant INSTRUCAO_DESVIO_INCONDICIONAL  : std_logic_vector(3 downto 0) := "1110";
    constant INSTRUCAO_SALTO_CONDICIONAL_RETORNO  : std_logic_vector(5 downto 1) := "11110";

    constant AND_OP  : std_logic_vector(2 downto 0) := "000";
    constant OR_OP   : std_logic_vector(2 downto 0) := "001";
    constant XOR_OP  : std_logic_vector(2 downto 0) := "010";
    constant MOV_OP  : std_logic_vector(2 downto 0) := "011";
    constant ADD_OP  : std_logic_vector(2 downto 0) := "100";
    constant ADDC_OP : std_logic_vector(2 downto 0) := "101";
    constant SUB_OP  : std_logic_vector(2 downto 0) := "110";
    constant SUBC_OP : std_logic_vector(2 downto 0) := "111";

    constant ANDI_OP  : std_logic_vector(2 downto 0) := "000";
    constant ORI_OP   : std_logic_vector(2 downto 0) := "001";
    constant XORI_OP  : std_logic_vector(2 downto 0) := "010";
    constant MOVI_OP  : std_logic_vector(2 downto 0) := "011";
    constant ADDI_OP  : std_logic_vector(2 downto 0) := "100";
    constant ADDCI_OP : std_logic_vector(2 downto 0) := "101";
    constant SUBI_OP  : std_logic_vector(2 downto 0) := "110";
    constant SUBCI_OP : std_logic_vector(2 downto 0) := "111";

    constant RL_OP   : std_logic_vector(2 downto 0) := "000";
    constant RR_OP   : std_logic_vector(2 downto 0) := "001";
    constant RLC_OP  : std_logic_vector(2 downto 0) := "010";
    constant RRC_OP  : std_logic_vector(2 downto 0) := "011";
    constant SLL_OP  : std_logic_vector(2 downto 0) := "100";
    constant SRL_OP  : std_logic_vector(2 downto 0) := "101";
    constant SRA_OP  : std_logic_vector(2 downto 0) := "110";
    constant NOT_OP  : std_logic_vector(2 downto 0) := "111";

    constant LDM_OP  : std_logic_vector(1 downto 0) := "00";
    constant STM_OP  : std_logic_vector(1 downto 0) := "01";
    constant INP_OP  : std_logic_vector(1 downto 0) := "10";
    constant OUT_OP  : std_logic_vector(1 downto 0) := "11";

    constant JMP_OP  : std_logic := '0';
    constant CALL_OP : std_logic := '1';

    constant SKIPC_OP : std_logic_vector(1 downto 0) := "00";
    constant SKIPZ_OP : std_logic_vector(1 downto 0) := "01";
    constant SKIPV_OP : std_logic_vector(1 downto 0) := "10";
    constant RET_OP   : std_logic_vector(1 downto 0) := "11";

    constant PERMANECE_COMO_ESTA : std_logic_vector(1 downto 0) := "00";
    constant CARREGA_UM_NOVO_VALOR : std_logic_vector(1 downto 0) := "01";
    constant CARREGA_VALOR_DO_TOPO_DA_PILHA : std_logic_vector(1 downto 0) := "10";
    constant INCREMENTA : std_logic_vector(1 downto 0) := "11";
begin

    process(nrst, clk)
    begin
        if nrst = '0' then
            pres_state <= rst;
        elsif rising_edge(clk) then
            pres_state <= next_state;
        end if;
    end process;

    process(nrst, rom_q, pres_state, c_flag_reg, z_flag_reg)
    begin
        reg_do_a_on_dext <= '0';
        reg_di_sel <= '0';
        alu_b_in_sel <= '0';
        reg_wr_ena <= '0';
        c_flag_wr_ena <= '0';
        z_flag_wr_ena <= '0';
        v_flag_wr_ena <= '0';
        alu_op <= "----";
        stack_push <= '0';
        stack_pop <= '0';
        pc_ctrl <= PERMANECE_COMO_ESTA;
        mem_wr_ena <= '0';
        mem_rd_ena <= '0';
        inp <= '0';
        outp <= '0';
        debug <= (others => '0');

        if pres_state = rst then
            next_state <= fetch_only;
            debug <= "00000000001";

        elsif pres_state = fetch_only then
            next_state <= fetch_dec_ex;
            pc_ctrl <= INCREMENTA;
            debug <= "00000000010";

        elsif pres_state = fetch_dec_ex then

            if rom_q(15 downto 11) = INSTRUCAO_SALTO_CONDICIONAL_RETORNO then
                if rom_q(10 downto 9) = SKIPC_OP then
                    if c_flag_reg = '1' then
                        pc_ctrl <= CARREGA_UM_NOVO_VALOR;
                        next_state <= fetch_only;
                        debug <= "00000000011";
                    else
                        pc_ctrl <= INCREMENTA;
                        next_state <= fetch_dec_ex;
                        debug <= "00000000100";
                    end if;

                elsif rom_q(10 downto 9) = SKIPZ_OP then
                    if z_flag_reg = '1' then
                        pc_ctrl <= CARREGA_UM_NOVO_VALOR;
                        next_state <= fetch_only;
                        debug <= "00000000101";
                    else
                        pc_ctrl <= INCREMENTA;
                        next_state <= fetch_dec_ex;
                        debug <= "00000000110";
                    end if;

                elsif rom_q(10 downto 9) = SKIPV_OP then
                    if v_flag_reg = '1' then
                        pc_ctrl <= CARREGA_UM_NOVO_VALOR;
                        next_state <= fetch_only;
                        debug <= "00000000111";
                    else
                        pc_ctrl <= INCREMENTA;
                        next_state <= fetch_dec_ex;
                        debug <= "00000001000";
                    end if;

                elsif rom_q(10 downto 9) = RET_OP then
                    stack_pop <= '1';
                    pc_ctrl <= CARREGA_VALOR_DO_TOPO_DA_PILHA;
                    next_state <= fetch_only;
                    debug <= "00000001001";

                else
                    next_state <= fetch_only;
                    debug <= "00000001010";
                end if;

            elsif rom_q(15 downto 12) = INSTRUCAO_DESVIO_INCONDICIONAL then
                if rom_q(11) = JMP_OP then
                    pc_ctrl <= CARREGA_UM_NOVO_VALOR;
                    next_state <= fetch_only;
                    debug <= "00000001100";

                elsif rom_q(11) = CALL_OP then
                    stack_push <= '1';
                    pc_ctrl <= CARREGA_UM_NOVO_VALOR;
                    next_state <= fetch_only;
                    debug <= "00000001101";

                else
                    next_state <= fetch_only;
                    debug <= "00000001110";
                end if;

            elsif rom_q(15 downto 13) = INSTRUCAO_MEMORIA_ES then
                if rom_q(12 downto 11) = LDM_OP then
                    mem_rd_ena <= '1';
                    reg_wr_ena <= '1';
                    pc_ctrl <= INCREMENTA;
                    next_state <= fetch_dec_ex;
                    debug <= "00000010000";

                elsif rom_q(12 downto 11) = STM_OP then
                    mem_wr_ena <= '1';
                    reg_do_a_on_dext <= '1';
                    pc_ctrl <= INCREMENTA;
                    next_state <= fetch_dec_ex;
                    debug <= "00000010001";

                elsif rom_q(12 downto 11) = INP_OP then
                    inp <= '1';
                    reg_wr_ena <= '1';
                    pc_ctrl <= INCREMENTA;
                    next_state <= fetch_dec_ex;
                    debug <= "00000010010";

                elsif rom_q(12 downto 11) = OUT_OP then
                    outp <= '1';
                    reg_do_a_on_dext <= '1';
                    pc_ctrl <= INCREMENTA;
                    next_state <= fetch_dec_ex;
                    debug <= "00000010011";

                else
                    next_state <= fetch_only;
                    debug <= "00000010100";
                end if;

            elsif rom_q(15 downto 14) = INSTRUCAO_REG_REG then
                if rom_q(13 downto 11) = AND_OP then
                    alu_op <= "0" & AND_OP;
                    reg_wr_ena <= '1';
                    alu_b_in_sel <= '1';
                    reg_di_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '0';
                    v_flag_wr_ena <= '0';
                    next_state <= fetch_dec_ex;
                    debug <= "00000010110";

                elsif rom_q(13 downto 11) = OR_OP then
                    alu_op <= "0" & OR_OP;
                    reg_wr_ena <= '1';
                    alu_b_in_sel <= '1';
                    reg_di_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '0';
                    v_flag_wr_ena <= '0';
                    next_state <= fetch_dec_ex;
                    debug <= "00000010111";

                elsif rom_q(13 downto 11) = XOR_OP then
                    alu_op <= "0" & XOR_OP;
                    reg_wr_ena <= '1';
                    alu_b_in_sel <= '1';
                    reg_di_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '0';
                    v_flag_wr_ena <= '0';
                    next_state <= fetch_dec_ex;
                    debug <= "00000011000";

                elsif rom_q(13 downto 11) = MOV_OP then
                    alu_op <= "1111";
                    reg_wr_ena <= '1';
                    reg_di_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '0';
                    v_flag_wr_ena <= '0';
                    next_state <= fetch_dec_ex;
                    debug <= "00000011001";

                elsif rom_q(13 downto 11) = ADD_OP then
                    alu_op <= "0" & ADD_OP;
                    reg_wr_ena <= '1';
                    alu_b_in_sel <= '1';
                    reg_di_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '1';
                    v_flag_wr_ena <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000011010";

                elsif rom_q(13 downto 11) = ADDC_OP then
                    alu_op <= "0" & ADDC_OP;
                    reg_wr_ena <= '1';
                    alu_b_in_sel <= '1';
                    reg_di_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '1';
                    v_flag_wr_ena <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000011011";

                elsif rom_q(13 downto 11) = SUB_OP then
                    alu_op <= "0" & SUB_OP;
                    reg_wr_ena <= '1';
                    alu_b_in_sel <= '1';
                    reg_di_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '1';
                    v_flag_wr_ena <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000011100";

                elsif rom_q(13 downto 11) = SUBC_OP then
                    alu_op <= "0" & SUBC_OP;
                    reg_wr_ena <= '1';
                    alu_b_in_sel <= '1';
                    reg_di_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '1';
                    v_flag_wr_ena <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000011101";

                else
                    next_state <= fetch_only;
                    debug <= "00000011110";
                end if;

            elsif rom_q(15 downto 14) = INSTRUCAO_REG_IMMED then
                if rom_q(13 downto 11) = ANDI_OP then
                    alu_op <= "0" & ANDI_OP;
                    reg_wr_ena <= '1';
                    reg_di_sel <= '1';
                    alu_b_in_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '0';
                    v_flag_wr_ena <= '0';
                    next_state <= fetch_dec_ex;
                    debug <= "00000011111";

                elsif rom_q(13 downto 11) = ORI_OP then
                    alu_op <= "0" & ORI_OP;
                    reg_wr_ena <= '1';
                    reg_di_sel <= '1';
                    alu_b_in_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '0';
                    v_flag_wr_ena <= '0';
                    next_state <= fetch_dec_ex;
                    debug <= "00000100000";

                elsif rom_q(13 downto 11) = XORI_OP then
                    alu_op <= "0" & XORI_OP;
                    reg_wr_ena <= '1';
                    reg_di_sel <= '1';
                    alu_b_in_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '0';
                    v_flag_wr_ena <= '0';
                    next_state <= fetch_dec_ex;
                    debug <= "00000100001";

                elsif rom_q(13 downto 11) = MOVI_OP then
                    alu_op <= "1111";
                    reg_wr_ena <= '1';
                    reg_di_sel <= '1';
                    c_flag_wr_ena <= '1';
                    alu_b_in_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    next_state <= fetch_dec_ex;
                    debug <= "00000100010";

                elsif rom_q(13 downto 11) = ADDI_OP then
                    alu_op <= "0" & ADDI_OP;
                    reg_wr_ena <= '1';
                    reg_di_sel <= '1';
                    alu_b_in_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '1';
                    v_flag_wr_ena <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000100011";

                elsif rom_q(13 downto 11) = ADDCI_OP then
                    alu_op <= "0" & ADDCI_OP;
                    reg_wr_ena <= '1';
                    reg_di_sel <= '1';
                    alu_b_in_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '1';
                    v_flag_wr_ena <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000100100";

                elsif rom_q(13 downto 11) = SUBI_OP then
                    alu_op <= "0" & SUBI_OP;
                    reg_wr_ena <= '1';
                    reg_di_sel <= '1';
                    alu_b_in_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '1';
                    v_flag_wr_ena <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000100101";

                elsif rom_q(13 downto 11) = SUBCI_OP then
                    alu_op <= "0" & SUBCI_OP;
                    reg_wr_ena <= '1';
                    reg_di_sel <= '1';
                    alu_b_in_sel <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    c_flag_wr_ena <= '1';
                    v_flag_wr_ena <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000100110";

                else
                    next_state <= fetch_only;
                    debug <= "00000100111";
                end if;

            elsif rom_q(15 downto 14) = INSTRUCAO_ALU_1_REG then
                if rom_q(13 downto 11) = RL_OP then
                    alu_op <= "1" & RL_OP;
                    reg_wr_ena <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    reg_di_sel <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000101000";

                elsif rom_q(13 downto 11) = RR_OP then
                    alu_op <= "1" & RR_OP;
                    reg_wr_ena <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    reg_di_sel <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000101001";

                elsif rom_q(13 downto 11) = RLC_OP then
                    alu_op <= "1" & RLC_OP;
                    reg_wr_ena <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    reg_di_sel <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000101010";

                elsif rom_q(13 downto 11) = RRC_OP then
                    alu_op <= "1" & RRC_OP;
                    reg_wr_ena <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    reg_di_sel <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000101011";

                elsif rom_q(13 downto 11) = SLL_OP then
                    alu_op <= "1" & SLL_OP;
                    reg_wr_ena <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    reg_di_sel <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000101100";

                elsif rom_q(13 downto 11) = SRL_OP then
                    alu_op <= "1" & SRL_OP;
                    reg_wr_ena <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    reg_di_sel <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000101101";

                elsif rom_q(13 downto 11) = SRA_OP then
                    alu_op <= "1" & SRA_OP;
                    reg_wr_ena <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    reg_di_sel <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000101110";

                elsif rom_q(13 downto 11) = NOT_OP then
                    alu_op <= "1" & NOT_OP;
                    reg_wr_ena <= '1';
                    pc_ctrl <= INCREMENTA;
                    z_flag_wr_ena <= '1';
                    reg_di_sel <= '1';
                    next_state <= fetch_dec_ex;
                    debug <= "00000101111";

                else
                    next_state <= fetch_only;
                    debug <= "00000110000";
                end if;

            else
                next_state <= fetch_only;
                debug <= "00000110001";
            end if;

        else
            next_state <= fetch_only;
            debug <= "00000110010";
        end if;
    end process;

end Behavioral;
