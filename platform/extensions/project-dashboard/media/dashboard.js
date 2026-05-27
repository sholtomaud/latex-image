// Fluent Professional native web components — styled to match DESIGN.md.
// No framework dependencies. All tokens are CSS custom properties set in the
// host HTML; components read them via getComputedStyle / var().

// ── SVG helpers ───────────────────────────────────────────────────────────────

function svgEl(tag, attrs = {}, children = []) {
  const el = document.createElementNS("http://www.w3.org/2000/svg", tag);
  for (const [k, v] of Object.entries(attrs)) el.setAttribute(k, String(v));
  for (const c of children) {
    if (c == null) continue;
    el.appendChild(typeof c === "string" ? document.createTextNode(c) : c);
  }
  return el;
}

// ── Shared shadow host helper ─────────────────────────────────────────────────

function getShadow(host) {
  return host.shadowRoot ?? host.attachShadow({ mode: "open" });
}

// ── Base token stylesheet (injected into every shadow root) ───────────────────

const BASE_TOKENS = `
  :host {
    --fp-bg:                   #faf9f8;
    --fp-surface:              #ffffff;
    --fp-surface-low:          #f4f3f2;
    --fp-surface-container:    #efeeed;
    --fp-on-surface:           #1a1c1c;
    --fp-on-surface-body:      #323130;
    --fp-on-surface-variant:   #424752;
    --fp-outline:              #727783;
    --fp-outline-variant:      #c2c6d4;
    --fp-card-border:          #edebe9;
    --fp-hover-bg:             #f3f2f1;
    --fp-primary:              #00488d;
    --fp-primary-container:    #005fb8;
    --fp-on-primary:           #ffffff;
    --fp-inverse-primary:      #a8c8ff;
    --fp-secondary:            #605e5c;
    --fp-error:                #ba1a1a;
    --fp-ok:                   #107c10;
    --fp-font:                 'Inter', 'Segoe UI', system-ui, sans-serif;
    --fp-shadow-soft:          0px 4px 12px rgba(0,0,0,0.08);
    --fp-radius:               4px;
    --fp-radius-lg:            8px;
    font-family: var(--fp-font);
    -webkit-font-smoothing: antialiased;
  }
`;

// ── <fp-metric-card> ──────────────────────────────────────────────────────────
// Displays a single KPI: large numeric value + label.
// Usage: <fp-metric-card label="Total words" value="12,340"></fp-metric-card>

class FpMetricCard extends HTMLElement {
  static get observedAttributes() { return ["label", "value", "delta"]; }
  attributeChangedCallback() { if (this.isConnected) this._render(); }
  connectedCallback()        { this._render(); }

  _render() {
    const label = this.getAttribute("label") ?? "";
    const value = this.getAttribute("value") ?? "—";
    const delta = this.getAttribute("delta");          // e.g. "+3%" or "-2%"
    const deltaColor = delta?.startsWith("-") ? "var(--fp-error)" : "var(--fp-ok)";

    getShadow(this).innerHTML = `
      <style>
        ${BASE_TOKENS}
        :host {
          display: block;
          background: var(--fp-surface);
          border: 1px solid var(--fp-card-border);
          border-radius: var(--fp-radius-lg);
          padding: 20px 24px 18px;
          min-width: 140px;
        }
        .value {
          font-size: 32px;
          font-weight: 600;
          line-height: 40px;
          letter-spacing: -0.01em;
          color: var(--fp-primary);
          margin-bottom: 2px;
        }
        .delta {
          font-size: 11px;
          font-weight: 600;
          color: ${deltaColor};
          margin-bottom: 4px;
        }
        .label {
          font-size: 12px;
          font-weight: 600;
          line-height: 16px;
          color: var(--fp-on-surface-variant);
          text-transform: uppercase;
          letter-spacing: 0.06em;
        }
      </style>
      <div class="value">${value}</div>
      ${delta ? `<div class="delta">${delta}</div>` : ""}
      <div class="label">${label}</div>
    `;
  }
}
customElements.define("fp-metric-card", FpMetricCard);

