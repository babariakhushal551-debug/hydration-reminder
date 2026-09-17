/* HydroFlow web preview — mirrors the SwiftUI app's state and screens. */

// ---------- State (mirrors HydrationStore) ----------
const ML_PER_OZ = 29.5735;
const state = {
  unit: 'oz',                       // 'oz' | 'ml'
  goalML: 2660,
  entries: [],                      // {id, date:Date, bev, ml, factor, container}
  streakBase: 6,                    // seeded streak from "previous days"
  reminders: true, intervalH: 1.5, bedtime: true, weather: true, haptics: true,
};
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
const vessels = [
  { name:'Glass',  bev:'water',   ml:240, icon:'🥛' },
  { name:'Mug',    bev:'tea',     ml:355, icon:'🍵' },
  { name:'Bottle', bev:'water',   ml:473, icon:'🍶' },
  { name:'Flask',  bev:'electro', ml:710, icon:'⚡' },
];

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

function seedDemoData() {
  const now = Date.now();
  state.entries.push(
    { id: uid(), date: new Date(now - 6.2 * 36e5), bev: 'water',   ml: 473, factor: 1.00, container: 'Glass Bottle' },
    { id: uid(), date: new Date(now - 2.4 * 36e5), bev: 'electro', ml: 710, factor: 1.10, container: 'Workout Flask' },
  );
}
seedDemoData();

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
  if (!wasGoalMet && totalToday() >= state.goalML) {
    wasGoalMet = true;
    fireConfetti();
  }
  if (totalToday() < state.goalML) wasGoalMet = false;
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
  sheetSel = id; lastBeverage = id;
  sheetML = bevCatalog.find(b => b.id === id).preset;
  renderSheet();
}

// ---------- Pour-bottle drag interaction ----------
// Maps vertical drags on the log-sheet bottle to the selected volume.
// Water body spans 26%..98% of the bottle height (below the shoulder).
function setupPourDrag() {
  const bottle = document.getElementById('pour-bottle');
  if (!bottle) return;
  const TOP_FRAC = 0.26, BOTTOM_FRAC = 0.98, MAX_ML = 1000;
  let dragging = false;

  const setFromY = (clientY) => {
    const rect = bottle.getBoundingClientRect();
    const raw = 1 - (clientY - rect.top) / rect.height;         // top = full
    const bodyFrac = Math.min(Math.max((raw - TOP_FRAC) / (BOTTOM_FRAC - TOP_FRAC), 0), 1);
    const step = state.unit === 'oz' ? ML_PER_OZ : 50;
    const snapped = Math.round((bodyFrac * MAX_ML) / step) * step;
    const clamped = Math.min(Math.max(snapped, 30), 2000);
    if (Math.abs(clamped - sheetML) >= 1) {
      sheetML = clamped; lastBeverage = sheetSel;
      haptic();
      // Update just the moving parts for 60fps-feel; full re-render on release.
      document.getElementById('pour-water').style.height = (26 + Math.min(sheetML / MAX_ML, 1) * 72) + '%';
      const num = bottle.querySelector('.num');
      num.innerHTML = `${fmt(sheetML)}<small> ${unitSym()}</small><div class="cap-b" style="color:var(--brand)">${Math.round(sheetML)} ml</div>`;
    }
  };

  bottle.addEventListener('pointerdown', (e) => {
    dragging = true;
    bottle.setPointerCapture(e.pointerId);
    setFromY(e.clientY);
  });
  bottle.addEventListener('pointermove', (e) => { if (dragging) setFromY(e.clientY); });
  bottle.addEventListener('pointerup', () => { if (dragging) { dragging = false; renderSheet(); } });
  bottle.addEventListener('pointercancel', () => { dragging = false; });
}
// Re-bind after every sheet render (element is recreated).
const _origRenderSheet = renderSheet;
renderSheet = function () { _origRenderSheet(); setupPourDrag(); };
function sheetLog() {
  logDrink(sheetSel, sheetML, 'Custom log');
  setTimeout(closeSheet, 550);
}

