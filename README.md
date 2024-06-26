### README para Projetos de Sistemas Reconfiguráveis

#### Introdução
Este repositório contém uma série de projetos desenvolvidos para o curso de Sistemas Reconfiguráveis no programa de Engenharia de Computação. Cada projeto foca no design, implementação e simulação de vários sistemas digitais utilizando VHDL. Os projetos foram realizados utilizando o Quartus II versão 9.1sp2.

#### Visão Geral dos Projetos

1. **Projeto 1: Unidade Lógica e Aritmética (ALU)**
    - **Objetivo:** Projetar, implementar e simular uma ALU de 8 bits capaz de realizar 16 operações diferentes, incluindo operações lógicas, aritméticas, de rotação e deslocamento.
    - **Detalhes:**
        - Circuito combinacional.
        - Entradas: `a_in[7..0]`, `b_in[7..0]`, `c_in`, `op_sel[3..0]`.
        - Saídas: `r_out[7..0]`, `c_out`, `z_out`, `v_out`.
        - Operações: AND, OR, XOR, NOT, ADD, ADDC, SUB, SUBC, RL, RR, RLC, RRC, SLL, SRL, SRA, PASS_B.
    - **Entrega:** Relatório em formato ABNT e arquivos do projeto em formato .zip ou .rar.

2. **Projeto 2: Banco de Registradores, Pilha e Contador**
    - **Objetivo:** Projetar, implementar e simular três módulos independentes: banco de registradores (`reg_bank`), pilha (`stack`) e contador programável (`prog_cnt`).
    - **Detalhes:**
        - Banco de Registradores: 8 registradores de 8 bits, incluindo flags de status (C, Z, V).
        - Pilha: Conjunto de 8 registradores de 11 bits.
        - Contador: Contador síncrono de módulo 2048 com reset assíncrono e carregamento síncrono.
    - **Entrega:** Relatório em formato ABNT e arquivos do projeto em formato .zip ou .rar.

3. **Projeto 3: Periféricos para Microcontrolador**
    - **Objetivo:** Projetar, implementar e simular dois periféricos para microcontrolador: porta de entrada/saída (`port_io`) e memória RAM (`ram_256x8`).
    - **Detalhes:**
        - Porta de Entrada/Saída: Interfaceamento com sensores e atuadores digitais.
        - Memória RAM: Memória RAM de 256 bytes.
    - **Entrega:** Relatório em formato ABNT e arquivos do projeto em formato .zip ou .rar.

4. **Projeto 4: Microcontrolador PUC-241**
    - **Objetivo:** Implementar o microcontrolador PUC-241 utilizando os módulos desenvolvidos nos trabalhos anteriores e complementando com blocos adicionais.
    - **Detalhes:**
        - Arquitetura Harvard com memórias separadas para instruções e dados.
        - Programa de teste para acionar LEDs sequencialmente.
    - **Entrega:** Arquivos do projeto em formato .zip ou .rar, incluindo o programa de teste.

#### Estrutura do Repositório
- `Trab1/`: Arquivos relacionados ao Projeto 1.
- `Trab2/`: Arquivos relacionados ao Projeto 2.
- `Trab3/`: Arquivos relacionados ao Projeto 3.
- `Trab4/`: Arquivos relacionados ao Projeto 4.
- `README.md`: Este arquivo README.

#### Instruções de Uso
1. **Configuração do Ambiente:**
    - Baixe e instale o Quartus II versão 9.1sp2.
    - Extraia os arquivos de cada projeto na pasta correspondente.

2. **Compilação e Simulação:**
    - Abra o Quartus II e carregue o projeto desejado.
    - Compile o projeto e execute as simulações conforme descrito nos relatórios.

3. **Envio:**
    - Certifique-se de que todos os arquivos do projeto e os relatórios estão incluídos na pasta correspondente.
    - Compacte a pasta em um arquivo .zip ou .rar para envio.

#### Autores
- Philipi Gariglio Carvalho Faustino Altoé
- Izabela Galinari

#### Instituição
- Pontifícia Universidade Católica de Minas Gerais
- Faculdade de Engenharia de Computação