// ── <fp-data-table> ───────────────────────────────────────────────────────────
// High-density data grid. Set via JS: el.data = { columns, rows }.
// columns: [{ key, label, numeric? }]
// rows:    [{ [key]: string }]

class FpDataTable extends HTMLElement {
  set data({ columns, rows }) {
    this._columns = columns;
    this._rows    = rows;
    this._render();
  }
  connectedCallback() { if (this._columns) this._render(); }

  _render() {
    const cols = this._columns ?? [];
    const rows = this._rows    ?? [];

    getShadow(this).innerHTML = `
      <style>
        ${BASE_TOKENS}
        :host { display: block; overflow-x: auto; }
        table {
          width: 100%;
          border-collapse: collapse;
          font-size: 13px;
          line-height: 20px;
          color: var(--fp-on-surface-body);
        }
        thead { position: sticky; top: 0; z-index: 1; }
        th {
          text-align: left;
          padding: 8px 12px;
          font-size: 11px;
          font-weight: 600;
          line-height: 16px;
          text-transform: uppercase;
          letter-spacing: 0.05em;
          color: var(--fp-on-surface-variant);
          background: var(--fp-surface-low);
          border-bottom: 1px solid var(--fp-card-border);
          white-space: nowrap;
        }
        td {
          padding: 8px 12px;
          border-bottom: 1px solid var(--fp-surface-low);
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
          max-width: 320px;
        }
        td.num {
          text-align: right;
          font-variant-numeric: tabular-nums;
          color: var(--fp-on-surface-variant);
        }
        tr:last-child td { border-bottom: none; }
        tbody tr:hover td { background: var(--fp-hover-bg); }
        .empty {
          text-align: center;
          color: var(--fp-outline);
          font-style: italic;
          padding: 24px;
        }
      </style>
      <table>
        <thead>
          <tr>${cols.map(c => `<th>${c.label}</th>`).join("")}</tr>
        </thead>
        <tbody>
          ${rows.length
            ? rows.map(r =>
                `<tr>${cols.map(c =>
                  `<td class="${c.numeric ? "num" : ""}">${r[c.key] ?? ""}</td>`
                ).join("")}</tr>`
              ).join("")
            : `<tr><td colspan="${cols.length}" class="empty">No files found</td></tr>`
          }
        </tbody>
      </table>
    `;
  }
}
customElements.define("fp-data-table", FpDataTable);

// ── <fp-bar-chart> ────────────────────────────────────────────────────────────
// SVG bar chart. Set via JS: el.data = [{ label, value }]

class FpBarChart extends HTMLElement {
  set data(points) { this._points = points; this._render(); }
  connectedCallback() { if (this._points) this._render(); }

