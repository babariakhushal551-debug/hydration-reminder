/* HydroFlow web preview — mirrors the SwiftUI app's state and screens. */

// ---------- State (mirrors HydrationStore) ----------
const ML_PER_OZ = 29.5735;
const state = {
  unit: 'oz',                       // 'oz' | 'ml'
  goalML: 2660, customGoalML: null,
  entries: [],                      // {id, date:Date, bev, ml, factor, container}
  streakBase: 6,                    // seeded streak from "previous days"
  reminders: true, intervalH: 1.5, customIntervalMin: null,
  activeStart: 8, activeEnd: 22,
  sound: 'default', soundVolume: 0.8,
  bedtime: true, weather: true, haptics: true,
};
const baseGoal = () => state.customGoalML ?? 2660;
let bevCatalog = [
  { id:'water',     name:'Pure Water',        factor:1.00, preset:240, icon:'💧', tint:'#007AFF' },
  { id:'sparkling', name:'Sparkling Water',   factor:1.00, preset:355, icon:'🫧', tint:'#00C7BE' },
  { id:'electro',   name:'Electrolyte Drink', factor:1.10, preset:473, icon:'⚡', tint:'#00C7BE' },
  { id:'tea',       name:'Green / Herbal Tea',factor:0.90, preset:240, icon:'🍃', tint:'#00C7BE' },
  { id:'coffee',    name:'Iced / Hot Coffee', factor:0.80, preset:180, icon:'☕', tint:'#5856D6' },
  { id:'coconut',   name:'Coconut Water',     factor:0.95, preset:330, icon:'🥥', tint:'#00C7BE' },
  { id:'juice',     name:'Fruit Juice',       factor:0.90, preset:240, icon:'🧃', tint:'#ff9500' },
  { id:'milk',      name:'Milk',              factor:0.90, preset:240, icon:'🥛', tint:'#00C7BE' },
  { id:'soda',      name:'Soft Drink',        factor:0.85, preset:355, icon:'🥤', tint:'#5856D6' },
  { id:'energy',    name:'Energy Drink',      factor:0.75, preset:250, icon:'🔥', tint:'#5856D6' },
  { id:'alcohol',   name:'Alcohol',           factor:0.30, preset:355, icon:'🍷', tint:'#5856D6' },
  { id:'custom',    name:'Custom Beverage',   factor:1.00, preset:240, icon:'🧪', tint:'#7c4dd4' },
];
let containers = [
  { id: uid(), name:'Cup',    bev:'water',   ml:240, icon:'🥛' },
  { id: uid(), name:'Glass',  bev:'water',   ml:355, icon:'🫗' },
  { id: uid(), name:'Mug',    bev:'tea',     ml:473, icon:'🍵' },
  { id: uid(), name:'Bottle', bev:'water',   ml:710, icon:'🍶' },
  { id: uid(), name:'Jug',    bev:'electro', ml:950, icon:'🧺' },
];
const vessels = containers; // today shelf renders from the editable presets

// ---------- Helpers ----------
const $ = (s) => document.querySelector(s);
const uid = () => Math.random().toString(36).slice(2);
const toUnit = (ml) => state.unit === 'oz' ? ml / ML_PER_OZ : ml;
const fmt = (ml) => Math.round(toUnit(ml));
const unitSym = () => state.unit === 'oz' ? 'oz' : 'ml';
const todayKey = (d = new Date()) => d.toISOString().slice(0, 10);
const entriesToday = () => state.entries.filter(e => todayKey(e.date) === todayKey());
const totalToday = () => entriesToday().reduce((s, e) => s + e.ml * e.factor, 0);
const progress = () => Math.min(totalToday() / state.goalML, 1.2);
const fmtTime = (d) => d.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
const goalML = () => baseGoal();

// iOS system sounds (matched to SoundManager's friendly names).
const SOUND_LIBRARY = [
  { id:'default',    name:'System Default', file:'Ping' },
  { id:'bundled:water_drop.wav', name:'Water Drop', file:'Drip' },
  { id:'bundled:gentle_ripple.wav', name:'Gentle Ripple', file:'Ripple' },
  { id:'bundled:glass_chime.wav', name:'Glass Chime', file:'Chime' },
  { id:'system:sms-received1.caf', name:'Tri-tone', file:'Tri-tone' },
  { id:'system:sms-received2.caf', name:'Chord', file:'Chord' },
  { id:'system:sms-received4.caf', name:'Glass', file:'Glass' },
  { id:'system:sms-received5.caf', name:'Bell', file:'Bell' },
  { id:'system:new-mail.caf', name:'New Mail', file:'Mail' },
  { id:'system:fanfare.caf', name:'Fanfare', file:'Fanfare' },
  { id:'system:complete.caf', name:'Complete', file:'Complete' },
  { id:'system:waterdrip.caf', name:'Water Drip', file:'Waterdrip' },
];
function previewSound(id) {
  const opt = SOUND_LIBRARY.find(s => s.id === id) || SOUND_LIBRARY[0];
  try {
    const ctx = previewSound.ctx = previewSound.ctx || new (window.AudioContext || window.webkitAudioContext)();
    if (ctx.state === 'suspended') ctx.resume();
    const vol = state.soundVolume;
    const tone = (freq, start, dur, type = 'sine') => {
      const o = ctx.createOscillator(), g = ctx.createGain();
      o.type = type; o.frequency.value = freq;
      g.gain.setValueAtTime(0, ctx.currentTime + start);
      g.gain.linearRampToValueAtTime(vol * 0.5, ctx.currentTime + start + 0.015);
      g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + start + dur);
      o.connect(g).connect(ctx.destination);
      o.start(ctx.currentTime + start); o.stop(ctx.currentTime + start + dur + 0.05);
    };
    switch (opt.file) {
      case 'Drip':     tone(1200, 0, 0.28, 'sine'); break;
      case 'Ripple':   tone(523, 0, 0.5); tone(784, 0.12, 0.5); break;
      case 'Chime':    tone(1318, 0, 0.7); tone(1975, 0.02, 0.5, 'triangle'); break;
      case 'Tri-tone': tone(830, 0, 0.12); tone(1245, 0.13, 0.18); break;
      case 'Chord':    tone(523, 0, 0.5); tone(659, 0, 0.5); tone(784, 0, 0.5); break;
      case 'Glass':    tone(988, 0, 0.35, 'triangle'); tone(1480, 0.05, 0.4, 'triangle'); break;
      case 'Bell':     tone(1174, 0, 0.6); break;
      case 'Mail':     tone(660, 0, 0.18); tone(880, 0.1, 0.3); break;
      case 'Fanfare':  tone(523, 0, 0.2); tone(659, 0.15, 0.2); tone(784, 0.3, 0.35); break;
      case 'Complete': tone(784, 0, 0.15); tone(1046, 0.12, 0.3); break;
      case 'Waterdrip':tone(900, 0, 0.3); tone(600, 0.15, 0.25); break;
      default:         tone(880, 0, 0.25);
    }
  } catch (_) { /* audio unavailable */ }
}

