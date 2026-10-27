(() => {
  // ---------- Configuração ----------
  const ESCALA = 4;          // cada pixel do jogo vira 4 pixels na tela
  const LARG = SALA.LARG;
  const ALT = SALA.ALT;
  const CHAVE_SAVE = 'sala-cozy-v1';
  const MAX_OFFLINE = 3600;  // segundos de crescimento enquanto o jogo está fechado

  const LUZES = {
    sol: { nome: 'Sol direto' },
    meia: { nome: 'Meia-luz' },
    sombra: { nome: 'Sombra' },
  };

  // tempos: segundos de terra molhada para ir de muda → crescendo → adulta
  // seca: por quantos segundos a terra fica molhada depois de regar
  // mimo: a planta adulta solta flores ou uma muda para vender a cada tantos segundos
  // luz: quanto cada planta gosta de cada luz (1 = ideal, 0.6 = aceita, 0.3 = sofre); multiplica o ritmo
  const PLANTAS = {
    violeta: {
      nome: 'Violeta', preco: 10, venda: 6, tempos: [10, 14], seca: 25, mimo: 30,
      luz: { sol: 0.3, meia: 1, sombra: 0.6 },
      dica: 'Gosta de meia-luz. Sol direto queima as folhas, e regar com a terra molhada encharca.',
    },
    rosa: {
      nome: 'Rosa', preco: 20, venda: 12, tempos: [15, 20], seca: 15, mimo: 45,
      luz: { sol: 1, meia: 0.6, sombra: 0.3 },
      dica: 'Precisa de sol direto e de rega frequente. Dá as flores mais valiosas.',
    },
    costela: {
      nome: 'Costela de adão', preco: 30, venda: 10, tempos: [20, 30], seca: 60, mimo: 40,
      luz: { sol: 0.6, meia: 1, sombra: 1 },
      dica: 'Tranquila: aguenta sombra e fica um minuto sem água.',
    },
  };

  const VASOS = {
    barro: { nome: 'Vaso de barro', curto: 'Barro', preco: 0, charme: 0 },
    ceramica: { nome: 'Vaso de cerâmica', curto: 'Cerâmica', preco: 8, charme: 1 },
    cesto: { nome: 'Cesto de palha', curto: 'Cesto', preco: 12, charme: 2 },
  };

  // Pontos onde dá para colocar um vaso: x é o centro, y é onde o vaso apoia.
  const PONTOS = [
    { id: 'parapeito', nome: 'Parapeito da janela', x: 48, y: 79, luz: 'sol' },
    { id: 'chao-janela', nome: 'Chão perto da janela', x: 66, y: 146, luz: 'sol' },
    { id: 'prateleira', nome: 'Prateleira', x: 128, y: 50, luz: 'meia' },
    { id: 'mesinha', nome: 'Mesinha ao lado do sofá', x: 178, y: 100, luz: 'meia' },
    { id: 'rack', nome: 'Rack da TV', x: 244, y: 98, luz: 'sombra' },
    { id: 'canto', nome: 'Canto perto da TV', x: 214, y: 154, luz: 'sombra' },
  ];

  const ESTAGIOS = ['Muda', 'Crescendo', 'Adulta'];
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

  // Os sprites antigos têm 16 colunas com o caule perto da coluna 7: tiramos as colunas vazias
  // das bordas para a planta ficar centralizada no vaso.
  function aparar(linhas) {
    const larg = Math.max(...linhas.map((l) => l.length));
    const cheias = linhas.map((l) => l.padEnd(larg, '.'));
    let ini = 0, fim = larg - 1;
    while (ini < fim && cheias.every((l) => l[ini] === '.')) ini++;
    while (fim > ini && cheias.every((l) => l[fim] === '.')) fim--;
    return cheias.map((l) => l.slice(ini, fim + 1));
  }
  for (const tipo of Object.keys(PLANTAS)) {
    for (const fase of ['crescendo', 'pronta']) SPRITES[tipo][fase] = aparar(SPRITES[tipo][fase]);
  }
  SPRITES.broto = aparar(SPRITES.broto);

  // Quanto da planta balança: a costela adulta só mexe as folhas de trás, para não rasgar a folha da frente.
  const FRACAO_BALANCO = { costelapronta: 0.3 };

  function spriteDaPlanta(p, balanco) {
    if (p.estagio === 0) return sprite('broto', SPRITES.broto, { balanco });
    const fase = p.estagio === 2 ? 'pronta' : 'crescendo';
    const nome = p.tipo + fase;
    return sprite(nome, SPRITES[p.tipo][fase], { balanco, fracaoBalanco: FRACAO_BALANCO[nome] });
  }

  // ---------- Estado ----------
  function estadoInicial() {
    return { moedas: 40, t: 0, pontos: {}, salvoEm: Date.now() };
  }

  function carregar() {
    try {
      const bruto = localStorage.getItem(CHAVE_SAVE);
      if (!bruto) return estadoInicial();
      const salvo = JSON.parse(bruto);
      if (typeof salvo.pontos !== 'object' || salvo.pontos === null) return estadoInicial();
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
  let ferramenta = 'violeta';
  let vasoEscolhido = 'barro';
  let hover = -1;
  let confirmacao = null; // { indice, acao, ate }
  const particulas = [];
  const textos = [];

  // ---------- Simulação ----------
  function gostoDeLuz(p, ponto) {
    return PLANTAS[p.tipo].luz[ponto.luz];
  }

  function avancar(dt) {
    estado.t += dt;
    for (const ponto of PONTOS) {
      const p = estado.pontos[ponto.id]?.planta;
      if (!p || p.mimoPronto) continue;
      const molhada = estado.t < p.molhadoAte;
      const encharcada = estado.t < p.encharcadoAte;
      if (!molhada || encharcada) continue;
      const def = PLANTAS[p.tipo];
      p.progresso += dt * gostoDeLuz(p, ponto);
      const precisa = p.estagio < 2 ? def.tempos[p.estagio] : def.mimo;
      if (p.progresso >= precisa) {
        p.progresso = 0;
        if (p.estagio < 2) p.estagio++;
        else p.mimoPronto = true;
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

  // Aconchego: plantas crescidas e felizes com a luz deixam a sala mais aconchegante, e vasos bonitos ajudam.
  function aconchego() {
    let total = 0;
    for (const ponto of PONTOS) {
      const v = estado.pontos[ponto.id];
      if (!v) continue;
      total += VASOS[v.vaso].charme;
      const p = v.planta;
      if (!p) continue;
      total += p.estagio;
      if (p.estagio === 2) {
        const luz = gostoDeLuz(p, ponto);
        total += luz === 1 ? 3 : luz >= 0.6 ? 1 : 0;
      }
    }
    return total;
  }

  // ---------- Ações ----------
  function texto(ponto, msg, cor = '#fff6d8') {
    textos.push({ x: ponto.x, y: ponto.y - 24, msg, cor, vida: 1.4 });
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
    const ponto = PONTOS[i];
    const v = estado.pontos[ponto.id];
    const p = v?.planta;

    // Planta com flores ou muda pronta: colhe com qualquer ferramenta
    if (p?.mimoPronto) {
      const def = PLANTAS[p.tipo];
      p.mimoPronto = false;
      estado.moedas += def.venda;
      texto(ponto, `+${def.venda}`, '#f6d861');
      brilho(ponto, 10);
      status(p.tipo === 'costela'
        ? `Você separou uma muda de costela de adão e vendeu por ${def.venda} moedas.`
        : `Você colheu ${p.tipo === 'rosa' ? 'rosas' : 'violetas'} e vendeu por ${def.venda} moedas.`);
      return salvar();
    }

    if (ferramenta === 'regador') {
      if (!p) return status('Coloque uma planta aqui antes de regar.');
      const def = PLANTAS[p.tipo];
      respingo(ponto);
      if (p.tipo === 'violeta' && estado.t < p.molhadoAte) {
        p.encharcadoAte = estado.t + ENCHARCADO_S;
        status('Ops, a violeta ficou encharcada. Ela para de crescer até a terra secar um pouco.');
        return salvar();
      }
      p.molhadoAte = estado.t + def.seca;
      status(`${def.nome} regada.`);
      return salvar();
    }

    if (ferramenta === 'tirar') {
      if (!v) return status('Não tem nada aqui.');
      const oque = p ? `a ${PLANTAS[p.tipo].nome.toLowerCase()}` : `o ${VASOS[v.vaso].nome.toLowerCase()}`;
      if (!confirmar(i, 'tirar', `Clique de novo para tirar ${oque} daqui.`)) return;
      delete estado.pontos[ponto.id];
      status('Espaço livre de novo.');
      return salvar();
    }

    if (ferramenta === 'vaso') {
      const vaso = VASOS[vasoEscolhido];
      if (v?.vaso === vasoEscolhido) return status(`Este já é um ${vaso.nome.toLowerCase()}.`);
      if (estado.moedas < vaso.preco) return status(`Faltam ${vaso.preco - estado.moedas} moedas para o ${vaso.nome.toLowerCase()}.`);
      estado.moedas -= vaso.preco;
      if (vaso.preco) texto(ponto, `-${vaso.preco}`, '#f7a1b5');
      estado.pontos[ponto.id] = { vaso: vasoEscolhido, planta: p || null };
      status(v ? `Trocou para ${vaso.nome.toLowerCase()}.` : `${vaso.nome} colocado. Agora escolha uma planta para ele.`);
      return salvar();
    }

    // Ferramenta é uma planta: vai no vaso que já está ali, ou num vaso novo do tipo escolhido
    const def = PLANTAS[ferramenta];
    if (p) return status('Este vaso já tem uma planta.');
    const vaso = v ? v.vaso : vasoEscolhido;
    const custo = def.preco + (v ? 0 : VASOS[vaso].preco);
    if (estado.moedas < custo) return status(`Faltam ${custo - estado.moedas} moedas para colocar ${def.nome.toLowerCase()} aqui.`);
    estado.moedas -= custo;
    estado.pontos[ponto.id] = { vaso, planta: { tipo: ferramenta, estagio: 0, progresso: 0, molhadoAte: 0, encharcadoAte: 0, mimoPronto: false } };
    texto(ponto, `-${custo}`, '#f7a1b5');
    const luz = def.luz[ponto.luz];
    const aviso = luz === 1 ? 'Ela adora essa luz!' : luz >= 0.6 ? 'A luz aqui é razoável para ela.' : 'Ela não gosta dessa luz e vai crescer bem devagar.';
    status(`${def.nome} colocada: ${ponto.nome.toLowerCase()}. ${aviso} Não esqueça de regar.`);
    salvar();
  }

  // ---------- Efeitos ----------
  function respingo(ponto) {
    for (let k = 0; k < 8; k++) {
      particulas.push({ x: ponto.x - 5 + Math.random() * 10, y: ponto.y - 22 - Math.random() * 4, vy: 25 + Math.random() * 20, vida: 0.5, cor: k % 2 ? '#5fa8d8' : '#a9dcf5' });
    }
  }

  function brilho(ponto, n) {
    for (let k = 0; k < n; k++) {
      particulas.push({ x: ponto.x - 6 + Math.random() * 12, y: ponto.y - 12 - Math.random() * 12, vy: -10 - Math.random() * 10, vida: 0.8, cor: k % 2 ? '#f6d861' : '#fff6d8' });
    }
  }

  // Poeirinha flutuando no feixe de sol
  const poeira = Array.from({ length: 14 }, (_, k) => ({ fase: k * 1.7, base: k / 14 }));

  // ---------- Desenho ----------
  const canvas = document.getElementById('sala');
  canvas.width = LARG * ESCALA;
  canvas.height = ALT * ESCALA;
  const ctx = canvas.getContext('2d');
  ctx.imageSmoothingEnabled = false;
  ctx.scale(ESCALA, ESCALA);

  const fundo = desenharSala();

  // Desenha um sprite com a base apoiada em (x, y), centralizado em x. Devolve a linha do topo.
  function desenharApoiado(c, x, y) {
    const larg = c.width - 2, alt = c.height - 2;
    ctx.drawImage(c, Math.round(x - larg / 2) - 1, y - alt - 1);
    return y - alt;
  }

  function caixaDoPonto(ponto) {
    return { x: ponto.x - 10, y: ponto.y - 30, w: 20, h: 32 };
  }

  function desenharPonto(ponto, i, quadro, agora) {
    const v = estado.pontos[ponto.id];
    if (!v) {
      // espaço livre: contorno de vaso piscando suavemente, com um +
      ctx.globalAlpha = 0.55 + 0.3 * Math.sin(agora / 450 + i);
      ctx.fillStyle = 'rgba(46, 42, 36, 0.35)';
      ctx.fillRect(ponto.x - 7, ponto.y - 8, 15, 9);
      ctx.strokeStyle = '#fff6d8';
      ctx.lineWidth = 1;
      ctx.setLineDash([2, 1]);
      ctx.strokeRect(ponto.x - 6.5, ponto.y - 7.5, 13, 7);
      ctx.setLineDash([]);
      ctx.fillStyle = '#fff6d8';
      ctx.fillRect(ponto.x - 2, ponto.y - 4, 5, 1);
      ctx.fillRect(ponto.x, ponto.y - 6, 1, 5);
      ctx.globalAlpha = 1;
    } else {
      const topoVaso = desenharApoiado(sprite('vaso-' + v.vaso, SPRITES.vasos[v.vaso]), ponto.x, ponto.y);
      const p = v.planta;
      if (p) {
        const molhada = estado.t < p.molhadoAte;
        const encharcada = estado.t < p.encharcadoAte;
        const balanco = BALANCO[(quadro + i) % BALANCO.length];
        const topoPlanta = desenharApoiado(spriteDaPlanta(p, balanco), ponto.x, topoVaso + 1);
        if (p.mimoPronto && (quadro + i) % 3 === 0) {
          ctx.fillStyle = '#fff6d8';
          const sx = ponto.x - 4 + ((i * 5) % 9), sy = topoPlanta + 2 + ((i * 3) % 4);
          ctx.fillRect(sx, sy - 1, 1, 3);
          ctx.fillRect(sx - 1, sy, 3, 1);
        }
        if (encharcada) {
          ctx.fillStyle = '#a9dcf5';
          const b = quadro % 2;
          ctx.fillRect(ponto.x - 8, topoVaso + 1 - b, 1, 1);
          ctx.fillRect(ponto.x + 8, topoVaso + b, 1, 1);
        } else if (!molhada) {
          ctx.drawImage(sprite('gota', SPRITES.gota), ponto.x + 6, topoPlanta - 6 - (quadro % 2));
        }
      }
    }

    if (i === hover) {
      const caixa = caixaDoPonto(ponto);
      ctx.strokeStyle = 'rgba(255, 246, 216, 0.8)';
      ctx.lineWidth = 1;
      ctx.strokeRect(caixa.x + 0.5, caixa.y + 0.5, caixa.w - 1, caixa.h - 1);
      ctx.drawImage(sprite('luz-' + ponto.luz, SPRITES.luz[ponto.luz]), caixa.x + 1, caixa.y + 1);
    }
  }

  function desenhar(agora) {
    const quadro = Math.floor(agora / QUADRO_MS);
    ctx.drawImage(fundo, 0, 0);
    desenharLuzDoSol(ctx, 1 + 0.08 * Math.sin(agora / 1600));

    // poeira no feixe de sol
    const J = SALA.JANELA;
    ctx.fillStyle = '#fff3b0';
    for (const d of poeira) {
      const tt = agora / 9000 + d.fase;
      const prog = (tt % 1 + d.base) % 1;
      const x = J.x + 10 + prog * 50 + Math.sin(tt * 6) * 3;
      const y = J.y + J.alt + 4 + prog * 60 + Math.cos(tt * 5) * 2;
      ctx.globalAlpha = 0.6 * Math.sin(prog * Math.PI);
      ctx.fillRect(Math.round(x), Math.round(y), 1, 1);
    }
    ctx.globalAlpha = 1;

    // brilho da TV ligada
    ctx.fillStyle = Math.floor(agora / 900) % 3 ? '#465d78' : '#4c6682';
    ctx.fillRect(201, 75, 34, 16);

    // gato respirando no sofá, soltando um "z" de vez em quando
    const respira = Math.floor(agora / 1100) % 2;
    desenharApoiado(sprite('gato' + respira, SPRITES.gato[respira]), 142, 101);
    const zt = (agora / 2400) % 1;
    if (zt < 0.6) {
      ctx.globalAlpha = 1 - zt / 0.6;
      ctx.fillStyle = '#fff6d8';
      ctx.font = '6px "Pixelify Sans", monospace';
      ctx.textAlign = 'left';
      ctx.fillText('z', 150 + zt * 6, 92 - zt * 10);
      ctx.globalAlpha = 1;
    }

    // pontos de vaso, de trás para a frente
    PONTOS.map((ponto, i) => [ponto, i])
      .sort((a, b) => a[0].y - b[0].y)
      .forEach(([ponto, i]) => desenharPonto(ponto, i, quadro, agora));

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
  const elAconchego = document.getElementById('aconchego');
  const elStatus = document.getElementById('status');
  const elInfo = document.getElementById('info');

  function status(msg) {
    elStatus.textContent = msg;
  }

  function descreverPonto(i) {
    if (i < 0) return 'Passe o mouse ou toque num espaço com + para ver a luz de cada canto.';
    const ponto = PONTOS[i];
    const v = estado.pontos[ponto.id];
    let txt = `${ponto.nome} · ${LUZES[ponto.luz].nome}`;
    if (!v) return txt + ' · livre';
    const p = v.planta;
    if (!p) return txt + ` · ${VASOS[v.vaso].nome.toLowerCase()} vazio`;
    const def = PLANTAS[p.tipo];
    const luz = def.luz[ponto.luz];
    txt += ` · ${def.nome}, ${ESTAGIOS[p.estagio].toLowerCase()}`;
    txt += luz === 1 ? ', feliz com a luz' : luz >= 0.6 ? ', luz razoável' : ', não gosta dessa luz';
    if (p.mimoPronto) txt += ', pronta para colher';
    else if (estado.t < p.encharcadoAte) txt += ', encharcada';
    else if (estado.t < p.molhadoAte) txt += `, terra molhada por mais ${Math.ceil(p.molhadoAte - estado.t)}s`;
    else txt += ', com sede';
    return txt;
  }

  function miniatura(nome, linhas) {
    return sprite(nome, linhas).toDataURL();
  }

  function botao(item, n) {
    const b = document.createElement('button');
    b.type = 'button';
    b.id = 'ferramenta-' + item.id;
    b.className = 'ferramenta';
    b.title = `${item.titulo} (tecla ${n})`;
    b.innerHTML = `<img src="${item.img}" alt=""><span class="rotulo">${item.rotulo}</span><span class="detalhe">${item.detalhe}</span>`;
    b.addEventListener('click', item.acao);
    return b;
  }

  function montarFerramentas() {
    const grupos = {
      plantas: Object.entries(PLANTAS).map(([id, def]) => ({
        id, rotulo: def.nome, detalhe: `${def.preco} moedas`, titulo: def.dica,
        img: miniatura(id + 'pronta', SPRITES[id].pronta), acao: () => escolher(id),
      })),
      vasos: Object.entries(VASOS).map(([id, def]) => ({
        id: 'vaso-' + id, rotulo: def.curto, detalhe: def.preco ? `${def.preco} moedas` : 'grátis',
        titulo: `Usa este vaso nas próximas plantas, ou clique num vaso da sala para trocar.${def.charme ? ' Deixa a sala mais aconchegante.' : ''}`,
        img: miniatura('vaso-' + id, SPRITES.vasos[id]), acao: () => escolherVaso(id),
      })),
      cuidados: [
        { id: 'regador', rotulo: 'Regador', detalhe: 'molha a terra', titulo: 'Plantas só crescem com a terra molhada.', img: miniatura('regador', SPRITES.regador), acao: () => escolher('regador') },
        { id: 'tirar', rotulo: 'Tirar', detalhe: 'libera o espaço', titulo: 'Remove o vaso e a planta. Pede confirmação.', img: miniatura('pa', SPRITES.pa), acao: () => escolher('tirar') },
      ],
    };
    const todos = [];
    for (const [grupo, itens] of Object.entries(grupos)) {
      const caixa = document.getElementById('grupo-' + grupo);
      for (const item of itens) {
        todos.push(item);
        caixa.appendChild(botao(item, todos.length));
      }
    }
    document.addEventListener('keydown', (e) => {
      const k = Number(e.key);
      if (k >= 1 && k <= todos.length) todos[k - 1].acao();
    });
  }

  function marcar() {
    document.querySelectorAll('.ferramenta').forEach((b) => {
      const ativo = b.id === 'ferramenta-' + ferramenta || (ferramenta === 'vaso' && b.id === 'ferramenta-vaso-' + vasoEscolhido);
      b.setAttribute('aria-pressed', String(ativo));
    });
  }

  function escolher(id) {
    ferramenta = id;
    marcar();
    if (PLANTAS[id]) status(`${PLANTAS[id].nome}: ${PLANTAS[id].dica}`);
    else if (id === 'regador') status('Regador na mão. Clique nas plantas com a gotinha de sede.');
    else status('Clique num vaso da sala para tirá-lo.');
  }

  function escolherVaso(id) {
    vasoEscolhido = id;
    ferramenta = 'vaso';
    marcar();
    status(`${VASOS[id].nome} escolhido. Clique num espaço livre para colocar, ou num vaso da sala para trocar.`);
  }

  function indiceNoPonto(evento) {
    const r = canvas.getBoundingClientRect();
    const x = ((evento.clientX - r.left) / r.width) * LARG;
    const y = ((evento.clientY - r.top) / r.height) * ALT;
    // quando as caixas se sobrepõem, ganha o ponto mais à frente
    let achado = -1;
    PONTOS.forEach((ponto, i) => {
      const c = caixaDoPonto(ponto);
      const dentro = x >= c.x && x < c.x + c.w && y >= c.y && y < c.y + c.h;
      if (dentro && (achado < 0 || ponto.y > PONTOS[achado].y)) achado = i;
    });
    return achado;
  }

  canvas.addEventListener('pointermove', (e) => { hover = indiceNoPonto(e); });
  canvas.addEventListener('pointerleave', () => { hover = -1; });
  canvas.addEventListener('pointerdown', (e) => {
    const i = indiceNoPonto(e);
    hover = i;
    if (i >= 0) clicar(i);
  });

  document.getElementById('recomecar').addEventListener('click', () => {
    if (!confirmar(-2, 'recomecar', 'Clique de novo em "Recomeçar" para esvaziar a sala e começar do zero.')) return;
    estado = estadoInicial();
    salvar();
    status('Sala vazia de novo. Que tal uma violeta na prateleira?');
  });

  // ---------- Laço principal ----------
  let anterior = performance.now();
  let ultimoSave = anterior;

  function laco(agora) {
    const dt = (agora - anterior) / 1000;
    anterior = agora;
    if (dt > 1) recuperarTempo(dt); // a aba ficou em segundo plano
    else avancar(dt);
    atualizarEfeitos(Math.min(dt, 0.1));
    desenhar(agora);

    elMoedas.textContent = estado.moedas;
    elAconchego.textContent = aconchego();
    elInfo.textContent = descreverPonto(hover);
    if (agora - ultimoSave > 5000) { salvar(); ultimoSave = agora; }
    requestAnimationFrame(laco);
  }

  document.getElementById('icone-moeda').src = miniatura('moeda', SPRITES.moeda);
  document.getElementById('icone-aconchego').src = miniatura('coracao', SPRITES.coracao);
  montarFerramentas();
  escolher('violeta');
  status(Object.keys(estado.pontos).length
    ? 'Bem-vindo de volta! Suas plantas continuaram crescendo.'
    : 'Escolha uma planta e clique num espaço com + na sala. Cada canto tem uma luz diferente.');
  window.addEventListener('beforeunload', salvar);
  requestAnimationFrame(laco);
})();