  _render() {
    const pts = this._points ?? [];
    if (!pts.length) return;

    const W   = 540, H = 220;
    const PAD = { top: 20, right: 16, bottom: 52, left: 56 };
    const iW  = W - PAD.left - PAD.right;
    const iH  = H - PAD.top  - PAD.bottom;

    const max    = Math.max(...pts.map(p => p.value)) || 1;
    const barW   = Math.max(8, Math.floor((iW / pts.length) * 0.55));
    const step   = iW / pts.length;

    // Fluent Professional colors (hardcoded since shadow CSS vars aren't
    // accessible from JS getComputedStyle before first paint)
    const C = {
      bar:    "#005fb8",
      barHov: "#00488d",
      grid:   "#f3f2f1",
      axis:   "#edebe9",
      label:  "#605e5c",
      value:  "#1a1c1c",
    };

    // Y-axis nice ticks
    const rawStep = max / 4;
    const mag     = Math.pow(10, Math.floor(Math.log10(rawStep)));
    const niceStep = Math.ceil(rawStep / mag) * mag || 1;
    const ticks = [];
    for (let v = 0; v <= max * 1.05; v += niceStep) ticks.push(v);

    const toY = (v) => PAD.top + iH - (v / (ticks[ticks.length - 1] || 1)) * iH;

    const gridLines = ticks.map(v =>
      svgEl("line", {
        x1: PAD.left, y1: toY(v),
        x2: PAD.left + iW, y2: toY(v),
        stroke: v === 0 ? C.axis : C.grid, "stroke-width": 1,
      }),
    );

    const yLabels = ticks.map(v =>
      svgEl("text", {
        x: PAD.left - 8, y: toY(v) + 4,
        "text-anchor": "end",
        fill: C.label, "font-size": 10, "font-family": "'Inter','Segoe UI',sans-serif",
      }, [v >= 1000 ? (v / 1000).toFixed(0) + "k" : String(v)]),
    );

    const bars = pts.map((p, i) => {
      const bh  = Math.max(2, (p.value / (ticks[ticks.length - 1] || 1)) * iH);
      const x   = PAD.left + i * step + (step - barW) / 2;
      const y   = toY(p.value);
      const mid = x + barW / 2;

      return [
        svgEl("rect", {
          x, y, width: barW, height: bh,
          fill: C.bar, rx: 2,
        }),
        svgEl("text", {
          x: mid, y: H - PAD.bottom + 16,
          "text-anchor": "middle",
          fill: C.label, "font-size": 10,
          "font-family": "'Inter','Segoe UI',sans-serif",
        }, [p.label.length > 10 ? p.label.slice(0, 9) + "…" : p.label]),
        bh > 18
          ? svgEl("text", {
              x: mid, y: y - 5,
              "text-anchor": "middle",
              fill: C.value, "font-size": 9,
              "font-family": "'Inter','Segoe UI',sans-serif",
              "font-weight": "600",
            }, [p.value >= 1000 ? (p.value / 1000).toFixed(1) + "k" : p.value.toLocaleString()])
          : null,
      ];
    });

    const svg = svgEl("svg", {
      viewBox: `0 0 ${W} ${H}`,
      style: "width:100%;height:auto;display:block",
      role: "img", "aria-label": "Bar chart",
    }, [...gridLines, ...yLabels, ...bars.flat()]);

    const shadow = getShadow(this);
    shadow.innerHTML = `<style>${BASE_TOKENS}:host{display:block}</style>`;
    shadow.appendChild(svg);
  }
}
customElements.define("fp-bar-chart", FpBarChart);

// ── <fp-line-chart> ───────────────────────────────────────────────────────────
// SVG line chart with status dots.
// Set via JS: el.data = [{ label, value, ok? }]

class FpLineChart extends HTMLElement {
  set data(points) { this._points = points; this._render(); }
  connectedCallback() { if (this._points) this._render(); }

