# Floricultura Cozy

Jogo de navegador em pixel art, no estilo cozy, sobre decorar ambientes com plantas. Você começa com uma sala vazia, escolhe onde colocar cada vaso, cuida das plantas e deixa o lugar cada vez mais aconchegante.

## Como jogar

Abra o `index.html` no navegador. Não precisa instalar nada.

1. Escolha uma planta e clique num espaço com **+** na sala. Ela vai num vaso do tipo selecionado.
2. Pegue o regador e clique nas plantas com sede (a gotinha azul). Elas só crescem com a terra molhada.
3. Quando a planta adulta brilhar, clique para colher flores ou separar uma muda, e ganhar moedas.
4. Troque vasos para deixar a sala mais bonita: escolha um vaso e clique num vaso da sala.

O **aconchego** (coração no topo) sobe com plantas crescidas, plantas felizes com a luz e vasos bonitos.

Atalhos: teclas 1 a 8 escolhem plantas, vasos e cuidados.

O progresso fica salvo no navegador, e as plantas continuam crescendo por até 1 hora com o jogo fechado (desde que a terra esteja molhada).

## Luz

Cada ponto da sala tem uma luz, e cada planta prefere uma. Na luz errada ela cresce bem mais devagar.

| Ponto | Luz |
| --- | --- |
| Parapeito da janela, chão perto da janela | Sol direto |
| Prateleira, mesinha ao lado do sofá | Meia-luz |
| Rack da TV, canto perto da TV | Sombra |

| Planta | Preço | Gosta de | Jeito de cuidar |
| --- | --- | --- | --- |
| Violeta | 10 | Meia-luz | Sol direto queima. Regar com a terra ainda molhada encharca e ela para de crescer por um tempo. |
| Rosa | 20 | Sol direto | A terra seca rápido, precisa de rega frequente. Dá as flores mais valiosas. |
| Costela de adão | 30 | Meia-luz ou sombra | Tranquila, fica um minuto sem água. |

Os tempos estão curtos de propósito para testar. Eles ficam no objeto `PLANTAS` em `src/game.js`, e os pontos da sala em `PONTOS`.

## Estrutura

- `index.html` e `style.css`: a página e a interface (contadores, botões, mensagens).
- `src/sprites.js`: a pixel art das plantas, vasos, gato e ícones, desenhada como texto (cada letra é um pixel de uma cor da paleta). O contorno escuro é gerado automaticamente.
- `src/sala.js`: o cenário da sala (parede, janela, sofá, TV, prateleira, tapete) e a luz do sol.
- `src/game.js`: estado, crescimento, desenho no canvas e animações.

As plantas balançam em loop: as linhas de cima do sprite se deslocam 1 pixel para os lados num ciclo de 4 quadros, e cada vaso começa numa fase diferente. A sala também tem poeirinha flutuando no feixe de sol, a TV piscando e um gato dormindo no sofá.

## Próximos passos

- Redesenhar violeta e rosa com referências, como foi feito com a costela de adão.
- Mais cômodos (varanda, cozinha, quarto) desbloqueados com aconchego.
- Mais vasos, plantas e objetos de decoração.

## Publicar online

Em Settings > Pages do repositório, escolha "Deploy from a branch", branch `main` e pasta `/ (root)`. O jogo fica em `https://gustavordeo.github.io/floricultura-cozy/`.