function seedDemoData() {
  const now = Date.now();
  state.entries.push(
    { id: uid(), date: new Date(now - 6.2 * 36e5), bev: 'water',   ml: 473, factor: 1.00, container: 'Glass Bottle' },
    { id: uid(), date: new Date(now - 2.4 * 36e5), bev: 'electro', ml: 710, factor: 1.10, container: 'Workout Flask' },
  );
}

// ---------- Confetti ----------
function fireConfetti() {
  const canvas = $('#confetti');
  const ctx = canvas.getContext('2d');
  canvas.width = canvas.offsetWidth; canvas.height = canvas.offsetHeight;
  const parts = Array.from({ length: 110 }, (_, i) => ({
    x: Math.random() * canvas.width, y: -20 - Math.random() * canvas.height * 0.4,
    vx: (Math.random() - 0.5) * 1.6, vy: 2 + Math.random() * 2.6,
    w: 5 + Math.random() * 6, rot: Math.random() * Math.PI, vr: (Math.random() - 0.5) * 0.25,
    color: ['#007AFF', '#00C7BE', '#5856D6', '#FFD60A', '#FF375F', '#63E6E2'][i % 6],
  }));
  const t0 = performance.now();
  (function frame(t) {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    parts.forEach(p => {
      p.x += p.vx; p.y += p.vy; p.rot += p.vr;
      ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.rot);
      ctx.fillStyle = p.color; ctx.fillRect(-p.w / 2, -p.w / 3, p.w, p.w * 0.62);
      ctx.restore();
    });
    if (t - t0 < 2800) requestAnimationFrame(frame);
    else ctx.clearRect(0, 0, canvas.width, canvas.height);
  })(t0);
}

let toastTimer;
function toast(msg) {
  $('#toast-text').textContent = msg;
  $('#toast').classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => $('#toast').classList.remove('show'), 1900);
}

function haptic() { if (state.haptics && navigator.vibrate) navigator.vibrate(12); }

// ---------- Logging ----------
let wasGoalMet = false;
function logDrink(bevId, ml, container) {
  const bev = bevCatalog.find(b => b.id === bevId);
  state.entries.push({ id: uid(), date: new Date(), bev: bevId, ml, factor: bev.factor, container });
  haptic();
  toast(`+${fmt(ml)} ${unitSym()} ${bev.name} logged`);
  renderAll();
  if (!wasGoalMet && totalToday() >= goalML()) {
    wasGoalMet = true;
    fireConfetti();
  }
  if (totalToday() < goalML()) wasGoalMet = false;
}

// ---------- Goal editor ----------
let goalDraft = 2660;
function openGoalEditor() {
  goalDraft = baseGoal();
  renderGoalSheet();
  $('#goal-sheet').style.display = 'flex';
  requestAnimationFrame(() => $('#goal-sheet').classList.add('open'));
}
function closeGoalEditor() {
  $('#goal-sheet').classList.remove('open');
  setTimeout(() => { $('#goal-sheet').style.display = 'none'; }, 250);
}
function renderGoalSheet() {
  $('#goal-val').textContent = fmt(goalDraft);
  $('#goal-slider').value = toUnit(goalDraft);
  $('#goal-log').textContent = `Set ${fmt(goalDraft)} ${unitSym()} Goal`;
}
function goalNudge(dir) {
  const step = state.unit === 'oz' ? ML_PER_OZ : 250;
  goalDraft = Math.min(Math.max(goalDraft + dir * step, 1000), 5000);
  haptic(); renderGoalSheet();
}
function goalSlider(val) {
  const ml = state.unit === 'oz' ? val * ML_PER_OZ : val;
  goalDraft = Math.round(ml / 50) * 50;
  haptic(); renderGoalSheet();
}
function goalSave() {
  state.customGoalML = goalDraft;
  haptic(); toast(`Daily goal set to ${fmt(goalDraft)} ${unitSym()}`);
  closeGoalEditor(); renderAll();
}
function goalReset() {
  state.customGoalML = null;
  haptic(); toast('Using profile recommendation');
  closeGoalEditor(); renderAll();
}
function quickAdjustGoal(deltaML) {
  state.customGoalML = Math.min(Math.max(baseGoal() + deltaML, 1000), 5000);
  haptic(); toast(`Daily goal: ${fmt(state.customGoalML)} ${unitSym()}`);
  renderAll();
}

// ---------- Sheet ----------
function openSheet(bevId = null, ml = null) {
  sheetSel = bevId || lastBeverage;
  sheetML = ml || bevCatalog.find(b => b.id === sheetSel).preset;
  renderSheet();
  $('#phone').classList.add('sheet-open');
}
function closeSheet() { $('#phone').classList.remove('sheet-open'); }
$('#sheet-back').addEventListener('click', closeSheet);

let sheetSel = 'water', sheetML = 240, lastBeverage = 'water';
const presets = [120, 240, 355, 473, 710, 950];

