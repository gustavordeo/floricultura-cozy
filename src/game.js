(() => {
  // ---------- Configuração ----------
  const ESCALA = 4;          // cada pixel do jogo vira 4 pixels na tela
  const TILE = 24;
  const LARG = 192;
  const ALT = 144;
  const GRADE = { x: 24, y: 26, cols: 6, linhas: 4 };
  const CAMINHO_Y = 126;     // onde começa o caminho de terra embaixo
  const CHAVE_SAVE = 'floricultura-cozy-v1';
  const MAX_OFFLINE = 3600;  // segundos de crescimento enquanto o jogo está fechado

  // tempos: segundos de água necessários para passar de semente → broto → crescendo → pronta
  // seca: por quantos segundos a terra fica molhada depois de regar
  const PLANTAS = {
    violeta: {
      nome: 'Violeta', estilo: 'Delicada', semente: 5, venda: 14,
      tempos: [6, 8, 10], seca: 25,
      dica: 'Rápida, mas não gosta de água demais. Regar com a terra molhada encharca.',
    },
    rosa: {
      nome: 'Rosa', estilo: 'Romântica', semente: 15, venda: 40,
      tempos: [10, 15, 20], seca: 15,
      dica: 'Vale mais, mas a terra seca rápido. Regue com frequência.',
    },
    costela: {
      nome: 'Costela de adão', estilo: 'Tropical', semente: 30, venda: 22,
      tempos: [15, 25, 30], seca: 60, perene: true,
      dica: 'Lenta, aguenta muito tempo sem água e rebrota depois de cada colheita.',
    },
  };
  const ESTAGIOS = ['Semente', 'Broto', 'Crescendo', 'Pronta para colher'];
  const BALANCO = [0, 1, 0, -1];   // deslocamento em pixels de cada quadro da animação
  const QUADRO_MS = 420;
  const ENCHARCADO_S = 12;

  // ---------- Sprites ----------
  const CONTORNO = '#2e2a24';
  const cacheSprites = new Map();

  // Desenha um sprite de texto num canvas pequeno, com 1 pixel de margem para o contorno automático.
  // balanco: desloca para os lados a parte de cima do sprite (a fração de linhas em fracaoBalanco).
  function sprite(nome, linhas, { balanco = 0, fracaoBalanco = 0.55 } = {}) {
    const chave = nome + '|' + balanco;
    if (cacheSprites.has(chave)) return cacheSprites.get(chave);

    const larg = Math.max(...linhas.map((l) => l.length));
    const limiteBalanco = Math.ceil(linhas.length * fracaoBalanco);
    const W = larg + 2, H = linhas.length + 2;
    const grade = Array.from({ length: H }, () => Array(W).fill(null));

    linhas.forEach((linha, y) => {
      const dx = y < limiteBalanco ? balanco : 0;
      [...linha].forEach((ch, x) => {
        const cor = PALETA[ch];
        const gx = x + 1 + dx, gy = y + 1;
        if (cor && gx >= 0 && gx < W && gy < H) grade[gy][gx] = cor;
      });
    });

    const c = document.createElement('canvas');
    c.width = W; c.height = H;
    const g = c.getContext('2d');
    for (let y = 0; y < H; y++) {
      for (let x = 0; x < W; x++) {
        let cor = grade[y][x];
        if (!cor) {
          const vizinho = [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([ox, oy]) => grade[y + oy]?.[x + ox]);
          if (!vizinho) continue;
          cor = CONTORNO;
        }
        g.fillStyle = cor;
        g.fillRect(x, y, 1, 1);
      }
    }
    cacheSprites.set(chave, c);
    return c;
  }

  // Quanto da planta balança: a costela pronta só mexe as folhas de trás, para não rasgar a folha da frente.
  const FRACAO_BALANCO = { costelapronta: 0.3 };

  function spriteDaPlanta(p, balanco) {
    if (p.estagio === 0) return sprite('semente', SPRITES.semente);
    if (p.estagio === 1) return sprite('broto', SPRITES.broto, { balanco });
    const fase = p.estagio === 3 ? 'pronta' : 'crescendo';
    const nome = p.tipo + fase;
    return sprite(nome, SPRITES[p.tipo][fase], { balanco, fracaoBalanco: FRACAO_BALANCO[nome] });
  }

  // Centraliza o sprite no canteiro, com a base 3 pixels acima da borda de baixo.
  function desenharPlanta(p, balanco, x, y) {
    const c = spriteDaPlanta(p, balanco);
    const larg = c.width - 2, alt = c.height - 2;
    ctx.drawImage(c, x + Math.floor((TILE - larg) / 2) - 1, y + TILE - 3 - alt);
  }

  // ---------- Estado ----------
  function estadoInicial() {
    const canteiros = [];
    for (let i = 0; i < GRADE.cols * GRADE.linhas; i++) {
      const col = i % GRADE.cols, lin = Math.floor(i / GRADE.cols);
      canteiros.push({ liberado: col < 3 && lin < 2, planta: null });
    }
    return { moedas: 30, t: 0, compras: 0, colhidas: 0, canteiros, salvoEm: Date.now() };
  }

  function carregar() {
    try {
      const bruto = localStorage.getItem(CHAVE_SAVE);
      if (!bruto) return estadoInicial();
      const salvo = JSON.parse(bruto);
      if (!Array.isArray(salvo.canteiros) || salvo.canteiros.length !== GRADE.cols * GRADE.linhas) return estadoInicial();
      return salvo;
    } catch (e) {
      return estadoInicial();
    }
  }

  function salvar() {
    estado.salvoEm = Date.now();
    try { localStorage.setItem(CHAVE_SAVE, JSON.stringify(estado)); } catch (e) { /* sem armazenamento: o jogo segue sem salvar */ }
  }

  let estado = carregar();
  let ferramenta = 'regador';
  let hover = -1;
  let confirmacao = null; // { indice, acao, ate }
  const particulas = [];
  const textos = [];

  // ---------- Simulação ----------
  function avancar(dt) {
    estado.t += dt;
    for (const c of estado.canteiros) {
      const p = c.planta;
      if (!p || p.estagio >= 3) continue;
      const molhada = estado.t < p.molhadoAte;
      const encharcada = estado.t < p.encharcadoAte;
      if (!molhada || encharcada) continue;
      p.progresso += dt;
      const precisa = PLANTAS[p.tipo].tempos[p.estagio];
      if (p.progresso >= precisa) {
        p.progresso = 0;
        p.estagio++;
      }
    }
  }

  function recuperarTempo(segundos) {
    let resta = Math.min(segundos, MAX_OFFLINE);
    while (resta > 0) {
      const passo = Math.min(1, resta);
      avancar(passo);
      resta -= passo;
    }
  }

  // Crescimento enquanto o jogo estava fechado
  recuperarTempo((Date.now() - (estado.salvoEm || Date.now())) / 1000);

  function custoExpansao() {
    return 40 + estado.compras * 20;
  }

  // ---------- Ações ----------
  function centro(i) {
    const col = i % GRADE.cols, lin = Math.floor(i / GRADE.cols);
    return { x: GRADE.x + col * TILE + TILE / 2, y: GRADE.y + lin * TILE + TILE / 2 };
  }

  function texto(i, msg, cor = '#fff6d8') {
    const { x, y } = centro(i);
    textos.push({ x, y: y - 6, msg, cor, vida: 1.4 });
  }

  function confirmar(i, acao, msg) {
    if (confirmacao && confirmacao.indice === i && confirmacao.acao === acao && performance.now() < confirmacao.ate) {
      confirmacao = null;
      return true;
    }
    confirmacao = { indice: i, acao, ate: performance.now() + 3000 };
    status(msg);
    return false;
  }

  function clicar(i) {
    const c = estado.canteiros[i];
    const p = c.planta;

    if (!c.liberado) {
      const custo = custoExpansao();
      if (estado.moedas < custo) return status(`Faltam ${custo - estado.moedas} moedas para abrir este canteiro.`);
      if (!confirmar(i, 'comprar', `Clique de novo para abrir este canteiro por ${custo} moedas.`)) return;
      estado.moedas -= custo;
      estado.compras++;
      c.liberado = true;
      texto(i, `-${custo}`, '#f7a1b5');
      status('Canteiro novo pronto para plantar!');
      return salvar();
    }

    // Planta pronta é colhida com qualquer ferramenta
    if (p && p.estagio === 3) {
      const def = PLANTAS[p.tipo];
      estado.moedas += def.venda;
      estado.colhidas++;
      texto(i, `+${def.venda}`, '#f6d861');
      brilho(i, 10);
      if (def.perene) {
        p.estagio = 2;
        p.progresso = 0;
        status(`Vendeu uma muda de ${def.nome}. Ela vai rebrotar!`);
      } else {
        c.planta = null;
        status(`Vendeu ${def.nome === 'Rosa' ? 'um buquê de rosas' : 'um vasinho de violetas'} por ${def.venda} moedas.`);
      }
      return salvar();
    }

    if (ferramenta === 'regador') {
      if (!p) return status('Plante uma semente antes de regar.');
      const def = PLANTAS[p.tipo];
      respingo(i);
      if (p.tipo === 'violeta' && estado.t < p.molhadoAte) {
        p.encharcadoAte = estado.t + ENCHARCADO_S;
        status('Ops, a violeta ficou encharcada. Ela para de crescer até a terra secar um pouco.');
        return salvar();
      }
      p.molhadoAte = estado.t + def.seca;
      status(`${def.nome} regada.`);
      return salvar();
    }

    if (ferramenta === 'pa') {
      if (!p) return status('Este canteiro já está vazio.');
      if (!confirmar(i, 'remover', `Clique de novo para arrancar a ${PLANTAS[p.tipo].nome.toLowerCase()}.`)) return;
      c.planta = null;
      status('Canteiro limpo.');
      return salvar();
    }

    // Ferramenta é uma semente
    const def = PLANTAS[ferramenta];
    if (p) return status('Este canteiro já tem uma planta.');
    if (estado.moedas < def.semente) return status(`Faltam ${def.semente - estado.moedas} moedas para a semente de ${def.nome.toLowerCase()}.`);
    estado.moedas -= def.semente;
    c.planta = { tipo: ferramenta, estagio: 0, progresso: 0, molhadoAte: 0, encharcadoAte: 0 };
    texto(i, `-${def.semente}`, '#f7a1b5');
    status(`Plantou ${def.nome.toLowerCase()}. Agora é só regar.`);
    salvar();
  }

  // ---------- Efeitos ----------
  function respingo(i) {
    const { x, y } = centro(i);
    for (let k = 0; k < 8; k++) {
      particulas.push({ x: x - 5 + Math.random() * 10, y: y - 10 - Math.random() * 4, vy: 20 + Math.random() * 20, vida: 0.5, cor: k % 2 ? '#5fa8d8' : '#a9dcf5' });
    }
  }

  function brilho(i, n) {
    const { x, y } = centro(i);
    for (let k = 0; k < n; k++) {
      particulas.push({ x: x - 6 + Math.random() * 12, y: y - 4 - Math.random() * 8, vy: -10 - Math.random() * 10, vida: 0.8, cor: k % 2 ? '#f6d861' : '#fff6d8' });
    }
  }

  // ---------- Desenho ----------
  const canvas = document.getElementById('jardim');
  canvas.width = LARG * ESCALA;
  canvas.height = ALT * ESCALA;
  const ctx = canvas.getContext('2d');
  ctx.imageSmoothingEnabled = false;
  ctx.scale(ESCALA, ESCALA);

  // Gerador pseudoaleatório fixo, para o cenário ser sempre igual
  function aleatorio(semente) {
    let s = semente;
    return () => (s = (s * 16807) % 2147483647) / 2147483647;
  }

  const fundo = (() => {
    const c = document.createElement('canvas');
    c.width = LARG; c.height = ALT;
    const g = c.getContext('2d');
    const rnd = aleatorio(7);
    g.fillStyle = '#7fbf5a';
    g.fillRect(0, 0, LARG, ALT);
    for (let k = 0; k < 140; k++) {
      g.fillStyle = rnd() < 0.5 ? '#6cad4c' : '#93cf68';
      const x = Math.floor(rnd() * LARG), y = Math.floor(rnd() * ALT);
      g.fillRect(x, y, 1, 2);
      g.fillRect(x + 1, y + 1, 1, 1);
    }
    // cerca
    g.fillStyle = '#a8703f';
    g.fillRect(0, 9, LARG, 2);
    g.fillRect(0, 14, LARG, 2);
    for (let x = 1; x < LARG; x += 10) {
      g.fillStyle = '#7a4a2e';
      g.fillRect(x, 5, 4, 13);
      g.fillStyle = '#c48a52';
      g.fillRect(x + 1, 6, 1, 11);
    }
    // caminho de terra
    g.fillStyle = '#d9b77f';
    g.fillRect(0, CAMINHO_Y, LARG, ALT - CAMINHO_Y);
    g.fillStyle = '#c9a36a';
    for (let k = 0; k < 50; k++) g.fillRect(Math.floor(rnd() * LARG), CAMINHO_Y + 1 + Math.floor(rnd() * (ALT - CAMINHO_Y - 2)), 2, 1);
    // florzinhas decorativas no gramado
    const cores = ['#f6d861', '#fff6d8', '#f7a1b5', '#c9a7f2'];
    for (let k = 0; k < 18; k++) {
      let x = Math.floor(rnd() * LARG), y = 20 + Math.floor(rnd() * (CAMINHO_Y - 26));
      const fimGrade = GRADE.x + GRADE.cols * TILE;
      if (x > GRADE.x - 3 && x < fimGrade + 2) x = rnd() < 0.5 ? 3 + Math.floor(rnd() * (GRADE.x - 6)) : fimGrade + 3 + Math.floor(rnd() * (LARG - fimGrade - 6));
      g.fillStyle = cores[k % cores.length];
      g.fillRect(x, y, 1, 1);
      g.fillRect(x - 1, y + 1, 1, 1);
      g.fillRect(x + 1, y + 1, 1, 1);
      g.fillRect(x, y + 2, 1, 1);
      g.fillStyle = '#4c9a45';
      g.fillRect(x, y + 3, 1, 2);
    }
    return c;
  })();

  function desenharTerra(x, y, molhada) {
    ctx.fillStyle = molhada ? '#5a3a26' : '#8a5a38';
    ctx.fillRect(x + 1, y + 1, TILE - 2, TILE - 2);
    ctx.fillStyle = molhada ? '#4a2f1f' : '#6f4529';
    for (const ly of [6, 12, 18, TILE - 2]) ctx.fillRect(x + 1, y + ly, TILE - 2, 1);
    ctx.fillStyle = molhada ? '#6e4a32' : '#a8703f';
    ctx.fillRect(x + 4, y + 3, 1, 1);
    ctx.fillRect(x + 15, y + 9, 1, 1);
    ctx.fillRect(x + 8, y + 15, 1, 1);
    ctx.fillRect(x + 18, y + 20, 1, 1);
  }

  const borboleta = { x: 20, y: 40 };

  function desenhar(agora) {
    const quadro = Math.floor(agora / QUADRO_MS);
    ctx.drawImage(fundo, 0, 0);

    estado.canteiros.forEach((c, i) => {
      const col = i % GRADE.cols, lin = Math.floor(i / GRADE.cols);
      const x = GRADE.x + col * TILE, y = GRADE.y + lin * TILE;
      const p = c.planta;

      if (!c.liberado) {
        ctx.fillStyle = 'rgba(46, 42, 36, 0.12)';
        ctx.fillRect(x + 1, y + 1, TILE - 2, TILE - 2);
        ctx.drawImage(sprite('placa', SPRITES.placa), x + 4, y + 6);
        ctx.fillStyle = '#fff6d8';
        ctx.font = '5px "Pixelify Sans", monospace';
        ctx.textAlign = 'center';
        ctx.fillText(String(custoExpansao()), x + 11, y + 12);
      } else {
        const molhada = p && estado.t < p.molhadoAte;
        desenharTerra(x, y, molhada);
      }

      if (p) {
        const balanco = BALANCO[(quadro + col + lin * 2) % BALANCO.length];
        desenharPlanta(p, balanco, x, y);

        const molhada = estado.t < p.molhadoAte;
        const encharcada = estado.t < p.encharcadoAte;
        if (p.estagio === 3) {
          if ((quadro + i) % 5 === 0) {
            ctx.fillStyle = '#fff6d8';
            const sx = x + 5 + ((i * 7) % 14), sy = y + 1 + ((i * 3) % 6);
            ctx.fillRect(sx, sy - 1, 1, 3);
            ctx.fillRect(sx - 1, sy, 3, 1);
          }
        } else if (encharcada) {
          ctx.fillStyle = '#a9dcf5';
          const b = quadro % 2;
          ctx.fillRect(x + 4, y + 18 - b, 1, 1);
          ctx.fillRect(x + 18, y + 17 + b, 1, 1);
          ctx.fillRect(x + 11, y + 20, 2, 1);
        } else if (!molhada) {
          const pulo = quadro % 2;
          ctx.drawImage(sprite('gota', SPRITES.gota), x + 16, y - 2 - pulo);
        }
      }

      if (i === hover) {
        ctx.strokeStyle = 'rgba(255, 246, 216, 0.9)';
        ctx.lineWidth = 1;
        ctx.strokeRect(x + 0.5, y + 0.5, TILE - 1, TILE - 1);
      }
    });

    // borboleta passeando
    const tb = agora / 1000;
    borboleta.x = LARG / 2 + Math.sin(tb * 0.31) * (LARG / 2 - 10);
    borboleta.y = 60 + Math.sin(tb * 0.83) * 38 + Math.sin(tb * 2.1) * 4;
    const asa = Math.floor(agora / 160) % 2;
    ctx.drawImage(sprite('borboleta' + asa, SPRITES.borboleta[asa]), Math.round(borboleta.x), Math.round(borboleta.y));

    for (const pt of particulas) {
      ctx.fillStyle = pt.cor;
      ctx.fillRect(Math.round(pt.x), Math.round(pt.y), 1, 1);
    }

    ctx.font = '7px "Pixelify Sans", monospace';
    ctx.textAlign = 'center';
    for (const tx of textos) {
      ctx.globalAlpha = Math.min(1, tx.vida);
      ctx.fillStyle = '#2e2a24';
      ctx.fillText(tx.msg, tx.x + 0.5, tx.y + 0.5);
      ctx.fillStyle = tx.cor;
      ctx.fillText(tx.msg, tx.x, tx.y);
    }
    ctx.globalAlpha = 1;
  }

  function atualizarEfeitos(dt) {
    for (let k = particulas.length - 1; k >= 0; k--) {
      const pt = particulas[k];
      pt.y += pt.vy * dt;
      pt.vida -= dt;
      if (pt.vida <= 0) particulas.splice(k, 1);
    }
    for (let k = textos.length - 1; k >= 0; k--) {
      textos[k].y -= 8 * dt;
      textos[k].vida -= dt;
      if (textos[k].vida <= 0) textos.splice(k, 1);
    }
  }

  // ---------- Interface ----------
  const elMoedas = document.getElementById('moedas');
  const elStatus = document.getElementById('status');
  const elInfo = document.getElementById('info');

  function status(msg) {
    elStatus.textContent = msg;
  }

  function descreverCanteiro(i) {
    if (i < 0) return 'Passe o mouse ou toque num canteiro para ver como ele está.';
    const c = estado.canteiros[i];
    if (!c.liberado) return `Canteiro fechado. Abra por ${custoExpansao()} moedas.`;
    const p = c.planta;
    if (!p) return 'Canteiro vazio, pronto para uma semente.';
    const def = PLANTAS[p.tipo];
    let txt = `${def.nome}: ${ESTAGIOS[p.estagio]}`;
    if (p.estagio < 3) {
      const pct = Math.floor((p.progresso / def.tempos[p.estagio]) * 100);
      txt += ` (${pct}%)`;
      if (estado.t < p.encharcadoAte) txt += ', encharcada';
      else if (estado.t < p.molhadoAte) txt += `, terra molhada por mais ${Math.ceil(p.molhadoAte - estado.t)}s`;
      else txt += ', com sede';
    }
    return txt;
  }

  function miniatura(nome, linhas) {
    return sprite(nome, linhas).toDataURL();
  }

  function montarFerramentas() {
    const barra = document.getElementById('ferramentas');
    const itens = [
      ...Object.entries(PLANTAS).map(([id, def]) => ({
        id, rotulo: def.nome, detalhe: `${def.estilo} · semente ${def.semente}`, titulo: def.dica,
        img: miniatura(id + 'pronta', SPRITES[id].pronta),
      })),
      { id: 'regador', rotulo: 'Regador', detalhe: 'molha a terra', titulo: 'Plantas só crescem com a terra molhada.', img: miniatura('regador', SPRITES.regador) },
      { id: 'pa', rotulo: 'Pá', detalhe: 'arranca a planta', titulo: 'Libera o canteiro. Pede confirmação.', img: miniatura('pa', SPRITES.pa) },
    ];
    itens.forEach((item, n) => {
      const b = document.createElement('button');
      b.type = 'button';
      b.id = 'ferramenta-' + item.id;
      b.className = 'ferramenta';
      b.title = `${item.titulo} (tecla ${n + 1})`;
      b.innerHTML = `<img src="${item.img}" alt=""><span class="rotulo">${item.rotulo}</span><span class="detalhe">${item.detalhe}</span>`;
      b.addEventListener('click', () => escolher(item.id));
      barra.appendChild(b);
    });
    document.addEventListener('keydown', (e) => {
      const n = Number(e.key);
      if (n >= 1 && n <= itens.length) escolher(itens[n - 1].id);
    });
  }

  function escolher(id) {
    ferramenta = id;
    document.querySelectorAll('.ferramenta').forEach((b) => b.setAttribute('aria-pressed', String(b.id === 'ferramenta-' + id)));
    status(PLANTAS[id] ? `${PLANTAS[id].nome}: ${PLANTAS[id].dica}` : id === 'regador' ? 'Regador na mão. Clique nas plantas com sede.' : 'Pá na mão. Clique numa planta para arrancar.');
  }

  function indiceNoPonto(evento) {
    const r = canvas.getBoundingClientRect();
    const x = ((evento.clientX - r.left) / r.width) * LARG;
    const y = ((evento.clientY - r.top) / r.height) * ALT;
    const col = Math.floor((x - GRADE.x) / TILE), lin = Math.floor((y - GRADE.y) / TILE);
    if (col < 0 || lin < 0 || col >= GRADE.cols || lin >= GRADE.linhas) return -1;
    return lin * GRADE.cols + col;
  }

  canvas.addEventListener('pointermove', (e) => { hover = indiceNoPonto(e); });
  canvas.addEventListener('pointerleave', () => { hover = -1; });
  canvas.addEventListener('pointerdown', (e) => {
    const i = indiceNoPonto(e);
    hover = i;
    if (i >= 0) clicar(i);
  });

  document.getElementById('recomecar').addEventListener('click', () => {
    if (!confirmar(-2, 'recomecar', 'Clique de novo em "Recomeçar" para apagar o jardim e começar do zero.')) return;
    estado = estadoInicial();
    salvar();
    status('Jardim novinho. Comece plantando violetas, que são baratas e rápidas.');
  });

  // ---------- Laço principal ----------
  let anterior = performance.now();
  let ultimoSave = anterior;

  function laco(agora) {
    let dt = (agora - anterior) / 1000;
    anterior = agora;
    if (dt > 1) recuperarTempo(dt); // a aba ficou em segundo plano
    else avancar(dt);
    atualizarEfeitos(Math.min(dt, 0.1));
    desenhar(agora);

    elMoedas.textContent = estado.moedas;
    elInfo.textContent = descreverCanteiro(hover);
    if (agora - ultimoSave > 5000) { salvar(); ultimoSave = agora; }
    requestAnimationFrame(laco);
  }

  document.getElementById('icone-moeda').src = miniatura('moeda', SPRITES.moeda);
  montarFerramentas();
  escolher('violeta');
  status(estado.colhidas ? 'Bem-vindo de volta! Suas plantas continuaram crescendo.' : 'Escolha uma semente, plante num canteiro e regue. Comece pelas violetas!');
  window.addEventListener('beforeunload', salvar);
  requestAnimationFrame(laco);
})();