  _render() {
    const pts = this._points ?? [];
    if (!pts.length) return;

    const W   = 540, H = 190;
    const PAD = { top: 20, right: 16, bottom: 44, left: 48 };
    const iW  = W - PAD.left - PAD.right;
    const iH  = H - PAD.top  - PAD.bottom;

    const C = {
      line:   "#005fb8",
      area:   "#005fb8",
      ok:     "#107c10",
      fail:   "#d83b01",
      dot:    "#005fb8",
      grid:   "#f3f2f1",
      axis:   "#edebe9",
      label:  "#605e5c",
    };

    const maxV = Math.max(...pts.map(p => p.value)) * 1.15 || 1;
    const n    = pts.length;

    const toX = (i) => PAD.left + (n > 1 ? (i / (n - 1)) * iW : iW / 2);
    const toY = (v) => PAD.top + iH - (v / maxV) * iH;

    // Grid & Y-axis ticks
    const rawStep = maxV / 3;
    const mag     = Math.pow(10, Math.floor(Math.log10(rawStep || 1)));
    const niceStep = Math.ceil(rawStep / (mag || 1)) * (mag || 1) || 1;
    const ticks = [];
    for (let v = 0; v <= maxV * 1.05; v += niceStep) ticks.push(v);

    const gridLines = ticks.map(v =>
      svgEl("line", {
        x1: PAD.left, y1: toY(v),
        x2: PAD.left + iW, y2: toY(v),
        stroke: v === 0 ? C.axis : C.grid, "stroke-width": 1,
      }),
    );
    const yLabels = ticks.map(v =>
      svgEl("text", {
        x: PAD.left - 6, y: toY(v) + 4,
        "text-anchor": "end",
        fill: C.label, "font-size": 10,
        "font-family": "'Inter','Segoe UI',sans-serif",
      }, [v.toFixed(1) + "s"]),
    );

    // Area fill
    const areaCoords = n > 1 ? [
      `${toX(0)},${PAD.top + iH}`,
      ...pts.map((p, i) => `${toX(i)},${toY(p.value)}`),
      `${toX(n - 1)},${PAD.top + iH}`,
    ].join(" ") : null;

    const area = areaCoords
      ? svgEl("polygon", { points: areaCoords, fill: C.area, opacity: 0.07 })
      : null;

    // Line
    const lineCoords = pts.map((p, i) => `${toX(i)},${toY(p.value)}`).join(" ");
    const line = n > 1
      ? svgEl("polyline", {
          points: lineCoords,
          fill: "none", stroke: C.line,
          "stroke-width": 2, "stroke-linejoin": "round", "stroke-linecap": "round",
        })
      : null;

    // Status dots
    const dots = pts.map((p, i) =>
      svgEl("circle", {
        cx: toX(i), cy: toY(p.value), r: 4.5,
        fill: p.ok === false ? C.fail : C.ok,
        stroke: "#ffffff", "stroke-width": 1.5,
      }),
    );

    // X labels
    const xLabels = pts.map((p, i) =>
      svgEl("text", {
        x: toX(i), y: H - PAD.bottom + 16,
        "text-anchor": "middle",
        fill: C.label, "font-size": 10,
        "font-family": "'Inter','Segoe UI',sans-serif",
      }, [p.label]),
    );

    const svg = svgEl("svg", {
      viewBox: `0 0 ${W} ${H}`,
      style: "width:100%;height:auto;display:block",
      role: "img", "aria-label": "Line chart",
    }, [...gridLines, ...yLabels, area, line, ...dots, ...xLabels].filter(Boolean));

    const shadow = getShadow(this);
    shadow.innerHTML = `<style>${BASE_TOKENS}:host{display:block}</style>`;
    shadow.appendChild(svg);
  }
}
customElements.define("fp-line-chart", FpLineChart);

// ── <fp-panel> ────────────────────────────────────────────────────────────────
// Card container with optional title and subtitle.

class FpPanel extends HTMLElement {
  connectedCallback() {
    const title    = this.getAttribute("title")    ?? "";
    const subtitle = this.getAttribute("subtitle") ?? "";

    const shadow = getShadow(this);
    shadow.innerHTML = `
      <style>
        ${BASE_TOKENS}
        :host { display: block; }
        .card {
          background: var(--fp-surface);
          border: 1px solid var(--fp-card-border);
          border-radius: var(--fp-radius-lg);
          overflow: hidden;
        }
        .card-header {
          display: flex;
          align-items: baseline;
          gap: 8px;
          padding: 12px 16px 10px;
          border-bottom: 1px solid var(--fp-surface-low);
        }
        .card-title {
          font-size: 12px;
          font-weight: 600;
          line-height: 16px;
          text-transform: uppercase;
          letter-spacing: 0.07em;
          color: var(--fp-on-surface-variant);
        }
        .card-subtitle {
          font-size: 11px;
          color: var(--fp-outline);
        }
        .card-body { padding: 16px; }
      </style>
      <div class="card">
        ${title
          ? `<div class="card-header">
               <span class="card-title">${title}</span>
               ${subtitle ? `<span class="card-subtitle">${subtitle}</span>` : ""}
             </div>`
          : ""}
        <div class="card-body"><slot></slot></div>
      </div>
    `;
  }
}
customElements.define("fp-panel", FpPanel);