function renderSheet() {
  const bev = bevCatalog.find(b => b.id === sheetSel);
  $('#sheet-body').innerHTML = `
    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
        <span class="eyebrow" style="color:var(--label2)">TARGET INTAKE</span>
        <span class="cap" style="color:var(--brand);font-weight:700">💧 Real-time Fluid</span>
      </div>
      <div style="display:flex;align-items:center;justify-content:center;gap:20px;padding:8px 0">
        <div class="pour-bottle" id="pour-bottle">
          <div class="water" id="pour-water" style="height:${(26 + Math.min(sheetML / 1000, 1) * 72).toFixed(1)}%"></div>
          <div class="pour-center">
            <div class="num">${fmt(sheetML)}<small> ${unitSym()}</small><div class="cap-b" style="color:var(--brand)">${Math.round(sheetML)} ml</div></div>
            <div class="hint">DRAG TO POUR</div>
          </div>
        </div>
        <div style="display:flex;flex-direction:column;align-items:center;gap:12px">
          <button class="stepper-btn" onclick="nudge(1)">+</button>
          <div style="text-align:center;min-width:64px">
            <div style="font-size:30px;font-weight:800;line-height:1">${fmt(sheetML)}<span style="font-size:14px;color:var(--label2)"> ${unitSym()}</span></div>
            <div class="cap-b" style="color:var(--brand);margin-top:2px">${Math.round(sheetML)} ml</div>
          </div>
          <button class="stepper-btn" onclick="nudge(-1)">−</button>
        </div>
      </div>
      <div style="display:flex;gap:8px;overflow-x:auto;padding:6px 0;scrollbar-width:none">
        ${presets.map(p => `<button class="chip ${Math.abs(sheetML - p) < 1 ? 'on' : ''}" onclick="setPreset(${p})">${fmt(p)} ${unitSym()}</button>`).join('')}
      </div>
    </div>
    <div style="display:flex;justify-content:space-between;padding:0 4px 8px">
      <span class="eyebrow" style="color:var(--label2)">BEVERAGE TYPE</span>
      <span class="cap" style="color:var(--brand)">Hydration Index</span>
    </div>
    <div class="card" style="padding:4px 16px">
      ${bevCatalog.map(b => `
        <div class="row" onclick="pickBev('${b.id}')" style="cursor:pointer">
          <div class="tile" style="background:${b.tint}1f;color:${b.tint}">${b.icon}</div>
          <div style="flex:1">
            <div class="body-b" style="font-size:15px">${b.name}</div>
            <div class="cap" style="display:flex;gap:6px;align-items:center;margin-top:2px">
              <span style="background:${b.tint}14;color:${b.tint};font-weight:700;border-radius:4px;padding:1px 5px">${Math.round(b.factor * 100)}% hydration</span>
              <span>${fmt(b.preset)} ${unitSym()} preset</span>
            </div>
          </div>
          <span style="color:var(--brand);font-weight:800">${b.id === sheetSel ? '✓' : '›'}</span>
        </div>`).join('')}
    </div>
    <button class="btn-grad" style="margin-top:4px" onclick="sheetLog()">
      💧 Log ${fmt(sheetML)} ${unitSym()} ${bev.name}
    </button>`;
}
function nudge(dir) {
  const step = state.unit === 'oz' ? ML_PER_OZ : 50;
  haptic();
  sheetML = Math.min(Math.max(sheetML + dir * step, 30), 2000);
  renderSheet();
}
function setPreset(p) { haptic(); sheetML = p; renderSheet(); }
function pickBev(id) {
  haptic();
  sheetSel = id; sheetML = bevCatalog.find(b => b.id === id).preset;
  renderSheet();
}
const _origRenderSheet = renderSheet;
renderSheet = function () { _origRenderSheet(); setupPourDrag(); };

// Drag the water level inside the pour bottle to set the amount.
function setupPourDrag() {
  const bottle = $('#pour-bottle');
  if (!bottle) return;
  const step = state.unit === 'oz' ? ML_PER_OZ : 50;
  const setFromY = (clientY) => {
    const rect = bottle.getBoundingClientRect();
    const raw = 1 - (clientY - rect.top) / rect.height;   // top = full
    const clamped = Math.min(Math.max(raw, 0), 1);
    const snapped = Math.round((clamped * 1000) / step) * step;
    sheetML = Math.min(Math.max(snapped, 30), 2000);
    haptic();
    renderSheet();
  };
  bottle.onpointerdown = (e) => {
    bottle.setPointerCapture(e.pointerId);
    setFromY(e.clientY);
    bottle.onpointermove = (ev) => setFromY(ev.clientY);
    bottle.onpointerup = () => { bottle.onpointermove = null; };
  };
}
function sheetLog() {
  lastBeverage = sheetSel;
  logDrink(sheetSel, sheetML, 'Custom log');
  setTimeout(closeSheet, 550);
}

