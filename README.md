# floricultura-cozy

Jogo aconchegante de decorar uma sala com plantas (costela de adão, rosas e violetas), feito no **Godot 4.7** com GDScript.

## Estilo

Desenho à mão em cima de uma sala 3D de diorama: sombreado em três faixas (toon), papel com grão e manchas de aquarela,
hachura de lápis nas sombras e um traço fino de grafite **só nas plantas**. A câmera fica na diagonal, como uma maquete.

## Como abrir

1. Abra o Godot 4.7 (versão padrão, não a .NET).
2. Na lista de projetos, clique em **Importar** e escolha o arquivo `project.godot` desta pasta.
3. Com o projeto aberto, aperte **F5** (ou o botão ▶ no canto de cima) para jogar.

## Controles

- Arrastar: move o cenário.
- Botão direito do mouse (ou dois dedos no celular): gira a sala.
- Roda do mouse, pinça ou dois dedos no trackpad: aproxima e afasta.
- Dois cliques fora dos vasos: volta para o zoom e a posição inicial.
- Clicar num espaço com **+**: coloca o vaso e a planta escolhidos na barra de baixo.

## Como o jogo funciona

Cada canto da sala tem sol direto, meia-luz ou sombra. Cada planta gosta de uma luz e só cresce com a terra molhada.
Plantas adultas felizes e vasos bonitos aumentam o **aconchego** da sala. O progresso fica salvo no computador.

## Organização

- `cenas/sala.tscn`: cena principal.
- `scripts/sala.gd`: monta a sala, a câmera, a interface e as regras.
- `scripts/plantas.gd`: modelos das plantas e dos vasos.
- `scripts/materiais.gd`: materiais e a máscara usada pelo traço das plantas.
- `shaders/`: sombreado toon, máscara e o efeito de desenho à mão.

O renderizador é o **Compatibility**, para o jogo rodar no navegador e no celular.