// ---------- Screens ----------
function renderToday() {
  const tot = totalToday(), prog = progress(), pct = Math.round(prog * 100);
  const remaining = Math.max(0, state.goalML - tot);
  const last = entriesToday().sort((a, b) => b.date - a.date)[0];
  const glasses = (remaining / 240).toFixed(1);
  const today = entriesToday().sort((a, b) => b.date - a.date);

  $('#screen-today').innerHTML = `
    <div class="card" style="background:linear-gradient(90deg,rgba(0,122,255,.10),rgba(0,199,190,.10),#fff);display:flex;align-items:center;gap:10px;margin-top:10px">
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
            <div class="cap" style="margin-top:3px">of ${fmt(state.goalML)} ${unitSym()} goal</div>
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
        <div class="body-b" style="margin-top:8px">${last ? bevCatalog.find(b => b.id === last.bev).name : 'No drinks yet'}</div>
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
        ${vessels.map((v, i) => `
          <button class="vessel" onclick="logDrink('${v.bev}', ${v.ml}, '${v.name}')">
            <span class="vi">${v.icon}</span><b>+${fmt(v.ml)} ${unitSym()}</b><span>${v.name}</span>
          </button>`).join('')}
      </div>
      <div style="display:flex;gap:10px;align-items:center;margin-top:14px">
        <button class="chip" onclick="openSheet()">⚙ Custom</button>
        <button class="btn-grad" style="width:auto;padding:0 22px;height:44px;font-size:14px" onclick="logDrink('water',240,'Glass')">＋ Log Sip 💧</button>
        <button class="chip" onclick="repeatLast()">↺ ${last ? `+${fmt(last.ml)} ${unitSym()}` : 'Repeat'}</button>
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
  const elapsed = last ? (Date.now() - last.date.getTime()) / 6e4 : 0;
  return Math.max(0, Math.round(state.intervalH * 60 - elapsed));
}
function repeatLast() {
  const last = entriesToday().sort((a, b) => b.date - a.date)[0];
  if (last) logDrink(last.bev, last.ml, last.container);
}

// ---------- Analytics ----------
let analyticsRange = 'Week';
function renderAnalytics() {
  const weekLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  // Seed the week's history (only for display).
  const weekData = [95, 92, 74, 90, Math.round(toUnit(totalToday()) || 88), null, null];
  const metCount = weekData.filter(v => v !== null && v >= state.goalML / ML_PER_OZ * 1 && v >= fmt(state.goalML)).length;
  const avg = Math.round(weekData.filter(v => v).reduce((a, b) => a + b, 0) / weekData.filter(v => v).length);

  $('#screen-analytics').innerHTML = `
    <div class="hdr-row"><span class="h-large">Hydration Insights</span></div>
    <div class="seg">
      ${['Week', 'Month', 'Year'].map(r => `<button class="${analyticsRange === r ? 'on' : ''}" onclick="analyticsRange='${r}';renderAnalytics()">${r}</button>`).join('')}
    </div>

    <div class="card" style="display:flex;justify-content:space-between;align-items:center">
      <div>
        <div class="eyebrow">WEEKLY METRIC</div>
        <div class="h-med" style="margin:3px 0">${metCount} / 7 Days Goal Met</div>
        <div style="display:flex;gap:8px;align-items:center">
          <span class="cap">Daily Avg:</span>
          <b style="color:var(--brand)">${avg} ${unitSym()}</b>
          <span class="cap-b" style="background:rgba(0,199,190,.15);color:#006f69;border-radius:99px;padding:2px 8px">+4% vs lw</span>
        </div>
      </div>
      <div style="width:52px;height:52px;border-radius:16px;background:rgba(0,199,190,.2);box-shadow:0 0 16px rgba(57,220,210,.45);display:flex;align-items:center;justify-content:center;font-size:28px">✅</div>
    </div>

    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px">
        <span class="h-sm">📊 Weekly Intake Trend</span>
        <span class="cap">Target: ${fmt(state.goalML)} ${unitSym()}</span>
      </div>
      <div class="goal-line"><span>${fmt(state.goalML)} ${unitSym()}</span></div>
      <div class="bars">
        ${weekData.map((v, i) => {
          const isToday = i === 4;
          const isFuture = v === null;
          const h = isFuture ? 18 : Math.max(6, Math.min(v / (fmt(state.goalML) * 1.1), 1) * 118);
          return `
          <div class="bar-col">
            <span class="bar-val">${isFuture ? '--' : v}</span>
            <div class="bar ${isFuture ? 'empty' : isToday ? 'today' : v >= fmt(state.goalML) ? 'met' : ''}" style="height:${h}px"></div>
            <span class="bar-letter" style="${isToday ? 'color:var(--brand);font-weight:800' : ''}">${weekLetters[i]}</span>
          </div>`;
        }).join('')}
      </div>
    </div>

    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center;padding-bottom:10px;border-bottom:.5px solid var(--hair)">
        <span class="h-sm">🔹 Today's Breakdown</span>
        <b style="color:var(--brand)">${fmt(totalToday())} / ${fmt(state.goalML)} ${unitSym()}</b>
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
        <b class="cap-b" style="color:var(--brand)">18 / ${new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0).getDate()} days ›</b>
      </div>
      <div class="cap" style="margin:4px 0 10px">Heat-map indicator across daily hydration goals</div>
      <div class="heatmap">${renderHeatmap()}</div>
    </div>`;
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
  $('#screen-settings').innerHTML = `
    <div class="hdr-row"><span class="h-large">Reminders &amp; Preferences</span></div>
    <div class="card" style="background:linear-gradient(90deg,rgba(0,122,255,.14),rgba(0,199,190,.12));display:flex;align-items:center;gap:12px">
      <div class="tile" style="background:var(--azure);color:#fff;width:36px;height:36px;border-radius:50%">🔔</div>
      <div style="flex:1">
        <div class="body-b">Next Drink Alert</div>
        <div class="cap">Today • every ${state.intervalH}h during active hours</div>
      </div>
      <span class="cap-b" style="background:#fff;border-radius:99px;padding:4px 10px;color:var(--brand)">${state.reminders && !state.bedtime ? 'On Schedule' : 'Paused'}</span>
    </div>

    <div class="cap-b" style="letter-spacing:.8px;color:var(--label2);padding:0 4px 6px">SMART HYDRATION ALERTS</div>
    <div class="card" style="padding:4px 16px">
      <div class="row"><div class="tile" style="background:rgba(0,122,255,.14)">🔔</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Drink Reminders</div><div class="cap">Scheduled nudges during daytime</div></div>
        <label class="toggle"><input type="checkbox" ${state.reminders ? 'checked' : ''} onchange="state.reminders=this.checked;renderSettings()"><i></i></label></div>
      <div class="row" onclick="cycleInterval()" style="cursor:pointer"><div class="tile" style="background:rgba(0,199,190,.14)">⏱️</div>
        <span class="body-b" style="font-size:16px;flex:1">Reminder Interval</span>
        <b style="color:var(--brand);font-size:13px">Every ${state.intervalH} Hours</b><span class="cap">›</span></div>
      <div class="row"><div class="tile" style="background:rgba(88,86,214,.14)">🕐</div>
        <span class="body-b" style="font-size:16px;flex:1">Active Hours</span>
        <span style="font-size:13px;color:var(--label2)">8:00 AM – 10:00 PM</span><span class="cap">›</span></div>
      <div class="row"><div class="tile" style="background:rgba(0,0,0,.08)">🌙</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Bedtime Mode</div><div class="cap">Mutes all hydration alerts while asleep</div></div>
        <label class="toggle"><input type="checkbox" ${state.bedtime ? 'checked' : ''} onchange="state.bedtime=this.checked;renderSettings()"><i></i></label></div>
      <div class="row"><div class="tile" style="background:rgba(255,149,0,.14)">☀️</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Dynamic Weather</div><div class="cap">Auto-adds +12 oz on high heat days</div></div>
        <label class="toggle"><input type="checkbox" ${state.weather ? 'checked' : ''} onchange="state.weather=this.checked;renderSettings()"><i></i></label></div>
    </div>

    <div class="cap-b" style="letter-spacing:.8px;color:var(--label2);padding:8px 4px 6px">SOUNDS &amp; HAPTICS</div>
    <div class="card" style="padding:4px 16px">
      <div class="row"><div class="tile" style="background:rgba(0,199,190,.14)">🔊</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Notification Sound</div><div class="cap">Gentle acoustic water droplet chime</div></div>
        <b style="color:var(--brand);font-size:13px">Gentle Ripple</b><span class="cap">›</span></div>
      <div class="row"><div class="tile" style="background:rgba(88,86,214,.14)">📳</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Haptic Feedback</div><div class="cap">Subtle water droplet resonance</div></div>
        <label class="toggle"><input type="checkbox" ${state.haptics ? 'checked' : ''} onchange="state.haptics=this.checked;renderSettings()"><i></i></label></div>
    </div>

    <div class="cap-b" style="letter-spacing:.8px;color:var(--label2);padding:8px 4px 6px">TARGETS &amp; INTEGRATION</div>
    <div class="card" style="padding:4px 16px">
      <div class="row" onclick="cycleUnit()" style="cursor:pointer"><div class="tile" style="background:rgba(0,122,255,.14)">🚩</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Daily Goal</div><div class="cap">Tap to switch oz / ml units</div></div>
        <b style="color:var(--brand)">${fmt(state.goalML)} ${unitSym()}</b><span class="cap">›</span></div>
      <div class="row"><div class="tile" style="background:rgba(255,59,48,.12)">❤️</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Apple Health Sync</div><div class="cap">Available in the native iOS app</div></div>
        <span class="cap-b" style="color:#006f69">● Native only</span><span class="cap">›</span></div>
      <div class="row" onclick="resetHistory()" style="cursor:pointer"><div class="tile" style="background:rgba(88,86,214,.14)">♻️</div>
        <div style="flex:1"><div class="body-b" style="font-size:16px">Reset Today's Data</div><div class="cap">Clear all logged entries in this preview</div></div>
        <span class="cap">›</span></div>
    </div>
    <div style="text-align:center;padding:6px 0 16px"><div class="cap">HydroFlow Web Preview v1.0</div><div class="cap">Native SwiftUI app compiles via Xcode / CI</div></div>`;
}
function cycleInterval() {
  const opts = [1, 1.5, 2, 3];
  state.intervalH = opts[(opts.indexOf(state.intervalH) + 1) % opts.length];
  haptic(); renderSettings();
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
  if (!$('#phone').classList.contains('sheet-open')) { /* keep sheet DOM fresh separately */ }
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
renderAll();
showTab('today');