// ---------- Screens ----------
function renderToday() {
  const tot = totalToday(), prog = progress(), pct = Math.round(prog * 100);
  const remaining = Math.max(0, goalML() - tot);
  const last = entriesToday().sort((a, b) => b.date - a.date)[0];
  const glasses = (remaining / 240).toFixed(1);
  const today = entriesToday().sort((a, b) => b.date - a.date);
  const streak = state.streakBase + (tot >= goalML() ? 1 : 0);
  const topPct = streak >= 30 ? '1%' : streak >= 14 ? '5%' : streak >= 7 ? '10%' : streak >= 3 ? '25%' : '50%';

  $('#screen-today').innerHTML = `
    <div style="display:flex;align-items:center;gap:10px;padding:12px 0 2px">
      <div class="tile" style="background:rgba(0,122,255,.12);width:38px;height:38px;border-radius:12px">💧</div>
      <div style="flex:1;min-width:0">
        <div class="body-b">Today, ${new Date().toLocaleDateString([], { month: 'short', day: 'numeric' })}</div>
        <div style="font-size:11.5px;font-weight:700;color:#ff9500">🔥 ${streak} Day Streak <span style="color:var(--label2);font-weight:600">• Top ${topPct}</span></div>
      </div>
      <div style="display:flex;align-items:center;gap:5px;background:#fff;border-radius:99px;padding:3px;box-shadow:0 1px 3px rgba(0,0,0,.07)">
        <button onclick="quickAdjustGoal(-250)" style="width:26px;height:26px;border-radius:50%;border:none;background:rgba(0,122,255,.08);color:var(--label1);font-weight:800;cursor:pointer">−</button>
        <button onclick="openGoalEditor()" style="border:none;background:none;color:var(--brand);font-weight:800;font-size:11.5px;cursor:pointer">${fmt(baseGoal())}${unitSym()}</button>
        <button onclick="quickAdjustGoal(250)" style="width:26px;height:26px;border-radius:50%;border:none;background:var(--azure);color:#fff;font-weight:800;cursor:pointer">+</button>
      </div>
      <button class="tile" style="background:#fff;box-shadow:0 1px 3px rgba(0,0,0,.07)" onclick="showTab('analytics')">📅</button>
    </div>

    <div class="card" style="background:linear-gradient(90deg,rgba(0,122,255,.10),rgba(0,199,190,.10),#fff);display:flex;align-items:center;gap:10px">
      <div class="tile" style="background:var(--azure);color:#fff">💧</div>
      <div style="flex:1">
        <div class="eyebrow">HYDRATION RHYTHM • <span style="color:var(--aqua)">Optimal</span></div>
        <div style="font-size:12.5px;font-weight:600;margin-top:2px">Next recommended sip in ${nextSipMins()} mins</div>
      </div>
      <span class="cap">›</span>
    </div>

    <div class="card">
      <div class="bottle-row">
        <div class="bottle">
          <div class="water" style="height:${(26 + Math.min(prog, 1) * 72).toFixed(1)}%"></div>
          ${[25, 50, 75].map(f => `<div class="bottle-tick" style="top:${(26 + f / 100 * 72).toFixed(1)}%"><i></i>${f}%</div>`).join('')}
        </div>
        <div class="bottle-info">
          <div>
            <div class="big">${fmt(tot)}<small> ${unitSym()}</small></div>
            <div class="cap" style="margin-top:3px">of ${fmt(goalML())} ${unitSym()} goal</div>
          </div>
          <div class="pbar"><i style="width:${Math.min(pct, 100)}%"></i></div>
          <div style="display:flex;gap:6px;align-items:center">
            <b style="background:var(--azure);color:#fff;font-size:11px;border-radius:99px;padding:2px 8px">${pct}%</b>
            <span style="font-size:14px">${prog >= 1 ? '✅' : '💧'}</span>
          </div>
          <div class="cap-b" style="background:rgba(0,122,255,.07);border-radius:12px;padding:6px 10px">
            ${remaining <= 0 ? '🎉 Goal complete!' : `💧 ${fmt(remaining)} ${unitSym()} to go`}
          </div>
        </div>
      </div>
    </div>

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
      <div class="card" style="margin:0">
        <div style="display:flex;gap:8px;align-items:center"><div class="tile" style="background:rgba(0,122,255,.14)">🕐</div><span class="cap">LAST DRINK</span></div>
        <div class="body-b" style="margin-top:8px">${last ? `${fmt(last.ml)} ${unitSym()} ${bevCatalog.find(b => b.id === last.bev).name}` : 'No drinks yet'}</div>
        <div class="cap" style="margin-top:2px">${last ? `${fmtTime(last.date)} • ${last.container}` : 'Log your first sip!'}</div>
      </div>
      <div class="card" style="margin:0">
        <div style="display:flex;gap:8px;align-items:center"><div class="tile" style="background:rgba(0,199,190,.14)">🎯</div><span class="cap">DAILY TARGET</span></div>
        <div class="body-b" style="margin-top:8px">${fmt(remaining)} ${unitSym()} left</div>
        <div class="cap" style="margin-top:2px;color:var(--aqua);font-weight:700">approx. ${glasses} glasses</div>
      </div>
    </div>

    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center">
        <span class="body-b">⚡ Quick One-Tap Log</span><span class="cap">Instant Add</span>
      </div>
      <div class="vessels">
        ${vessels.map(v => `
          <button class="vessel" onclick="logDrink('${v.bev}', ${v.ml}, '${v.name}')">
            <span class="vi">${v.icon}</span><b>+${fmt(v.ml)} ${unitSym()}</b><span>${v.name}</span>
          </button>`).join('')}
      </div>
      <div style="display:flex;gap:8px;align-items:stretch;margin-top:14px">
        <button class="chip" style="flex:1;display:flex;flex-direction:column;gap:2px;padding:10px 6px" onclick="openSheet()">
          <span style="font-size:15px">⚙</span><span style="font-size:10.5px;font-weight:600">Custom</span>
        </button>
        <button class="btn-grad" style="width:auto;height:auto;padding:12px 18px;display:flex;align-items:center;gap:7px;white-space:nowrap" onclick="logDrink('${vessels[0].bev}',${vessels[0].ml},'${vessels[0].name}')">
          <span style="background:rgba(255,255,255,.25);border-radius:50%;width:22px;height:22px;display:inline-flex;align-items:center;justify-content:center;font-size:12px">＋</span>
          <span style="font-size:14px;font-weight:800">Log Sip</span>
          <span>💧</span>
        </button>
        <button class="chip" style="flex:1;display:flex;flex-direction:column;gap:2px;padding:10px 6px" onclick="repeatLast()">
          <span style="font-size:15px">↺</span><span style="font-size:10.5px;font-weight:600">${last ? `+${fmt(last.ml)} ${unitSym()}` : 'Repeat'}</span>
        </button>
      </div>
    </div>

    <div style="display:flex;justify-content:space-between;align-items:center;padding:0 4px 8px">
      <span class="body-b">Recent Sips Today <span class="cap">(${today.length} logged)</span></span>
    </div>
    <div class="card" style="padding:4px 16px">
      ${today.length ? today.slice(0, 5).map(e => {
        const b = bevCatalog.find(x => x.id === e.bev);
        return `
        <div class="entry">
          <div class="tile" style="background:${b.tint}1f;color:${b.tint};width:36px;height:36px;font-size:18px">${b.icon}</div>
          <div style="flex:1">
            <div class="body-b" style="font-size:14px">${fmt(e.ml)} ${unitSym()} ${b.name} <span style="background:${b.tint}14;color:${b.tint};font-size:10px;font-weight:800;border-radius:4px;padding:1px 5px">${Math.round(e.factor * 100)}%</span></div>
            <div class="cap" style="margin-top:2px">${fmtTime(e.date)} • ${e.container}</div>
          </div>
          <b style="color:var(--brand);font-size:13px">+${fmt(e.ml)} ${unitSym()}</b>
        </div>`;
      }).join('') : '<div class="cap" style="padding:14px;text-align:center">Nothing logged yet today — tap a vessel above! 💧</div>'}
    </div>`;
}
function nextSipMins() {
  const last = entriesToday().sort((a, b) => b.date - a.date)[0];
  const interval = state.customIntervalMin ?? state.intervalH * 60;
  const elapsed = last ? (Date.now() - last.date.getTime()) / 6e4 : 0;
  return Math.max(0, Math.round(interval - elapsed));
}
function repeatLast() {
  const last = entriesToday().sort((a, b) => b.date - a.date)[0];
  if (last) logDrink(last.bev, last.ml, last.container);
  else toast('Nothing to repeat yet');
}

