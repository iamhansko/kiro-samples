// DOM 요소
const canvas = document.getElementById('game-canvas');
const ctx = canvas.getContext('2d');
const currentPlayerDisplay = document.getElementById('current-player');
const powerDisplay = document.getElementById('power-display');
const countP1Display = document.getElementById('count-p1');
const countP2Display = document.getElementById('count-p2');
const roundDisplay = document.getElementById('round-number');
const scoreP1Display = document.getElementById('score-p1');
const scoreP2Display = document.getElementById('score-p2');
const resetBtn = document.getElementById('reset-btn');
const guideBtn = document.getElementById('guide-btn');
const modal = document.getElementById('guide-modal');
const modalCloseBtn = document.getElementById('modal-close');

// 상수
const SIZE = 480;
const GRID = SIZE / 18;

// 캔버스 초기화
canvas.width = SIZE;
canvas.height = SIZE;

// 게임 상태
let state = {
  player: 1,
  selected: null,
  dragging: false,
  dragStart: { x: 0, y: 0 },
  dragEnd: { x: 0, y: 0 },
  pieces: [],
  animating: false,
  round: 1,
  wins: [0, 0],
  first: 1
};

// 말 클래스
class Piece {
  constructor(x, y, player, num) {
    this.x = x;
    this.y = y;
    this.player = player;
    this.num = num;
    this.vx = 0;
    this.vy = 0;
    this.active = true;
  }

  draw() {
    if (!this.active) return;
    ctx.beginPath();
    ctx.arc(this.x, this.y, 10, 0, Math.PI * 2);
    ctx.fillStyle = this.player === 1 ? '#2196F3' : '#F44336';
    ctx.strokeStyle = this.player === 1 ? '#1976D2' : '#C62828';
    ctx.fill();
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.fillStyle = '#fff';
    ctx.font = 'bold 8px Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(this.num, this.x, this.y);
  }

  update() {
    if (!this.active) return;
    this.x += this.vx;
    this.y += this.vy;
    this.vx *= 0.98;
    this.vy *= 0.98;
    if (this.x < 10 || this.x > SIZE - 10 || this.y < 10 || this.y > SIZE - 10) {
      this.active = false;
      this.vx = this.vy = 0;
    }
    if (Math.abs(this.vx) < 0.1 && Math.abs(this.vy) < 0.1) {
      this.vx = this.vy = 0;
    }
  }

  moving() {
    return Math.abs(this.vx) > 0.1 || Math.abs(this.vy) > 0.1;
  }
}

// 게임 초기화
const initGame = () => {
  state.pieces = [];
  state.player = state.first;
  state.selected = null;
  state.animating = false;

  let num = 1;
  for (let r = 0; r < 17; r++) {
    for (let c = 0; c < 3; c++) {
      state.pieces.push(new Piece((1 + c) * GRID, (1 + r) * GRID, 1, num++));
    }
  }

  num = 1;
  for (let r = 0; r < 17; r++) {
    for (let c = 0; c < 3; c++) {
      state.pieces.push(new Piece((15 + c) * GRID, (1 + r) * GRID, 2, num++));
    }
  }

  updateDisplay();
};

// 게임 리셋
const resetGame = () => {
  state.round = 1;
  state.wins = [0, 0];
  state.first = 1;
  initGame();
};

// 충돌 처리
const handleCollisions = () => {
  for (let i = 0; i < state.pieces.length; i++) {
    for (let j = i + 1; j < state.pieces.length; j++) {
      const p1 = state.pieces[i];
      const p2 = state.pieces[j];
      if (!p1.active || !p2.active) continue;

      const dx = p2.x - p1.x;
      const dy = p2.y - p1.y;
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist < 20) {
        const angle = Math.atan2(dy, dx);
        const sin = Math.sin(angle);
        const cos = Math.cos(angle);
        const vx1 = p1.vx * cos + p1.vy * sin;
        const vy1 = p1.vy * cos - p1.vx * sin;
        const vx2 = p2.vx * cos + p2.vy * sin;
        const vy2 = p2.vy * cos - p2.vx * sin;
        p1.vx = vx2 * cos - vy1 * sin;
        p1.vy = vy1 * cos + vx2 * sin;
        p2.vx = vx1 * cos - vy2 * sin;
        p2.vy = vy2 * cos + vx1 * sin;
        const overlap = 20 - dist;
        p1.x -= overlap * cos * 0.5;
        p1.y -= overlap * sin * 0.5;
        p2.x += overlap * cos * 0.5;
        p2.y += overlap * sin * 0.5;
      }
    }
  }
};

// 화면 업데이트
const updateDisplay = () => {
  currentPlayerDisplay.textContent = `P${state.player}`;
  currentPlayerDisplay.style.color = state.player === 1 ? '#2196F3' : '#F44336';
  countP1Display.textContent = state.pieces.filter(p => p.player === 1 && p.active).length;
  countP2Display.textContent = state.pieces.filter(p => p.player === 2 && p.active).length;
  roundDisplay.textContent = state.round;
  scoreP1Display.textContent = state.wins[0];
  scoreP2Display.textContent = state.wins[1];
};

// 승리 확인
const checkWin = () => {
  const p1 = state.pieces.filter(p => p.player === 1 && p.active).length;
  const p2 = state.pieces.filter(p => p.player === 2 && p.active).length;

  if (p1 === 0) {
    state.wins[1]++;
    setTimeout(() => {
      alert(`Round ${state.round} - P2 Wins`);
      checkEnd();
    }, 100);
    return true;
  }
  if (p2 === 0) {
    state.wins[0]++;
    setTimeout(() => {
      alert(`Round ${state.round} - P1 Wins`);
      checkEnd();
    }, 100);
    return true;
  }
  return false;
};

