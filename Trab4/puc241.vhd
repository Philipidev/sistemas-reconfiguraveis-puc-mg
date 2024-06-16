-- Importação das bibliotecas IEEE necessárias para o design
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;   -- Tipos e operações lógicas padrão
use IEEE.STD_LOGIC_ARITH.ALL;  -- Operações aritméticas (opcional)
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- Operações aritméticas para vetores std_logic

-- Declaração da entidade do microcontrolador PUC-241
entity puc241 is
    Port (
        clk : in std_logic;                     -- Sinal de clock de entrada
        reset : in std_logic;                   -- Sinal de reset de entrada
        port_A : out std_logic_vector(7 downto 0); -- Porta de saída A (conectada aos LEDs)
        port_B : in std_logic_vector(7 downto 0)   -- Porta de entrada B (conectada às chaves)
    );
end puc241;

-- Arquitetura do design, descrevendo o comportamento do circuito
architecture Behavioral of puc241 is
    -- Declaração dos sinais internos
    signal counter : integer := 0; -- Contador usado para criar o delay de 1 décimo de segundo
    signal led_sequence : std_logic_vector(7 downto 0) := "00000001"; -- Sequência de LEDs inicial
    signal direction : std_logic := '0'; -- Direção inicial da sequência (0: esquerda para direita, 1: direita para esquerda)
begin
    -- Processo principal que é sensível ao clock e ao reset
    process(clk, reset)
    begin
        -- Verificação do sinal de reset
        if reset = '1' then
            port_A <= (others => '0'); -- Reseta a porta de saída A (desliga todos os LEDs)
            counter <= 0; -- Reseta o contador
            led_sequence <= "00000001"; -- Reseta a sequência de LEDs para o valor inicial
            direction <= '0'; -- Reseta a direção para esquerda para direita
        -- Verificação da borda de subida do clock
        elsif rising_edge(clk) then
            -- Verificação se o contador atingiu o valor para 1 décimo de segundo
            if counter = 10000000 then -- Este valor deve ser ajustado conforme a frequência do clock
                counter <= 0; -- Reseta o contador

                -- Verificação do bit 0 da porta de entrada B para alterar a direção
                if port_B(0) = '1' then
                    direction <= not direction; -- Alterna a direção
                end if;

                -- Atualização da sequência de LEDs conforme a direção
                if direction = '0' then
                    -- Desloca a sequência de LEDs para a esquerda
                    led_sequence <= led_sequence(6 downto 0) & led_sequence(7);
                else
                    -- Desloca a sequência de LEDs para a direita
                    led_sequence <= led_sequence(0) & led_sequence(7 downto 1);
                end if;

                -- Atualiza a porta de saída A com a nova sequência de LEDs
                port_A <= led_sequence;
            else
                counter <= counter + 1; -- Incrementa o contador
            end if;
        end if;
    end process;
end Behavioral;