// ---------- Analytics ----------
let analyticsRange = 'Week';
let customDays = 14;
function rangeData() {
  // Build daily totals for the active range from seeded + live entries.
  const days = analyticsRange === 'Week' ? 7 : analyticsRange === 'Month' ? new Date().getDate() : analyticsRange === 'Year' ? 12 : customDays;
  const monthly = analyticsRange === 'Year';
  const seeded = { 95: 2830, 92: 2720, 74: 2190, 90: 2660 }; // oz→ml presets for Mon–Thu pattern
  const out = [];
  const now = new Date();
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(now); d.setDate(now.getDate() - i);
    const key = todayKey(d);
    const live = state.entries.filter(e => todayKey(e.date) === key).reduce((s, e) => s + e.ml * e.factor, 0);
    if (monthly) {
      // Year mode: one bucket per month.
      out.push(null); // placeholder, computed below
    } else {
      const base = seeded[i % 4 === 0 ? 95 : i % 4] ?? 2400;
      const jitter = ((i * 37) % 300) - 150;
      out.push({ day: d, value: live || Math.max(0, base + jitter) * (analyticsRange === 'Week' ? 1 : 0.85 + (i % 5) * 0.06) });
    }
  }
  if (monthly) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months.map((m, i) => ({
      day: new Date(now.getFullYear(), i, 1),
      value: i <= now.getMonth() ? (i === now.getMonth() ? totalToday() : 2200 + ((i * 173) % 900)) : null,
    }));
  }
  return out;
}
function renderAnalytics() {
  const data = rangeData();
  const valid = data.filter(d => d.value !== null);
  const metCount = valid.filter(d => d.value >= goalML()).length;
  const avg = valid.length ? Math.round(valid.reduce((a, b) => a + b.value, 0) / valid.length) : 0;
  const prevAvg = valid.length ? Math.round(valid.reduce((a, b) => a + b.value, 0) / valid.length * 0.96) : 0;
  const change = prevAvg ? Math.round((avg - prevAvg) / prevAvg * 100) : 4;
  const showHeat = analyticsRange === 'Week';

  $('#screen-analytics').innerHTML = `
    <div class="hdr-row"><span class="h-large">Hydration Insights</span></div>
    <div class="seg">
      ${['Week', 'Month', 'Year', 'Custom'].map(r => `<button class="${analyticsRange === r ? 'on' : ''}" onclick="setRange('${r}')">${r}</button>`).join('')}
    </div>

    <div class="card" style="display:flex;justify-content:space-between;align-items:center">
      <div>
        <div class="eyebrow">${analyticsRange.toUpperCase()} METRIC</div>
        <div class="h-med" style="margin:3px 0">${metCount} / ${valid.length} Days Goal Met</div>
        <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap">
          <span class="cap">Daily Avg:</span>
          <b style="color:var(--brand)">${fmt(avg)} ${unitSym()}</b>
          <span class="cap-b" style="background:rgba(0,199,190,.15);color:#006f69;border-radius:99px;padding:2px 8px">+${change}% vs prev</span>
        </div>
      </div>
      <div style="width:52px;height:52px;border-radius:16px;background:rgba(0,199,190,.2);box-shadow:0 0 16px rgba(57,220,210,.45);display:flex;align-items:center;justify-content:center;font-size:28px">✅</div>
    </div>

    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px">
        <span class="h-sm">📊 ${analyticsRange} Intake Trend</span>
        <span class="cap">Target: ${fmt(goalML())} ${unitSym()}</span>
      </div>
      <div class="goal-line"><span>${fmt(goalML())} ${unitSym()}</span></div>
      <div class="bars" style="overflow-x:auto">
        ${data.map(d => {
          const isToday = d.day.toDateString() === new Date().toDateString();
          const v = d.value;
          const isFuture = v === null;
          const label = analyticsRange === 'Year'
            ? ['J','F','M','A','M','J','J','A','S','O','N','D'][d.day.getMonth()]
            : analyticsRange === 'Month' || (analyticsRange === 'Custom' && customDays > 14)
              ? String(d.day.getDate())
              : ['M','T','W','T','F','S','S'][ (d.day.getDay() + 6) % 7 ];
          const h = isFuture ? 14 : Math.max(5, Math.min(v / (goalML() * 1.15), 1) * 118);
          const w = data.length > 20 ? 8 : data.length > 12 ? 12 : 24;
          return `
          <div class="bar-col" style="min-width:${w + 8}px">
            <span class="bar-val">${isFuture ? '' : Math.round(toUnit(v))}</span>
            <div class="bar ${isFuture ? 'empty' : isToday ? 'today' : v >= goalML() ? 'met' : ''}" style="height:${h}px;width:${w}px"></div>
            <span class="bar-letter" style="${isToday ? 'color:var(--brand);font-weight:800' : ''}">${label}</span>
          </div>`;
        }).join('')}
      </div>
    </div>

    ${showHeat ? `
    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center;padding-bottom:10px;border-bottom:.5px solid var(--hair)">
        <span class="h-sm">🔹 Today's Breakdown</span>
        <b style="color:var(--brand)">${fmt(totalToday())} / ${fmt(goalML())} ${unitSym()}</b>
      </div>
      ${entriesToday().sort((a, b) => a.date - b.date).map(e => {
        const b = bevCatalog.find(x => x.id === e.bev);
        const period = e.date.getHours() < 11 ? ['☀️', 'Morning Boost'] : e.date.getHours() < 14 ? ['🌤️', 'Midday Water'] : e.date.getHours() < 18 ? ['🏃', 'Afternoon Refill'] : ['🍽️', 'Dinner Hydration'];
        return `
        <div class="row">
          <div class="tile" style="background:${b.tint}1f;color:${b.tint}">${period[0]}</div>
          <div style="flex:1">
            <div style="font-size:13px;font-weight:700">${period[1]}</div>
            <div class="cap">${fmtTime(e.date)} • ${e.container}</div>
          </div>
          <b style="font-size:14px">+${fmt(e.ml)} ${unitSym()}</b>
        </div>`;
      }).join('') || '<div class="cap" style="padding:12px">No entries yet.</div>'}
    </div>

    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center">
        <span class="h-sm">🗓️ ${new Date().toLocaleString([], { month: 'long' })} Consistency</span>
        <b class="cap-b" style="color:var(--brand)">›</b>
      </div>
      <div class="cap" style="margin:4px 0 10px">Heat-map indicator across daily hydration goals</div>
      <div class="heatmap">${renderHeatmap()}</div>
    </div>` : ''}
  `;
}
function setRange(r) {
  if (r === 'Custom') { openCustomPicker(); return; }
  analyticsRange = r; haptic(); renderAnalytics();
}
function openCustomPicker() {
  $('#custom-sheet').style.display = 'flex';
  requestAnimationFrame(() => $('#custom-sheet').classList.add('open'));
  renderCustomPicker();
}
function renderCustomPicker() {
  $('#custom-chips').innerHTML = [7, 14, 30, 90].map(d =>
    `<button class="chip ${customDays === d ? 'on' : ''}" onclick="customDays=${d};renderCustomPicker()">${d} days</button>`).join('');
}
function applyCustom() {
  analyticsRange = 'Custom';
  $('#custom-sheet').classList.remove('open');
  setTimeout(() => { $('#custom-sheet').style.display = 'none'; }, 250);
  haptic(); renderAnalytics();
}
function renderHeatmap() {
  const today = new Date();
  const y = today.getFullYear(), m = today.getMonth();
  const daysInMonth = new Date(y, m + 1, 0).getDate();
  const firstDow = (new Date(y, m, 1).getDay() + 6) % 7; // Monday-first
  const met = [1, 1, 1, 0.5, 1, 1, 1, 1, 0, 1, 1, 0.5, 1, 1]; // seeded pattern
  let html = ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map(l => `<span class="cap" style="text-align:center">${l}</span>`).join('');
  for (let i = 0; i < firstDow; i++) html += '<span></span>';
  for (let d = 1; d <= daysInMonth; d++) {
    const isFuture = d > today.getDate();
    const isToday = d === today.getDate();
    const r = isFuture ? null : (isToday ? progress() : met[(d - 1) % met.length]);
    const cls = r === null ? '' : r >= 1 ? 'full' : r >= 0.8 ? 'mid' : r > 0 ? 'low' : '';
    html += `<div class="hm-day ${cls} ${isToday ? 'today' : ''}" ${isFuture ? 'style="opacity:.45"' : ''}>${d}</div>`;
  }
  return html;
}