// 게임 종료 확인
const checkEnd = () => {
  if (state.round >= 4) {
    const msg = state.wins[0] > state.wins[1] ? `🎉 Winner: P1 (${state.wins[0]}W ${state.wins[1]}L)` :
                state.wins[1] > state.wins[0] ? `🎉 Winner: P2 (${state.wins[1]}W ${state.wins[0]}L)` :
                `🤝 Draw (${state.wins[0]}W ${state.wins[1]}L)`;
    setTimeout(() => alert(msg), 200);
    setTimeout(() => resetGame(), 400);
  } else {
    state.round++;
    state.first = state.first === 1 ? 2 : 1;
    setTimeout(() => initGame(), 300);
  }
};

// 게임 루프
const gameLoop = () => {
  ctx.clearRect(0, 0, SIZE, SIZE);

  // 보드
  ctx.strokeStyle = '#ddd';
  ctx.lineWidth = 1;
  for (let i = 0; i <= 18; i++) {
    const pos = i * GRID;
    ctx.beginPath();
    ctx.moveTo(pos, 0);
    ctx.lineTo(pos, SIZE);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(0, pos);
    ctx.lineTo(SIZE, pos);
    ctx.stroke();
  }

  // 말
  let moving = false;
  state.pieces.forEach(p => {
    p.update();
    p.draw();
    if (p.moving()) moving = true;
  });

  handleCollisions();

  // 선택 강조
  if (state.selected && !state.animating) {
    ctx.beginPath();
    ctx.arc(state.selected.x, state.selected.y, 15, 0, Math.PI * 2);
    ctx.strokeStyle = '#FFD700';
    ctx.lineWidth = 3;
    ctx.stroke();
  }

  // 화살표
  if (state.dragging && state.selected) {
    const dx = state.dragEnd.x - state.dragStart.x;
    const dy = state.dragEnd.y - state.dragStart.y;
    const dist = Math.sqrt(dx * dx + dy * dy);
    powerDisplay.textContent = Math.round(Math.min(dist / 2, 100));

    const angle = Math.atan2(-dy, -dx);
    const ex = state.selected.x + Math.cos(angle) * 20;
    const ey = state.selected.y + Math.sin(angle) * 20;

    ctx.beginPath();
    ctx.moveTo(state.selected.x, state.selected.y);
    ctx.lineTo(ex, ey);
    ctx.strokeStyle = '#FFD700';
    ctx.lineWidth = 2;
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(ex, ey);
    ctx.lineTo(ex - 5 * Math.cos(angle - Math.PI / 6), ey - 5 * Math.sin(angle - Math.PI / 6));
    ctx.lineTo(ex - 5 * Math.cos(angle + Math.PI / 6), ey - 5 * Math.sin(angle + Math.PI / 6));
    ctx.closePath();
    ctx.fillStyle = '#FFD700';
    ctx.fill();
  }

  // 애니메이션 종료
  if (state.animating && !moving) {
    state.animating = false;
    if (!checkWin()) {
      state.player = state.player === 1 ? 2 : 1;
      updateDisplay();
    }
  } else if (state.animating) {
    updateDisplay();
  }

  requestAnimationFrame(gameLoop);
};

// 마우스 다운
canvas.addEventListener('mousedown', (e) => {
  if (state.animating) return;
  const rect = canvas.getBoundingClientRect();
  const x = e.clientX - rect.left;
  const y = e.clientY - rect.top;

  for (const p of state.pieces) {
    if (!p.active || p.player !== state.player) continue;
    const dx = x - p.x;
    const dy = y - p.y;
    if (Math.sqrt(dx * dx + dy * dy) < 10) {
      state.selected = p;
      state.dragging = true;
      state.dragStart = { x, y };
      state.dragEnd = { x, y };
      break;
    }
  }
});

// 마우스 이동
const handleMove = (e) => {
  if (!state.dragging) return;
  const rect = canvas.getBoundingClientRect();
  state.dragEnd = { x: e.clientX - rect.left, y: e.clientY - rect.top };
};

canvas.addEventListener('mousemove', handleMove);
document.addEventListener('mousemove', handleMove);

// 마우스 업
const handleUp = () => {
  if (!state.dragging || !state.selected) return;
  const dx = state.dragEnd.x - state.dragStart.x;
  const dy = state.dragEnd.y - state.dragStart.y;
  const dist = Math.sqrt(dx * dx + dy * dy);

  if (dist > 5) {
    const power = Math.min(dist / 200, 1) * 40;
    const angle = Math.atan2(dy, dx);
    state.selected.vx = -Math.cos(angle) * power;
    state.selected.vy = -Math.sin(angle) * power;
    state.animating = true;
  }

  state.dragging = false;
  state.selected = null;
  powerDisplay.textContent = '0';
};

canvas.addEventListener('mouseup', handleUp);
document.addEventListener('mouseup', handleUp);

// 모달
guideBtn.addEventListener('click', () => modal.style.display = 'block');
modalCloseBtn.addEventListener('click', () => modal.style.display = 'none');
window.addEventListener('click', (e) => {
  if (e.target === modal) modal.style.display = 'none';
});
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') modal.style.display = 'none';
});

// 리셋
resetBtn.addEventListener('click', resetGame);

// 시작
initGame();
gameLoop();
