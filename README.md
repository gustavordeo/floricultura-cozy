# Floricultura Cozy

Jogo de navegador em pixel art, no estilo cozy, sobre cuidar de uma floricultura. A inspiração é o Colheita Feliz: você planta, rega, espera crescer, colhe e vende.

## Como jogar

Abra o `index.html` no navegador. Não precisa instalar nada.

1. Escolha uma semente na barra de baixo e clique num canteiro para plantar.
2. Pegue o regador e clique nas plantas com sede (a gotinha azul em cima do canteiro). Elas só crescem com a terra molhada.
3. Quando a planta florescer e começar a brilhar, clique nela para colher e vender.
4. Use as moedas para comprar mais sementes e abrir canteiros novos (as plaquinhas de madeira).

Atalhos: teclas 1 a 5 escolhem a semente ou a ferramenta.

O progresso fica salvo no navegador, e o jardim continua crescendo por até 1 hora com o jogo fechado (desde que a terra esteja molhada).

## As plantas

| Planta | Estilo | Semente | Venda | Jeito de cuidar |
| --- | --- | --- | --- | --- |
| Violeta | Delicada | 5 | 14 | Cresce rápido, mas regar com a terra ainda molhada encharca e ela para de crescer por um tempo. |
| Rosa | Romântica | 15 | 40 | Vale mais, mas a terra seca rápido. Precisa de rega frequente. |
| Costela de adão | Tropical | 30 | 22 | Lenta, aguenta 1 minuto sem água e rebrota depois de cada colheita (renda passiva). |

Os tempos estão curtos de propósito para testar. Eles ficam no objeto `PLANTAS` em `src/game.js`.

## Estrutura

- `index.html` e `style.css`: a página e a interface (moedas, ferramentas, mensagens).
- `src/sprites.js`: toda a pixel art, desenhada como texto (cada letra é um pixel de uma cor da paleta). O contorno escuro é gerado automaticamente.
- `src/game.js`: estado, simulação do crescimento, desenho no canvas e animações.

A animação em loop das plantas é um balanço: as linhas de cima do sprite se deslocam 1 pixel para os lados num ciclo de 4 quadros, e cada canteiro começa numa fase diferente para o jardim não balançar todo junto.

## Próximos passos

- Pedidos de clientes (buquês com combinações de flores).
- Vitrine da loja para decorar.
- Estações do ano e flores raras por cruzamento.
- Migrar para Phaser quando o jogo crescer (cenas, câmera, sons).

## Publicar online

Em Settings > Pages do repositório, escolha "Deploy from a branch", branch `main` e pasta `/ (root)`. O jogo fica em `https://gustavordeo.github.io/floricultura-cozy/`.