// ---------- History ----------
function renderHistory() {
  const byDay = {};
  state.entries.forEach(e => {
    const k = todayKey(e.date);
    (byDay[k] = byDay[k] || []).push(e);
  });
  const days = Object.keys(byDay).sort().reverse();
  $('#screen-history').innerHTML = `
    <div class="hdr-row"><span class="h-large">History</span></div>
    ${days.length ? days.map(k => {
      const tot = byDay[k].reduce((s, e) => s + e.ml * e.factor, 0);
      return `
      <div style="display:flex;justify-content:space-between;padding:10px 4px 4px">
        <b style="font-size:13px">${new Date(k).toLocaleDateString([], { month: 'short', day: 'numeric' })}</b>
        <b style="font-size:13px;color:var(--brand)">${fmt(tot)} ${unitSym()}</b>
      </div>
      <div class="card" style="padding:4px 16px">
        ${byDay[k].sort((a, b) => b.date - a.date).map(e => {
          const b = bevCatalog.find(x => x.id === e.bev);
          return `
          <div class="entry">
            <div class="tile" style="background:${b.tint}1f;color:${b.tint};width:36px;height:36px;font-size:18px">${b.icon}</div>
            <div style="flex:1">
              <div class="body-b" style="font-size:14px">${fmt(e.ml)} ${unitSym()} ${b.name}</div>
              <div class="cap" style="margin-top:2px">${fmtTime(e.date)} • ${e.container}</div>
            </div>
            <button style="border:none;background:none;color:var(--label3);font-size:16px;cursor:pointer" onclick="delEntry('${e.id}')">🗑</button>
          </div>`;
        }).join('')}
      </div>`;
    }).join('') : '<div class="card" style="text-align:center;padding:30px"><div style="font-size:40px">💧</div><div class="body-b" style="margin-top:8px">No history yet</div></div>'}`;
}
function delEntry(id) {
  state.entries = state.entries.filter(e => e.id !== id);
  haptic(); toast('Entry deleted'); renderAll();
}

