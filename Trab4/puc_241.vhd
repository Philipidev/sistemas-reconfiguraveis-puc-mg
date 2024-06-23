library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity puc_241 is
    Port (
        -- Sinais de controle e clock
        nrst : in std_logic;                    -- Sinal de reset negativo
        clk : in std_logic;                     -- Sinal de clock de entrada

        -- Sinais de entrada
        rom_q : in std_logic_vector(15 downto 0); -- Sinal de saída da ROM

        -- Sinais de flags
        c_flag_reg : in std_logic;
        z_flag_reg : in std_logic;
        v_flag_reg : in std_logic;

        -- Sinais de saída de controle
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
    -- Definição dos estados da FSM
    type state_type is (rst, fetch_only, fetch_dec_ex);
    signal pres_state, next_state : state_type;
    signal instrucao : std_logic_vector(15 downto 0);
    signal RA, RB : std_logic_vector(2 downto 0);
    signal op_code : std_logic_vector(2 downto 0);
    signal imm_value : std_logic_vector(7 downto 0);

    -- Definição das operações
    constant INSTRUCAO_REG_REG  : std_logic_vector(1 downto 0) := "00";
    constant INSTRUCAO_REG_IMMED  : std_logic_vector(1 downto 0) := "01";
    constant INSTRUCAO_ALU_1_REG  : std_logic_vector(1 downto 0) := "10";
    constant INSTRUCAO_MEMORIA_ES  : std_logic_vector(2 downto 0) := "110";
    constant INSTRUCAO_DESVIO_INCONDICIONAL  : std_logic_vector(3 downto 0) := "1110";
    constant INSTRUCAO_SALTO_CONDICIONAL_RETORNO  : std_logic_vector(5 downto 1) := "11110";

    -- Instruções Reg-Reg
    constant AND_OP  : std_logic_vector(2 downto 0) := "000";
    constant OR_OP   : std_logic_vector(2 downto 0) := "001";
    constant XOR_OP  : std_logic_vector(2 downto 0) := "010";
    constant MOV_OP  : std_logic_vector(2 downto 0) := "011";
    constant ADD_OP  : std_logic_vector(2 downto 0) := "100";
    constant ADDC_OP : std_logic_vector(2 downto 0) := "101";
    constant SUB_OP  : std_logic_vector(2 downto 0) := "110";
    constant SUBC_OP : std_logic_vector(2 downto 0) := "111";

    -- Instruções Reg-Immed
    constant ANDI_OP  : std_logic_vector(2 downto 0) := "000";
    constant ORI_OP   : std_logic_vector(2 downto 0) := "001";
    constant XORI_OP  : std_logic_vector(2 downto 0) := "010";
    constant MOVI_OP  : std_logic_vector(2 downto 0) := "011";
    constant ADDI_OP  : std_logic_vector(2 downto 0) := "100";
    constant ADDCI_OP : std_logic_vector(2 downto 0) := "101";
    constant SUBI_OP  : std_logic_vector(2 downto 0) := "110";
    constant SUBCI_OP : std_logic_vector(2 downto 0) := "111";

    -- Instruções ALU-1 Reg
    constant RL_OP   : std_logic_vector(2 downto 0) := "000";
    constant RR_OP   : std_logic_vector(2 downto 0) := "001";
    constant RLC_OP  : std_logic_vector(2 downto 0) := "010";
    constant RRC_OP  : std_logic_vector(2 downto 0) := "011";
    constant SLL_OP  : std_logic_vector(2 downto 0) := "100";
    constant SRL_OP  : std_logic_vector(2 downto 0) := "101";
    constant SRA_OP  : std_logic_vector(2 downto 0) := "110";
    constant NOT_OP  : std_logic_vector(2 downto 0) := "111";

    -- Instruções de memória e E/S
    constant LDM_OP  : std_logic_vector(1 downto 0) := "00";
    constant STM_OP  : std_logic_vector(1 downto 0) := "01";
    constant INP_OP  : std_logic_vector(1 downto 0) := "10";
    constant OUT_OP  : std_logic_vector(1 downto 0) := "11";

    -- Instruções de desvio incondicional e chamada de sub-rotina
    constant JMP_OP  : std_logic := '0';
    constant CALL_OP : std_logic := '1';

    -- Instruções de salto condicional e retorno
    constant SKIPC_OP : std_logic_vector(1 downto 0) := "00";
    constant SKIPZ_OP : std_logic_vector(1 downto 0) := "01";
    constant SKIPV_OP : std_logic_vector(1 downto 0) := "10";
    constant RET_OP   : std_logic_vector(1 downto 0) := "11";

    -- Instruções do Prog_cnt
    constant PERMANECE_COMO_ESTA : std_logic_vector(1 downto 0) := "00";
    constant CARREGA_UM_NOVO_VALOR : std_logic_vector(1 downto 0) := "01";
    constant CARREGA_VALOR_DO_TOPO_DA_PILHA : std_logic_vector(1 downto 0) := "10";
    constant INCREMENTA : std_logic_vector(1 downto 0) := "11";

    -- Sinais de controle internos
    signal alu_op_code : std_logic_vector(2 downto 0);
    signal alu_op_type : std_logic_vector(1 downto 0);
    signal mem_addr : std_logic_vector(3 downto 0);

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
        -- Inicializando os valores
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

        case pres_state is
            -- Reset
            when rst =>
                next_state <= fetch_only;

            -- Fetch only
            when fetch_only =>
                next_state <= fetch_dec_ex;
                reg_wr_ena <= '1';
                pc_ctrl <= INCREMENTA; -- Incrementa PC

            -- Fetch, Decode and Execute
            when fetch_dec_ex =>
                instrucao <= rom_q;
                case rom_q(15 downto 14) is
                    when INSTRUCAO_REG_REG => -- Instruções Reg-Reg
                        case rom_q(13 downto 11) is
                            when AND_OP => 
                                alu_op <= "0" & AND_OP;
                                reg_wr_ena <= '1';
                                alu_b_in_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '0';
                                v_flag_wr_ena <= '0';
                                next_state <= fetch_dec_ex;

                            when OR_OP => 
                                alu_op <= "0" & OR_OP;
                                reg_wr_ena <= '1';
                                alu_b_in_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '0';
                                v_flag_wr_ena <= '0';
                                next_state <= fetch_dec_ex;

                            when XOR_OP => 
                                alu_op <= "0" & XOR_OP;
                                reg_wr_ena <= '1';
                                alu_b_in_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '0';
                                v_flag_wr_ena <= '0';
                                next_state <= fetch_dec_ex;

                            when MOV_OP => 
                                alu_op <= "1111";
                                reg_wr_ena <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '0';
                                v_flag_wr_ena <= '0';
                                next_state <= fetch_dec_ex;

                            when ADD_OP => 
                                alu_op <= "0" & ADD_OP;
                                reg_wr_ena <= '1';
                                alu_b_in_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '1';
                                v_flag_wr_ena <= '1';
                                next_state <= fetch_dec_ex;

                            when ADDC_OP => 
                                alu_op <= "0" & ADDC_OP;
                                reg_wr_ena <= '1';
                                alu_b_in_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '1';
                                v_flag_wr_ena <= '1';
                                next_state <= fetch_dec_ex;

                            when SUB_OP => 
                                alu_op <= "0" & SUB_OP;
                                reg_wr_ena <= '1';
                                alu_b_in_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '1';
                                v_flag_wr_ena <= '1';
                                next_state <= fetch_dec_ex;

                            when SUBC_OP => 
                                alu_op <= "0" & SUBC_OP;
                                reg_wr_ena <= '1';
                                alu_b_in_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '1';
                                v_flag_wr_ena <= '1';
                                next_state <= fetch_dec_ex;

                            when others =>
                                next_state <= fetch_only;
                        end case;

                    when INSTRUCAO_REG_IMMED => -- Instruções Reg-Immed
                        case rom_q(13 downto 11) is
                            when ANDI_OP => 
                                alu_op <= "0" & ANDI_OP;
                                reg_wr_ena <= '1';
                                reg_di_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '0';
                                v_flag_wr_ena <= '0';
                                next_state <= fetch_dec_ex;

                            when ORI_OP => 
                                alu_op <= "0" & ORI_OP;
                                reg_wr_ena <= '1';
                                reg_di_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '0';
                                v_flag_wr_ena <= '0';
                                next_state <= fetch_dec_ex;

                            when XORI_OP => 
                                alu_op <= "0" & XORI_OP;
                                reg_wr_ena <= '1';
                                reg_di_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '0';
                                v_flag_wr_ena <= '0';
                                next_state <= fetch_dec_ex;

                            when MOVI_OP => 
                                alu_op <= "1111";
                                reg_wr_ena <= '1';
                                reg_di_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '0';
                                v_flag_wr_ena <= '0';
                                next_state <= fetch_dec_ex;

                            when ADDI_OP => 
                                alu_op <= "0" & ADDI_OP;
                                reg_wr_ena <= '1';
                                reg_di_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '1';
                                v_flag_wr_ena <= '1';
                                next_state <= fetch_dec_ex;

                            when ADDCI_OP => 
                                alu_op <= "0" & ADDCI_OP;
                                reg_wr_ena <= '1';
                                reg_di_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '1';
                                v_flag_wr_ena <= '1';
                                next_state <= fetch_dec_ex;

                            when SUBI_OP => 
                                alu_op <= "0" & SUBI_OP;
                                reg_wr_ena <= '1';
                                reg_di_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '1';
                                v_flag_wr_ena <= '1';
                                next_state <= fetch_dec_ex;

                            when SUBCI_OP => 
                                alu_op <= "0" & SUBCI_OP;
                                reg_wr_ena <= '1';
                                reg_di_sel <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '1';
                                v_flag_wr_ena <= '1';
                                next_state <= fetch_dec_ex;

                            when others =>
                                next_state <= fetch_only;
                        end case;

                    when INSTRUCAO_ALU_1_REG => -- Instruções ALU-1 Reg
                        case rom_q(13 downto 11) is
                            when RL_OP => 
                                alu_op <= "1" & RL_OP;
                                reg_wr_ena <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                -- Atualizar c_flag_wr_ena com base na saída do deslocamento
                                next_state <= fetch_dec_ex;

                            when RR_OP => 
                                alu_op <= "1" & RR_OP;
                                reg_wr_ena <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                -- Atualizar c_flag_wr_ena com base na saída do deslocamento
                                next_state <= fetch_dec_ex;

                            when RLC_OP => 
                                alu_op <= "1" & RLC_OP;
                                reg_wr_ena <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                -- Atualizar c_flag_wr_ena com base na saída do deslocamento
                                next_state <= fetch_dec_ex;

                            when RRC_OP => 
                                alu_op <= "1" & RRC_OP;
                                reg_wr_ena <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                -- Atualizar c_flag_wr_ena com base na saída do deslocamento
                                next_state <= fetch_dec_ex;

                            when SLL_OP => 
                                alu_op <= "1" & SLL_OP;
                                reg_wr_ena <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                -- Atualizar c_flag_wr_ena com base na saída do deslocamento
                                next_state <= fetch_dec_ex;

                            when SRL_OP => 
                                alu_op <= "1" & SRL_OP;
                                reg_wr_ena <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                -- Atualizar c_flag_wr_ena com base na saída do deslocamento
                                next_state <= fetch_dec_ex;

                            when SRA_OP => 
                                alu_op <= "1" & SRA_OP;
                                reg_wr_ena <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                -- Atualizar c_flag_wr_ena com base na saída do deslocamento
                                next_state <= fetch_dec_ex;

                            when NOT_OP => 
                                alu_op <= "1" & NOT_OP;
                                reg_wr_ena <= '1';
                                pc_ctrl <= INCREMENTA;
                                z_flag_wr_ena <= '1';
                                c_flag_wr_ena <= '0';
                                next_state <= fetch_dec_ex;

                            when others =>
                                next_state <= fetch_only;
                        end case;

                    when others =>
                        next_state <= fetch_only;
                end case;

                case rom_q(15 downto 13) is
                    when INSTRUCAO_MEMORIA_ES => -- Instruções de memória e E/S
                        case rom_q(12 downto 11) is
                            when LDM_OP =>
                                mem_rd_ena <= '1';
                                reg_wr_ena <= '1';
                                pc_ctrl <= INCREMENTA;
                                next_state <= fetch_dec_ex;

                            when STM_OP =>
                                mem_wr_ena <= '1';
                                reg_do_a_on_dext <= '1';
                                pc_ctrl <= INCREMENTA;
                                next_state <= fetch_dec_ex;

                            when INP_OP =>
                                inp <= '1';
                                reg_wr_ena <= '1';
                                pc_ctrl <= INCREMENTA;
                                next_state <= fetch_dec_ex;

                            when OUT_OP =>
                                outp <= '1';
                                reg_do_a_on_dext <= '1';
                                pc_ctrl <= INCREMENTA;
                                next_state <= fetch_dec_ex;

                            when others =>
                                next_state <= fetch_only;
                        end case;
                        when others =>
                            next_state <= fetch_only;    
                    end case;

                case rom_q(15 downto 12) is
                    when INSTRUCAO_DESVIO_INCONDICIONAL => -- Instruções de Desvio Incondicional e Chamada de Sub-Rotina
                        case rom_q(11) is
                            when JMP_OP => -- JMP
                                pc_ctrl <= CARREGA_UM_NOVO_VALOR; -- Carregar novo valor no PC
                                next_state <= fetch_only;

                            when CALL_OP => -- CALL
                                stack_push <= '1';
                                pc_ctrl <= CARREGA_UM_NOVO_VALOR; -- Carregar novo valor no PC
                                next_state <= fetch_only;

                            when others =>
                                next_state <= fetch_only;
                        end case;
                        when others =>
                            next_state <= fetch_only;
                    end case;

                case rom_q(15 downto 11) is
                    when INSTRUCAO_SALTO_CONDICIONAL_RETORNO => -- Instruções de Salto Condicional e Retorno
                        case rom_q(10 downto 9) is
                            when SKIPC_OP =>
                                if c_flag_reg = '1' then
                                    pc_ctrl <= CARREGA_UM_NOVO_VALOR; -- Carregar novo valor no PC
									next_state <= fetch_only;
                                else
                                    pc_ctrl <= INCREMENTA; -- Incrementar PC
									next_state <= fetch_dec_ex;
                                end if;
                                next_state <= fetch_only;

                            when SKIPZ_OP =>
                                if z_flag_reg = '1' then
                                    pc_ctrl <= CARREGA_UM_NOVO_VALOR; -- Carregar novo valor no PC
									next_state <= fetch_only;
                                else
                                    pc_ctrl <= INCREMENTA; -- Incrementar PC
									next_state <= fetch_dec_ex;
                                end if;
                                next_state <= fetch_only;

                            when SKIPV_OP =>
                                if v_flag_reg = '1' then
                                    pc_ctrl <= CARREGA_UM_NOVO_VALOR; -- Carregar novo valor no PC
									next_state <= fetch_only;
                                else
                                    pc_ctrl <= INCREMENTA; -- Incrementar PC
									next_state <= fetch_dec_ex;
                                end if;
                                next_state <= fetch_only;

                            when RET_OP =>
                                stack_pop <= '1';
                                pc_ctrl <= CARREGA_VALOR_DO_TOPO_DA_PILHA; -- Carregar valor do topo da pilha
                                next_state <= fetch_only;

                            when others =>
                                next_state <= fetch_only;
                        end case;

                    when others =>
                        next_state <= fetch_only;
                end case;

            when others =>
                next_state <= fetch_only;
        end case;
    end process;

end Behavioral;