// ── <fp-legend> ───────────────────────────────────────────────────────────────
// Small legend row for chart status indicators.

class FpLegend extends HTMLElement {
  connectedCallback() {
    getShadow(this).innerHTML = `
      <style>
        ${BASE_TOKENS}
        :host {
          display: flex;
          gap: 16px;
          align-items: center;
          padding: 8px 0 0;
        }
        .item {
          display: flex;
          align-items: center;
          gap: 5px;
          font-size: 11px;
          color: var(--fp-outline);
        }
        .dot {
          width: 8px; height: 8px;
          border-radius: 50%;
          flex-shrink: 0;
        }
        .ok   { background: #107c10; }
        .fail { background: #d83b01; }
      </style>
      <div class="item"><span class="dot ok"></span> Build passed</div>
      <div class="item"><span class="dot fail"></span> Build failed</div>
    `;
  }
}
customElements.define("fp-legend", FpLegend);

// ── renderDashboard ───────────────────────────────────────────────────────────
// Called from the inline <script> in the webview HTML after data arrives.

window.renderDashboard = function(data) {
  const root = document.querySelector("body");

  // ── Metrics row ──
  const metricsRow = document.createElement("div");
  metricsRow.style.cssText = [
    "display:grid",
    "grid-template-columns:repeat(auto-fill,minmax(160px,1fr))",
    "gap:12px",
    "margin-bottom:24px",
  ].join(";");

  for (const m of data.metrics) {
    const card = document.createElement("fp-metric-card");
    card.setAttribute("label", m.label);
    card.setAttribute("value", m.value);
    if (m.delta) card.setAttribute("delta", m.delta);
    metricsRow.appendChild(card);
  }
  root.appendChild(metricsRow);

  // ── Charts row ──
  const chartsRow = document.createElement("div");
  chartsRow.style.cssText = [
    "display:grid",
    "grid-template-columns:1fr 1fr",
    "gap:16px",
    "margin-bottom:16px",
  ].join(";");

  if (data.wordChart?.length) {
    const panel = document.createElement("fp-panel");
    panel.setAttribute("title", "Words by section");
    const chart = document.createElement("fp-bar-chart");
    panel.appendChild(chart);
    chartsRow.appendChild(panel);
    // Defer data assignment until element is in DOM so shadow root exists
    requestAnimationFrame(() => {
      chart.data = data.wordChart.map(c => ({ label: c.label, value: c.words }));
    });
  }

  if (data.buildChart?.length) {
    const panel = document.createElement("fp-panel");
    panel.setAttribute("title", "Build time");
    panel.setAttribute("subtitle", "seconds per run");
    const chart = document.createElement("fp-line-chart");
    const legend = document.createElement("fp-legend");
    panel.appendChild(chart);
    panel.appendChild(legend);
    chartsRow.appendChild(panel);
    requestAnimationFrame(() => {
      chart.data = data.buildChart.map(b => ({
        label: b.label,
        value: b.seconds,
        ok:    b.ok,
      }));
    });
  }

  root.appendChild(chartsRow);

  // ── File table ──
  if (data.fileTable?.length) {
    const panel = document.createElement("fp-panel");
    panel.setAttribute("title", "Source files");
    panel.setAttribute("subtitle", `${data.fileTable.length} .tex files`);
    const table = document.createElement("fp-data-table");
    panel.appendChild(table);
    root.appendChild(panel);
    requestAnimationFrame(() => {
      table.data = {
        columns: [
          { key: "name",  label: "File" },
          { key: "words", label: "Words",  numeric: true },
          { key: "lines", label: "Lines",  numeric: true },
        ],
        rows: data.fileTable.map(f => ({
          name:  f.name,
          words: f.words.toLocaleString(),
          lines: f.lines.toLocaleString(),
        })),
      };
    });
  }
};