// ---------- Settings ----------
function renderSettings() {
  const sound = SOUND_LIBRARY.find(s => s.id === state.sound) || SOUND_LIBRARY[0];
  const wrap = state.activeStart >= state.activeEnd;
  const hourLabel = h => { const d = h % 12 === 0 ? 12 : h % 12; return `${d} ${h < 12 ? 'AM' : 'PM'}`; };
  const intervalText = state.customIntervalMin
    ? (state.customIntervalMin % 60 === 0 ? `Every ${state.customIntervalMin / 60} h` : `Every ${state.customIntervalMin} min`)
    : `Every ${state.intervalH} Hours`;

  $('#screen-settings').innerHTML = `
    <div class="hdr-row"><span class="h-large">Reminders &amp; Preferences</span></div>
    <div class="card" style="background:linear-gradient(90deg,rgba(0,122,255,.14),rgba(0,199,190,.12));display:flex;align-items:center;gap:12px">
      <div class="tile" style="background:var(--azure);color:#fff;width:36px;height:36px;border-radius:50%">🔔</div>
      <div style="flex:1">
        <div class="body-b">Next Drink Alert</div>
        <div class="cap">${intervalText} during active hours</div>
      </div>
      <span class="cap-b" style="background:#fff;border-radius:99px;padding:4px 10px;color:var(--brand)">${state.reminders && !state.bedtime ? 'On Schedule' : 'Paused'}</span>
    </div>

    <div class="cap-b" style="letter-spacing:.8px;color:var(--label2);padding:0 4px 6px">SMART HYDRATION ALERTS</div>
    <div class="card" style="padding:4px 16px">
      <div class="row"><div class="tile" style="background:rgba(0,122,255,.14)">🔔</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Drink Reminders</div><div class="cap">Scheduled nudges during daytime</div></div>
        <label class="toggle"><input type="checkbox" ${state.reminders ? 'checked' : ''} onchange="state.reminders=this.checked;renderSettings()"><i></i></label></div>
      <div class="row" onclick="openIntervalPicker()" style="cursor:pointer"><div class="tile" style="background:rgba(0,199,190,.14)">⏱️</div>
        <span class="body-b" style="font-size:16px;flex:1">Reminder Interval</span>
        <b style="color:var(--brand);font-size:13px">${intervalText}</b><span class="cap">›</span></div>
      <div class="row" onclick="openHoursPicker()" style="cursor:pointer"><div class="tile" style="background:rgba(88,86,214,.14)">🕐</div>
        <span class="body-b" style="font-size:16px;flex:1">Active Hours</span>
        <span style="font-size:13px;color:var(--label2)">${hourLabel(state.activeStart)} – ${hourLabel(state.activeEnd)}</span><span class="cap">›</span></div>
      <div class="row"><div class="tile" style="background:rgba(0,0,0,.08)">🌙</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Bedtime Mode</div><div class="cap">Mutes all hydration alerts while asleep</div></div>
        <label class="toggle"><input type="checkbox" ${state.bedtime ? 'checked' : ''} onchange="state.bedtime=this.checked;renderSettings()"><i></i></label></div>
      <div class="row"><div class="tile" style="background:rgba(255,149,0,.14)">☀️</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Dynamic Weather</div><div class="cap">Auto-adds +12 oz on high heat days</div></div>
        <label class="toggle"><input type="checkbox" ${state.weather ? 'checked' : ''} onchange="state.weather=this.checked;renderSettings()"><i></i></label></div>
    </div>

    <div class="cap-b" style="letter-spacing:.8px;color:var(--label2);padding:8px 4px 6px">SOUNDS &amp; HAPTICS</div>
    <div class="card" style="padding:4px 16px">
      <div class="row" onclick="openSoundPicker()" style="cursor:pointer"><div class="tile" style="background:rgba(0,199,190,.14)">🔊</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Notification Sound</div><div class="cap">From your iPhone's sound library</div></div>
        <b style="color:var(--brand);font-size:13px">${sound.name}</b><span class="cap">›</span></div>
      <div class="row"><div class="tile" style="background:rgba(88,86,214,.14)">📳</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Haptic Feedback</div><div class="cap">Subtle water droplet resonance</div></div>
        <label class="toggle"><input type="checkbox" ${state.haptics ? 'checked' : ''} onchange="state.haptics=this.checked;renderSettings()"><i></i></label></div>
    </div>

    <div class="cap-b" style="letter-spacing:.8px;color:var(--label2);padding:8px 4px 6px">TARGETS &amp; INTEGRATION</div>
    <div class="card" style="padding:4px 16px">
      <div class="row" onclick="openGoalEditor()" style="cursor:pointer"><div class="tile" style="background:rgba(0,122,255,.14)">🚩</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Daily Goal</div><div class="cap">Raise, lower, or use profile value</div></div>
        <b style="color:var(--brand)">${fmt(baseGoal())} ${unitSym()}</b><span class="cap">›</span></div>
      <div class="row" onclick="cycleUnit()" style="cursor:pointer"><div class="tile" style="background:rgba(0,122,255,.10)">🔄</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Units</div><div class="cap">Ounces or milliliters everywhere</div></div>
        <b style="color:var(--brand)">${unitSym().toUpperCase()}</b><span class="cap">›</span></div>
      <div class="row" onclick="openPresetsEditor()" style="cursor:pointer"><div class="tile" style="background:rgba(88,86,214,.14)">🥛</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Container Presets</div><div class="cap">${containers.length} vessels on the Today shelf</div></div>
        <span class="cap">›</span></div>
      <div class="row"><div class="tile" style="background:rgba(255,59,48,.12)">❤️</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Apple Health Sync</div><div class="cap">Available in the native iOS app</div></div>
        <span class="cap-b" style="color:#006f69">● Native only</span><span class="cap">›</span></div>
      <div class="row" onclick="resetHistory()" style="cursor:pointer"><div class="tile" style="background:rgba(88,86,214,.14)">♻️</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Reset Preview Data</div><div class="cap">Clear all logged entries in this preview</div></div>
        <span class="cap">›</span></div>
    </div>
    <div style="text-align:center;padding:6px 0 16px"><div class="cap">HydroFlow Web Preview v1.1</div><div class="cap">Native SwiftUI app compiles via Xcode / CI</div></div>`;
}

// ---------- Interval picker (presets + custom) ----------
function openIntervalPicker() {
  $('#interval-sheet').style.display = 'flex';
  requestAnimationFrame(() => $('#interval-sheet').classList.add('open'));
  renderIntervalPicker();
}
function closeIntervalPicker() {
  $('#interval-sheet').classList.remove('open');
  setTimeout(() => { $('#interval-sheet').style.display = 'none'; }, 250);
}
function renderIntervalPicker() {
  const presetsList = [
    [0.5, 'Every 30 Minutes', 'Very frequent — builds the habit'],
    [0.75, 'Every 45 Minutes', 'Frequent — ~10 sips a day'],
    [1, 'Every Hour', 'Steady rhythm — the classic'],
    [1.5, 'Every 1.5 Hours', 'Balanced — recommended default'],
    [2, 'Every 2 Hours', 'Relaxed — ~7 reminders/day'],
    [2.5, 'Every 2.5 Hours', 'Light — for big-volume drinkers'],
    [3, 'Every 3 Hours', 'Minimal — just the essentials'],
  ];
  $('#interval-list').innerHTML = presetsList.map(([h, label, hint]) => `
    <div class="row" onclick="pickInterval(${h})" style="cursor:pointer">
      <div style="flex:1"><div class="body-b" style="font-size:15px">${label}</div><div class="cap">${hint}</div></div>
      ${!state.customIntervalMin && state.intervalH === h ? '<span style="color:var(--azure);font-weight:800">✓</span>' : ''}
    </div>`).join('');
  $('#custom-int-toggle').checked = !!state.customIntervalMin;
  if (state.customIntervalMin) $('#custom-int-slider').value = state.customIntervalMin;
  const wrap = document.getElementById('custom-int-wrap');
  if (wrap) wrap.style.display = state.customIntervalMin ? 'block' : 'none';
  $('#custom-int-label').textContent = state.customIntervalMin
    ? `${state.customIntervalMin % 60 === 0 ? state.customIntervalMin / 60 + ' h' : state.customIntervalMin + ' min'}`
    : 'Off';
}
function pickInterval(h) { state.intervalH = h; state.customIntervalMin = null; haptic(); renderIntervalPicker(); renderSettings(); }
function toggleCustomInterval(on) {
  state.customIntervalMin = on ? 75 : null;
  haptic(); renderIntervalPicker(); renderSettings();
  const wrap = document.getElementById('custom-int-wrap');
  if (wrap) wrap.style.display = on ? 'block' : 'none';
}
function customIntervalSlide(val) {
  state.customIntervalMin = Number(val);
  $('#custom-int-label').textContent = `${val % 60 === 0 ? val / 60 + ' h' : val + ' min'}`;
  haptic(); renderSettings();
}

