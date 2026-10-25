// Pixel art do jogo, desenhada como texto: cada caractere é um pixel.
// '.' é transparente; as outras letras vêm da PALETA.
// O contorno escuro é gerado automaticamente em game.js.

const PALETA = {
  g: '#2f6b3a', // verde escuro (caules)
  G: '#4c9a45', // verde
  l: '#8fd06a', // verde claro
  L: '#c4ec8e', // brilho da folha
  r: '#9e2c46', // rosa escura
  R: '#dd4b67', // rosa
  p: '#f7a1b5', // brilho da rosa
  v: '#4e3482', // violeta escura
  V: '#8a5bd0', // violeta
  w: '#c9a7f2', // lilás
  y: '#f6d861', // amarelo
  o: '#c98a1e', // dourado escuro
  W: '#fff6d8', // brilho branco
  b: '#7a4a2e', // madeira escura
  B: '#a8703f', // madeira
  s: '#dfe8f0', // metal claro
  S: '#8fa3b5', // metal
  c: '#5fa8d8', // água
  C: '#a9dcf5', // brilho da água
};

const SPRITES = {
  semente: [
    '.......l........',
    '......bBb.......',
  ],
  broto: [
    '.....lG.Gl......',
    '......GlG.......',
    '.......g........',
    '.......g........',
  ],

  violeta: {
    crescendo: [
      '.......l........',
      '......gGg.......',
      '....GlGLGlG.....',
      '...GlGGgGGlG....',
      '..GLGg.g.gGLG...',
      '...gg..g..gg....',
    ],
    pronta: [
      '...wV......Vw...',
      '..VyVw....wVyV..',
      '...VV..wV..VV...',
      '....g.VyVw.g....',
      '.....g.Vg.g.....',
      '....GlGLGlG.....',
      '...GlGGgGGlG....',
      '..GLGg.g.gGLG...',
      '...gg..g..gg....',
    ],
  },

  rosa: {
    crescendo: [
      '.......l........',
      '......GgG.......',
      '......GgG.......',
      '.......g........',
      '..GG...g........',
      '..GlG..g...GG...',
      '...Gg..g..GlG...',
      '.......g..gG....',
      '.......g.g......',
      '.......gg.......',
      '.......g........',
    ],
    pronta: [
      '.....rRRr.......',
      '....rRpRRr......',
      '....RRRpRRr.....',
      '....rRRRpRr.....',
      '.....rRRRr......',
      '......GgG.......',
      '..GG...g...rR...',
      '..GlG..g..rpRr..',
      '...Gg..g..rRRr..',
      '.......g...gG...',
      '...GG..g..gG....',
      '....Gg.g.g......',
      '.......gg.......',
      '.......g........',
    ],
  },

  costela: {
    crescendo: [
      '....GGG.........',
      '...GlLGG........',
      '...GlG.GG..GGG..',
      '....GG.Gg.GlLG..',
      '......g.gGlG.G..',
      '.......g.GG.....',
      '.......gg.......',
      '.......g........',
    ],
    pronta: [
      '...GGG....GGGG..',
      '..GlLG.G.GLlGGG.',
      '.GlG.GG.GG.GlGG.',
      '.GLG.GGgGG.GG.G.',
      '..GG.G.g.G.G.G..',
      '...G.Gg.g.gG....',
      '.GGG..g.g.......',
      'GlLGG..gg..GG...',
      'GlG.GG.g..GlGG..',
      '.GG.G..g.gG.GG..',
      '..G.G..ggG.G....',
      '.......g........',
    ],
  },

  regador: [
    '....SSSS........',
    '...S....S.......',
    '..SsssssS.....s.',
    '..SsCCssSS...sS.',
    '..SsssssS.SSsS..',
    '..SsssssSSsSS...',
    '..SsssssS.......',
    '...SSSSS........',
  ],
  pa: [
    '..........bb....',
    '.........bBb....',
    '........bBb.....',
    '.......bBb......',
    '......bBb.......',
    '..sS.bBb........',
    '.sssSbb.........',
    '.ssssS..........',
    '.sssSS..........',
    '..SSS...........',
  ],
  moeda: [
    '..oooo..',
    '.oyyyyo.',
    'oyWyyyoo',
    'oyWyyyoo',
    'oyyyyyoo',
    '.ooyyoo.',
    '..oooo..',
  ],
  gota: [
    '..c..',
    '.cCc.',
    'cCccc',
    'ccccc',
    '.ccc.',
  ],
  placa: [
    '..bbbbbbbbbb....',
    '.bBBBBBBBBBBb...',
    '.bBBBBBBBBBBb...',
    '.bBBBBBBBBBBb...',
    '..bbbbbbbbbb....',
    '......bb........',
    '......bb........',
  ],
  borboleta: [
    ['p.p', 'RyR', 'p.p'],
    ['...', 'pyp', '...'],
  ],
};
