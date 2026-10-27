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
  k: '#2e2a24', // contorno interno (separa folhas sobrepostas)
  T: '#c8643c', // terracota
  t: '#9c4a2c', // terracota escura
  U: '#e08458', // borda da terracota
  E: '#eef0ea', // cerâmica branca
  e: '#c3cbc4', // sombra da cerâmica
  Q: '#d9b25f', // palha
  q: '#a8823c', // palha escura
  F: '#e3a05a', // pelo do gato
  f: '#b8743a', // pelo escuro
  n: '#f6dcb4', // pelo claro
};

const SPRITES = {
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

  // Costela de adão em 24x24, baseada nas fotos de referência:
  // folha da frente em coração com nervura central clara e recortes, duas folhas escuras atrás.
  costela: {
    crescendo: [
      '....gg..................',
      '...gggggg...............',
      '...ggggggg..............',
      '...gglgggkk.............',
      '..gggglgkGGG............',
      '...ggggkGlllGGGGG.......',
      '...ggGGkGllllllllG......',
      '...gGGkGGl.lLllllG......',
      '....gggkkGGGL.G.GG......',
      '.......GGGGGLGGG.G......',
      '........GGGGLGGGG.......',
      '........Gk.GLGGGG.......',
      '.........GGGLG.G........',
      '.........GGGGGG.........',
      '..........kGGG..........',
      '..........g.k...........',
      '...........gg...........',
      '...........gg...........',
    ],
    pronta: [
      '....gg............gg....',
      'ggggggg.g......g.ggg.ggg',
      'lgg.ggg.gg....gg.ggg.ggl',
      'gl.gggg.Ggg..ggG.gggg.lg',
      'g.glggg.kkg..gGk.ggggl.g',
      'gggglgkkGGk..kkGkkglgg.g',
      '.ggggkGGGGG..GGGGGkgggg.',
      'gggggkGllllLLllllGGkgggg',
      'gggg.GGlllllLllllGG.gggg',
      '.g.GkGllllllLlllllGkG.g.',
      '..ggkGGl..lLLl..lGGkggg.',
      '...gkGk.GGGLLGGG.kGkg...',
      '......GGG.GGLG.GGG......',
      '......G..GG.LGG..GG.....',
      '.......GGGGGLGGGG.......',
      '......GG..GLLG..GG......',
      '........GGGLLGGG........',
      '........G.GGLG.G........',
      '.........GG.LGG.........',
      '..........GGGG..........',
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
  coracao: [
    '.RR.RR.',
    'RpRRRRR',
    'RRRRRRR',
    '.RRRRR.',
    '..RRR..',
    '...R...',
  ],
  gota: [
    '..c..',
    '.cCc.',
    'cCccc',
    'ccccc',
    '.ccc.',
  ],

  vasos: {
    barro: [
      'tUUUUUUUUUUUt',
      'tTTTTTTTTTTTt',
      '.tTTTTTTTTTt.',
      '.tTUTTTTTTTt.',
      '..tUTTTTTTt..',
      '..tTTTTTTTt..',
      '...ttttttt...',
    ],
    ceramica: [
      'eEEEEEEEEEEEe',
      '.eEEEEEEEEEe.',
      '.eccccccccce.',
      '.eEEEEEEEEEe.',
      '..eEEEEEEEe..',
      '..eEEEEEEEe..',
      '...eeeeeee...',
    ],
    cesto: [
      'qQqQqQqQqQqQq',
      'QqQqQqQqQqQqQ',
      '.qQqQqQqQqQq.',
      '.QqQqQqQqQqQ.',
      '..qQqQqQqQq..',
      '..QqQqQqQqQ..',
      '...qqqqqqq...',
    ],
  },

  // Gato dormindo no sofá: o segundo quadro tem uma linha a mais (respiração).
  gato: [
    [
      '.........f.f..',
      '..FFFFF..FFF..',
      '.FnnFFFF.FkFk.',
      'FnFFFFFFFFFFF.',
      'fFFFFFFFFFFFf.',
      '.ffff....fff..',
    ],
    [
      '.........f.f..',
      '..FFFFF..FFF..',
      '.FnnFFFF.FkFk.',
      'FnFFFFFFFFFFF.',
      'FnFFFFFFFFFFF.',
      'fFFFFFFFFFFFf.',
      '.ffff....fff..',
    ],
  ],

  luz: {
    sol: [
      '.y.y.',
      '..y..',
      'yyyyy',
      '..y..',
      '.y.y.',
    ],
    meia: [
      '.yyy.',
      'yyWWW',
      'yyWWW',
      'yyWWW',
      '.yyy.',
    ],
    sombra: [
      '.ww..',
      'ww...',
      'ww...',
      'ww..w',
      '.www.',
    ],
  },
};
