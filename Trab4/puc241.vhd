-- Importa��o das bibliotecas IEEE necess�rias para o design
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;   -- Tipos e opera��es l�gicas padr�o
use IEEE.STD_LOGIC_ARITH.ALL;  -- Opera��es aritm�ticas (opcional)
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- Opera��es aritm�ticas para vetores std_logic

-- Declara��o da entidade do microcontrolador PUC-241
entity puc241 is
    Port (
        clk : in std_logic;                     -- Sinal de clock de entrada
        reset : in std_logic;                   -- Sinal de reset de entrada
        port_A : out std_logic_vector(7 downto 0); -- Porta de sa�da A (conectada aos LEDs)
        port_B : in std_logic_vector(7 downto 0)   -- Porta de entrada B (conectada �s chaves)
    );
end puc241;

-- Arquitetura do design, descrevendo o comportamento do circuito
architecture Behavioral of puc241 is
    -- Declara��o dos sinais internos
    signal counter : integer := 0; -- Contador usado para criar o delay de 1 d�cimo de segundo
    signal led_sequence : std_logic_vector(7 downto 0) := "00000001"; -- Sequ�ncia de LEDs inicial
    signal direction : std_logic := '0'; -- Dire��o inicial da sequ�ncia (0: esquerda para direita, 1: direita para esquerda)
begin
    -- Processo principal que � sens�vel ao clock e ao reset
    process(clk, reset)
    begin
        -- Verifica��o do sinal de reset
        if reset = '1' then
            port_A <= (others => '0'); -- Reseta a porta de sa�da A (desliga todos os LEDs)
            counter <= 0; -- Reseta o contador
            led_sequence <= "00000001"; -- Reseta a sequ�ncia de LEDs para o valor inicial
            direction <= '0'; -- Reseta a dire��o para esquerda para direita
        -- Verifica��o da borda de subida do clock
        elsif rising_edge(clk) then
            -- Verifica��o se o contador atingiu o valor para 1 d�cimo de segundo
            if counter = 10000000 then -- Este valor deve ser ajustado conforme a frequ�ncia do clock
                counter <= 0; -- Reseta o contador

                -- Verifica��o do bit 0 da porta de entrada B para alterar a dire��o
                if port_B(0) = '1' then
                    direction <= not direction; -- Alterna a dire��o
                end if;

                -- Atualiza��o da sequ�ncia de LEDs conforme a dire��o
                if direction = '0' then
                    -- Desloca a sequ�ncia de LEDs para a esquerda
                    led_sequence <= led_sequence(6 downto 0) & led_sequence(7);
                else
                    -- Desloca a sequ�ncia de LEDs para a direita
                    led_sequence <= led_sequence(0) & led_sequence(7 downto 1);
                end if;

                -- Atualiza a porta de sa�da A com a nova sequ�ncia de LEDs
                port_A <= led_sequence;
            else
                counter <= counter + 1; -- Incrementa o contador
            end if;
        end if;
    end process;
end Behavioral;