// ---------- Active hours (24h) ----------
function openHoursPicker() {
  $('#hours-sheet').style.display = 'flex';
  requestAnimationFrame(() => $('#hours-sheet').classList.add('open'));
  renderHoursPicker();
}
function closeHoursPicker() {
  $('#hours-sheet').classList.remove('open');
  setTimeout(() => { $('#hours-sheet').style.display = 'none'; }, 250);
}
function renderHoursPicker() {
  const hourLabel = h => { const d = h % 12 === 0 ? 12 : h % 12; return `${d} ${h < 12 ? 'AM' : 'PM'}`; };
  const opts = Array.from({ length: 24 }, (_, h) => `<option value="${h}">${hourLabel(h)}</option>`).join('');
  $('#hours-start').innerHTML = opts; $('#hours-end').innerHTML = opts;
  $('#hours-start').value = state.activeStart; $('#hours-end').value = state.activeEnd;
  $('#hours-wrap-note').style.display = state.activeStart >= state.activeEnd ? 'flex' : 'none';
}
function setHours() {
  state.activeStart = Number($('#hours-start').value);
  state.activeEnd = Number($('#hours-end').value);
  haptic(); toast('Active hours saved');
  closeHoursPicker(); renderSettings();
}
function presetHours(s, e) {
  state.activeStart = s; state.activeEnd = e;
  haptic(); renderHoursPicker(); renderSettings();
}

// ---------- Sound picker ----------
function openSoundPicker() {
  $('#sound-sheet').style.display = 'flex';
  requestAnimationFrame(() => $('#sound-sheet').classList.add('open'));
  renderSoundPicker();
}
function closeSoundPicker() {
  $('#sound-sheet').classList.remove('open');
  setTimeout(() => { $('#sound-sheet').style.display = 'none'; }, 250);
}
function renderSoundPicker() {
  $('#sound-list').innerHTML = SOUND_LIBRARY.map(s => `
    <div class="row" onclick="pickSound('${s.id}')" style="cursor:pointer">
      <div class="tile" style="background:rgba(0,122,255,.10);width:30px;height:30px">🔊</div>
      <span class="body-b" style="flex:1;font-size:15px">${s.name}</span>
      <span class="cap">▶</span>
      ${state.sound === s.id ? '<span style="color:var(--azure);font-weight:800">✓</span>' : ''}
    </div>`).join('');
  $('#sound-vol').value = state.soundVolume;
}
function pickSound(id) {
  state.sound = id; haptic();
  previewSound(id);
  renderSoundPicker(); renderSettings();
}
function soundVolumeSlide(val) { state.soundVolume = Number(val); }

// ---------- Container presets editor ----------
let editContainerId = null;
function openPresetsEditor() {
  renderPresetsEditor();
  $('#presets-sheet').style.display = 'flex';
  requestAnimationFrame(() => $('#presets-sheet').classList.add('open'));
}
function closePresetsEditor() {
  $('#presets-sheet').classList.remove('open');
  setTimeout(() => { $('#presets-sheet').style.display = 'none'; }, 250);
}
function renderPresetsEditor() {
  $('#presets-list').innerHTML = containers.map(c => `
    <div class="row" onclick="editContainer('${c.id}')" style="cursor:pointer">
      <div class="tile" style="background:rgba(0,122,255,.10);width:34px;height:34px">${c.icon}</div>
      <div style="flex:1"><div class="body-b" style="font-size:15px">${c.name}</div><div class="cap">${fmt(c.ml)} ${unitSym()}</div></div>
      <span class="cap">›</span>
    </div>`).join('');
}
function editContainer(id) {
  editContainerId = id;
  const c = containers.find(x => x.id === id);
  $('#preset-name').value = c.name;
  $('#preset-ml').value = c.ml;
  $('#presets-sheet').classList.remove('open');
  setTimeout(() => {
    $('#preset-edit-sheet').style.display = 'flex';
    requestAnimationFrame(() => $('#preset-edit-sheet').classList.add('open'));
  }, 200);
}
function closePresetEdit() {
  $('#preset-edit-sheet').classList.remove('open');
  setTimeout(() => { $('#preset-edit-sheet').style.display = 'none'; }, 250);
  openPresetsEditor();
}
function presetNudge(dir) {
  const step = state.unit === 'oz' ? ML_PER_OZ : 50;
  const el = $('#preset-ml');
  el.value = Math.min(Math.max(Number(el.value) + dir * step, 30), 2000);
}
function savePreset() {
  const c = containers.find(x => x.id === editContainerId);
  if (c) {
    c.name = $('#preset-name').value.trim() || c.name;
    c.ml = Number($('#preset-ml').value) || c.ml;
  }
  haptic(); toast('Container saved');
  closePresetEdit(); renderAll();
}
function addContainer() {
  containers.push({ id: uid(), name: 'New Container', bev: 'water', ml: 250, icon: '🫗' });
  haptic(); renderPresetsEditor(); renderAll();
}
function removeContainer() {
  if (containers.length <= 1) { toast('Keep at least one container'); return; }
  containers = containers.filter(c => c.id !== editContainerId);
  haptic(); toast('Container removed');
  closePresetEdit(); renderAll();
}

function cycleUnit() {
  state.unit = state.unit === 'oz' ? 'ml' : 'oz';
  haptic(); toast(`Units: ${unitSym()}`); renderAll();
}
function resetHistory() {
  state.entries = [];
  seedDemoData();
  toast('Preview data reset'); renderAll();
}

// ---------- Navigation ----------
let currentTab = 'today';
function renderAll() {
  renderToday(); renderAnalytics(); renderHistory(); renderSettings();
}
function showTab(tab) {
  if (tab === 'add') { openSheet(); return; }
  currentTab = tab;
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  $('#screen-' + tab).classList.add('active');
  document.querySelectorAll('.navbar button').forEach(b => b.classList.toggle('on', b.dataset.tab === tab));
}
document.querySelectorAll('.navbar button').forEach(b =>
  b.addEventListener('click', () => showTab(b.dataset.tab)));

// ---------- Init ----------
seedDemoData();
renderAll();
showTab('today');
