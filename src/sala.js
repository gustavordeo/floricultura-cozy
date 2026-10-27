// Cenário da sala, desenhado uma vez num canvas fora da tela (256x160 pixels de jogo).
// Vista de frente, como uma casa de bonecas: parede ao fundo, chão de tacos embaixo.

const SALA = {
  LARG: 256,
  ALT: 160,
  CHAO_Y: 120,
  JANELA: { x: 18, y: 16, larg: 60, alt: 60 },
};

function desenharSala() {
  const { LARG, ALT, CHAO_Y, JANELA } = SALA;
  const c = document.createElement('canvas');
  c.width = LARG; c.height = ALT;
  const g = c.getContext('2d');
  const r = (x, y, w, h, cor) => { g.fillStyle = cor; g.fillRect(x, y, w, h); };

  // Parede com papel listrado
  r(0, 0, LARG, CHAO_Y, '#9cc3b4');
  for (let x = 0; x < LARG; x += 8) r(x, 0, 3, CHAO_Y, '#93baab');
  for (let x = 4; x < LARG; x += 16) for (let y = 6; y < CHAO_Y - 8; y += 12) r(x + ((y / 12) % 2) * 8, y, 1, 1, '#b5d6c9');
  r(0, CHAO_Y - 30, LARG, 2, '#e8dcc4'); // moldura de meia parede
  r(0, CHAO_Y - 28, LARG, 1, '#c9b99c');

  // Chão de tacos
  r(0, CHAO_Y, LARG, ALT - CHAO_Y, '#b07a4a');
  for (let y = CHAO_Y; y < ALT; y += 6) {
    r(0, y, LARG, 1, '#8f5e36');
    const desloc = ((y - CHAO_Y) / 6) % 2 ? 0 : 14;
    for (let x = desloc; x < LARG; x += 28) r(x, y, 1, 6, '#8f5e36');
    for (let x = desloc + 6; x < LARG; x += 28) r(x, y + 2, 3, 1, '#c08a58');
  }
  r(0, CHAO_Y - 4, LARG, 4, '#e8dcc4'); // rodapé
  r(0, CHAO_Y - 1, LARG, 1, '#c9b99c');

  // Janela com céu e nuvem
  const J = JANELA;
  r(J.x - 3, J.y - 3, J.larg + 6, J.alt + 6, '#f4efe4');
  r(J.x, J.y, J.larg, J.alt, '#a9dcf5');
  r(J.x, J.y + J.alt - 16, J.larg, 16, '#c4e8f8');
  r(J.x + 8, J.y + 12, 14, 4, '#ffffff');
  r(J.x + 5, J.y + 15, 22, 4, '#ffffff');
  r(J.x + 34, J.y + 30, 10, 3, '#ffffff');
  r(J.x + 31, J.y + 33, 18, 3, '#ffffff');
  r(J.x + J.larg - 18, J.y + 6, 10, 10, '#f6d861'); // sol
  r(J.x + J.larg - 17, J.y + 7, 4, 3, '#fff3b0');
  r(J.x + J.larg / 2 - 1, J.y, 2, J.alt, '#f4efe4'); // caixilho
  r(J.x, J.y + J.alt / 2 - 1, J.larg, 2, '#f4efe4');
  r(J.x - 6, J.y + J.alt + 2, J.larg + 12, 4, '#f4efe4'); // parapeito
  r(J.x - 6, J.y + J.alt + 6, J.larg + 12, 1, '#c9b99c');

  // Cortinas
  r(J.x - 12, J.y - 8, J.larg + 24, 2, '#7a4a2e');
  for (const cx of [J.x - 12, J.x + J.larg + 2]) {
    r(cx, J.y - 6, 10, 82, '#e3a05a');
    for (let k = 2; k < 10; k += 3) r(cx + k, J.y - 6, 1, 82, '#c98a46');
    r(cx, J.y + 76, 10, 2, '#c98a46');
  }

  // Quadro na parede
  r(150, 24, 30, 24, '#7a4a2e');
  r(152, 26, 26, 20, '#f3e6c8');
  r(152, 38, 26, 8, '#8fd06a');
  r(158, 30, 6, 6, '#dd4b67');
  r(168, 33, 5, 5, '#c9a7f2');

  // Prateleira com livros
  r(96, 50, 46, 3, '#a8703f');
  r(96, 53, 46, 1, '#7a4a2e');
  r(100, 54, 2, 4, '#7a4a2e');
  r(136, 54, 2, 4, '#7a4a2e');
  const livros = [['#dd4b67', 9], ['#5fa8d8', 11], ['#f6d861', 8], ['#4e3482', 10]];
  livros.forEach(([cor, alt], i) => r(99 + i * 4, 50 - alt, 3, alt, cor));

  // Sofá
  r(92, 82, 68, 20, '#c97b84'); // encosto
  r(92, 82, 68, 2, '#d8949b');
  r(86, 92, 10, 22, '#b4646e'); // braços
  r(156, 92, 10, 22, '#b4646e');
  r(86, 92, 10, 2, '#c97b84');
  r(156, 92, 10, 2, '#c97b84');
  r(96, 100, 60, 12, '#d8949b'); // assento
  r(96, 100, 60, 1, '#e7aeb3');
  r(125, 100, 1, 12, '#b4646e');
  r(100, 86, 14, 12, '#f6d861'); // almofada
  r(100, 86, 14, 1, '#fff3b0');
  r(88, 114, 3, 6, '#5e3b26'); // pés
  r(161, 114, 3, 6, '#5e3b26');

  // Mesinha lateral
  r(168, 100, 20, 3, '#a8703f');
  r(168, 103, 20, 1, '#7a4a2e');
  r(170, 104, 2, 16, '#7a4a2e');
  r(184, 104, 2, 16, '#7a4a2e');
  r(170, 112, 16, 1, '#7a4a2e');

  // Rack e TV
  r(194, 98, 58, 20, '#7a4a2e');
  r(194, 98, 58, 2, '#a8703f');
  r(198, 104, 22, 10, '#5e3b26');
  r(224, 104, 24, 10, '#5e3b26');
  r(208, 108, 4, 1, '#c48a52');
  r(234, 108, 4, 1, '#c48a52');
  r(196, 118, 3, 2, '#3b2f26');
  r(247, 118, 3, 2, '#3b2f26');
  r(198, 66, 40, 28, '#2b2a3a'); // TV
  r(201, 69, 34, 22, '#3c5068');
  r(203, 71, 12, 2, '#5d7896');
  r(214, 94, 8, 4, '#2b2a3a');

  // Tapete
  r(104, 128, 92, 16, '#8a5bd0');
  r(108, 130, 84, 12, '#c9a7f2');
  r(112, 132, 76, 8, '#8a5bd0');
  for (let x = 104; x < 196; x += 4) { r(x, 144, 2, 2, '#c9a7f2'); r(x, 126, 2, 2, '#c9a7f2'); }

  return c;
}

// Luz do sol entrando pela janela: feixe na parede e mancha no chão.
function desenharLuzDoSol(g, intensidade) {
  const { JANELA: J, CHAO_Y } = SALA;
  g.save();
  g.globalAlpha = 0.10 * intensidade;
  g.fillStyle = '#fff3b0';
  g.beginPath();
  g.moveTo(J.x, J.y + J.alt);
  g.lineTo(J.x + J.larg, J.y + J.alt);
  g.lineTo(J.x + J.larg + 44, 152);
  g.lineTo(J.x + 30, 152);
  g.closePath();
  g.fill();
  g.globalAlpha = 0.18 * intensidade;
  g.beginPath();
  g.moveTo(J.x + 22, CHAO_Y + 8);
  g.lineTo(J.x + J.larg + 16, CHAO_Y + 8);
  g.lineTo(J.x + J.larg + 44, 152);
  g.lineTo(J.x + 30, 152);
  g.closePath();
  g.fill();
  g.restore();
}
