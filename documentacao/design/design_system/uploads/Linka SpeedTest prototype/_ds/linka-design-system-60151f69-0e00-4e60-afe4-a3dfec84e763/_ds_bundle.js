/* @ds-bundle: {"format":4,"namespace":"LinkaDesignSystem_60151f","components":[{"name":"Wordmark","sourcePath":"components/brand/Wordmark.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Card","sourcePath":"components/core/Card.jsx"},{"name":"DetailsDisclosure","sourcePath":"components/speedtest/DetailsDisclosure.jsx"},{"name":"MetricRing","sourcePath":"components/speedtest/MetricRing.jsx"},{"name":"PhaseDots","sourcePath":"components/speedtest/PhaseDots.jsx"},{"name":"StatDisplay","sourcePath":"components/speedtest/StatDisplay.jsx"}],"sourceHashes":{"components/brand/Wordmark.jsx":"68277d798d4d","components/core/Button.jsx":"8ea0642fc24f","components/core/Card.jsx":"7eb45b21d7ff","components/speedtest/DetailsDisclosure.jsx":"c1fedba297b0","components/speedtest/MetricRing.jsx":"17afe797e965","components/speedtest/PhaseDots.jsx":"0a7aee02636f","components/speedtest/StatDisplay.jsx":"b9280f061240","ui_kits/speedtest-app/MeasuringScreen.jsx":"4fc0269b31f3","ui_kits/speedtest-app/ResultScreen.jsx":"1199f5626952"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.LinkaDesignSystem_60151f = window.LinkaDesignSystem_60151f || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/brand/Wordmark.jsx
try { (() => {
function Wordmark({
  size = 'md',
  color
}) {
  const dims = {
    sm: {
      text: 14,
      dot: 0.16,
      pad: '5px 9px',
      radius: 7
    },
    md: {
      text: 17,
      dot: 0.16,
      pad: '7px 13px',
      radius: 9
    },
    lg: {
      text: 34,
      dot: 0.15,
      pad: '14px 24px',
      radius: 14
    }
  }[size] || {};
  const fg = color || 'var(--brand-on-surface)';
  return /*#__PURE__*/React.createElement("span", {
    role: "img",
    "aria-label": "Linka",
    style: {
      display: 'inline-flex',
      alignItems: 'baseline',
      fontFamily: 'var(--font-display)',
      fontWeight: 'var(--weight-semibold)',
      letterSpacing: 'var(--tracking-brand)',
      fontSize: dims.text,
      color: fg,
      lineHeight: 1,
      background: 'var(--brand-surface)',
      padding: dims.pad,
      borderRadius: dims.radius
    }
  }, /*#__PURE__*/React.createElement("span", null, "l"), /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'relative',
      display: 'inline-block'
    }
  }, /*#__PURE__*/React.createElement("span", null, "\u0131"), /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: '-0.32em',
      left: '50%',
      transform: 'translateX(-50%)',
      width: `${dims.dot}em`,
      height: `${dims.dot}em`,
      borderRadius: '50%',
      background: 'var(--color-accent-warm)'
    }
  })), /*#__PURE__*/React.createElement("span", null, "nka"));
}
Object.assign(__ds_scope, { Wordmark });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/brand/Wordmark.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function Button({
  children,
  icon,
  variant = 'ghost',
  onClick,
  style
}) {
  const base = {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 7,
    fontFamily: 'var(--font-body)',
    fontSize: 'var(--text-sm)',
    fontWeight: 'var(--weight-medium)',
    padding: '10px 4px',
    borderRadius: 'var(--radius-sm)',
    border: 0,
    background: 'none',
    cursor: 'pointer',
    transition: 'color 0.15s ease',
    color: variant === 'subtle' ? 'var(--text-secondary)' : 'var(--text-primary)'
  };
  return /*#__PURE__*/React.createElement("button", {
    onClick: onClick,
    style: {
      ...base,
      ...style
    },
    onMouseEnter: e => e.currentTarget.style.color = 'var(--brand-accent)',
    onMouseLeave: e => e.currentTarget.style.color = base.color,
    onFocus: e => e.currentTarget.style.outline = '2px solid var(--focus-ring)',
    onBlur: e => e.currentTarget.style.outline = 'none'
  }, icon, children);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Card.jsx
try { (() => {
function Card({
  children,
  dashed = false,
  label,
  padding = 'var(--space-md)',
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      border: `var(--border-width) ${dashed ? 'dashed' : 'solid'} var(--border-default)`,
      borderRadius: dashed ? 'var(--radius)' : 'var(--radius-lg)',
      background: 'var(--surface-card)',
      padding,
      ...style
    }
  }, label && /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: -9,
      left: 14,
      background: 'var(--surface-page)',
      padding: '0 8px',
      fontFamily: 'var(--font-mono)',
      fontSize: 10,
      letterSpacing: 'var(--tracking-wide)',
      textTransform: 'uppercase',
      color: 'var(--text-secondary)'
    }
  }, label), children);
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Card.jsx", error: String((e && e.message) || e) }); }

// components/speedtest/DetailsDisclosure.jsx
try { (() => {
const {
  useState
} = React;
function DetailsDisclosure({
  label = 'Ver detalhes da medição',
  children,
  defaultOpen = false
}) {
  const [open, setOpen] = useState(defaultOpen);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement("button", {
    "aria-expanded": open,
    onClick: () => setOpen(o => !o),
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 6,
      marginTop: 'var(--space-xl)',
      fontSize: 14,
      color: 'var(--text-secondary)',
      padding: '6px 4px',
      borderRadius: 6,
      border: 0,
      background: 'none',
      cursor: 'pointer',
      fontFamily: 'var(--font-body)'
    },
    onMouseEnter: e => e.currentTarget.style.color = 'var(--brand-accent)',
    onMouseLeave: e => e.currentTarget.style.color = 'var(--text-secondary)'
  }, label, /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2",
    style: {
      width: 13,
      height: 13,
      transition: 'transform 0.2s ease',
      transform: open ? 'rotate(180deg)' : 'none'
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M6 9l6 6 6-6"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: 460,
      width: 'min(90vw, 460px)',
      margin: '0 auto',
      overflow: 'hidden',
      maxHeight: open ? 160 : 0,
      opacity: open ? 1 : 0,
      marginTop: open ? 'var(--space-md)' : 0,
      transition: 'max-height 0.3s ease, opacity 0.25s ease, margin-top 0.3s ease'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      lineHeight: 'var(--leading-relaxed)',
      color: 'var(--text-secondary)'
    }
  }, children)));
}
Object.assign(__ds_scope, { DetailsDisclosure });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/speedtest/DetailsDisclosure.jsx", error: String((e && e.message) || e) }); }

// components/speedtest/MetricRing.jsx
try { (() => {
function MetricRing({
  progress = 0,
  value,
  unit,
  connecting = false,
  size = 220
}) {
  const circ = 339.3;
  const offset = circ * (1 - progress);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      width: size,
      aspectRatio: '1',
      display: 'grid',
      placeItems: 'center',
      margin: '0 auto'
    }
  }, /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 120 120",
    style: {
      position: 'absolute',
      inset: 0,
      width: '100%',
      height: '100%',
      transform: 'rotate(-90deg)'
    }
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "60",
    cy: "60",
    r: "54",
    fill: "none",
    stroke: "var(--border-default)",
    strokeWidth: "3"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "60",
    cy: "60",
    r: "54",
    fill: "none",
    stroke: "var(--brand-accent)",
    strokeWidth: "3",
    strokeLinecap: "round",
    strokeDasharray: circ,
    strokeDashoffset: offset,
    opacity: connecting ? 0 : 1,
    style: {
      transition: 'stroke-dashoffset 0.12s linear'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center',
      padding: '0 12%',
      maxWidth: '100%'
    }
  }, connecting ? /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: Math.round(size * 0.1),
      fontWeight: 'var(--weight-medium)',
      color: 'var(--text-secondary)',
      whiteSpace: 'nowrap'
    }
  }, value) : /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontVariantNumeric: 'tabular-nums',
      fontSize: Math.round(size * 0.24),
      fontWeight: 'var(--weight-semibold)',
      letterSpacing: 'var(--tracking-tight)',
      lineHeight: 1,
      color: 'var(--text-primary)',
      whiteSpace: 'nowrap'
    }
  }, value, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: '0.22em',
      color: 'var(--text-secondary)',
      marginLeft: 4
    }
  }, unit))));
}
Object.assign(__ds_scope, { MetricRing });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/speedtest/MetricRing.jsx", error: String((e && e.message) || e) }); }

// components/speedtest/PhaseDots.jsx
try { (() => {
function PhaseDots({
  phases,
  activeKey
}) {
  const order = k => phases.findIndex(p => p.key === k);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'center',
      gap: 8,
      marginTop: 'var(--space-lg)'
    }
  }, phases.map(p => {
    const done = order(p.key) < order(activeKey);
    const current = p.key === activeKey;
    const color = current ? 'var(--text-primary)' : done ? 'var(--text-secondary)' : 'var(--border-default)';
    return /*#__PURE__*/React.createElement("span", {
      key: p.key,
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 6,
        fontFamily: 'var(--font-mono)',
        fontSize: 11,
        letterSpacing: 'var(--tracking-wide)',
        textTransform: 'uppercase',
        color,
        fontWeight: current ? 'var(--weight-semibold)' : 'var(--weight-regular)'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 6,
        height: 6,
        borderRadius: '50%',
        background: color
      }
    }), p.label);
  }));
}
Object.assign(__ds_scope, { PhaseDots });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/speedtest/PhaseDots.jsx", error: String((e && e.message) || e) }); }

// components/speedtest/StatDisplay.jsx
try { (() => {
function StatDisplay({
  label,
  value,
  unit,
  accent = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement("p", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 12,
      letterSpacing: 'var(--tracking-wider)',
      textTransform: 'uppercase',
      color: accent ? 'var(--brand-accent)' : 'var(--text-secondary)',
      margin: '0 0 10px'
    }
  }, label), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontVariantNumeric: 'tabular-nums',
      fontSize: 'clamp(48px, 9vw, 84px)',
      fontWeight: 'var(--weight-bold)',
      letterSpacing: 'var(--tracking-tight)',
      lineHeight: 1,
      color: 'var(--text-primary)'
    }
  }, value), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'clamp(14px, 2vw, 18px)',
      color: 'var(--text-secondary)',
      marginLeft: 3,
      fontWeight: 'var(--weight-medium)'
    }
  }, unit)));
}
Object.assign(__ds_scope, { StatDisplay });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/speedtest/StatDisplay.jsx", error: String((e && e.message) || e) }); }

// ui_kits/speedtest-app/MeasuringScreen.jsx
try { (() => {
function MeasuringScreen({
  connecting,
  phase,
  value,
  unit,
  progress,
  label
}) {
  const {
    MetricRing,
    PhaseDots,
    Wordmark
  } = window.LinkaDesignSystem_60151f;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '56px 24px',
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement(MetricRing, {
    connecting: connecting,
    value: value,
    unit: unit,
    progress: progress
  }), /*#__PURE__*/React.createElement("p", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 12,
      letterSpacing: '0.1em',
      textTransform: 'uppercase',
      color: 'var(--text-secondary)',
      margin: '20px 0 12px'
    }
  }, "Linka SpeedTest"), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 15,
      color: 'var(--text-secondary)',
      minHeight: 20
    }
  }, label), /*#__PURE__*/React.createElement(PhaseDots, {
    phases: [{
      key: 'download',
      label: 'Download'
    }, {
      key: 'upload',
      label: 'Upload'
    }],
    activeKey: phase
  }));
}
window.MeasuringScreen = MeasuringScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/speedtest-app/MeasuringScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/speedtest-app/ResultScreen.jsx
try { (() => {
function ResultScreen({
  download,
  upload,
  operator,
  duration,
  ping,
  detailsOpen,
  onToggleDetails,
  onRetest
}) {
  const {
    StatDisplay,
    DetailsDisclosure,
    Button,
    Card
  } = window.LinkaDesignSystem_60151f;
  const Chevron = () => /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2",
    style: {
      width: 13,
      height: 13,
      transform: detailsOpen ? 'rotate(180deg)' : 'none',
      transition: 'transform .2s'
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M6 9l6 6 6-6"
  }));
  const Retry = () => /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2",
    style: {
      width: 14,
      height: 14
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M3 12a9 9 0 1 1 3 6.7"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M3 21v-6h6"
  }));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '56px 24px',
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 'clamp(28px,7vw,88px)',
      justifyContent: 'center',
      flexWrap: 'wrap'
    }
  }, /*#__PURE__*/React.createElement(StatDisplay, {
    label: "Download",
    value: download,
    unit: "Mbps",
    accent: true
  }), /*#__PURE__*/React.createElement(StatDisplay, {
    label: "Upload",
    value: upload,
    unit: "Mbps"
  })), /*#__PURE__*/React.createElement("p", {
    style: {
      fontFamily: 'var(--font-display)',
      fontSize: 26,
      fontWeight: 700,
      letterSpacing: '-0.015em',
      marginTop: 20
    }
  }, "Sua conex\xE3o est\xE1 pronta."), /*#__PURE__*/React.createElement(Button, {
    variant: "subtle",
    icon: null,
    onClick: onToggleDetails,
    style: {
      marginTop: 32
    }
  }, "Ver detalhes da medi\xE7\xE3o", /*#__PURE__*/React.createElement(Chevron, null)), detailsOpen && /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 20
    }
  }, /*#__PURE__*/React.createElement(DetailsDisclosure, {
    defaultOpen: true
  }, "Operadora ", /*#__PURE__*/React.createElement("b", null, operator), " \xB7 Provedor ", /*#__PURE__*/React.createElement("b", null, "Linka Network Labs"), " \xB7 Dura\xE7\xE3o ", /*#__PURE__*/React.createElement("b", null, duration, "s"), " \xB7 Ping ", /*#__PURE__*/React.createElement("b", null, ping, " ms"))), /*#__PURE__*/React.createElement(Button, {
    icon: /*#__PURE__*/React.createElement(Retry, null),
    onClick: onRetest,
    style: {
      marginTop: 24
    }
  }, "Testar novamente"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 40,
      width: '100%',
      maxWidth: 560
    }
  }, /*#__PURE__*/React.createElement(Card, {
    dashed: true,
    label: "Publicidade",
    style: {
      minHeight: 90,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      fontFamily: 'var(--font-mono)'
    }
  }, "Espa\xE7o reservado para an\xFAncio \xB7 728\xD790"))));
}
window.ResultScreen = ResultScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/speedtest-app/ResultScreen.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Wordmark = __ds_scope.Wordmark;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.DetailsDisclosure = __ds_scope.DetailsDisclosure;

__ds_ns.MetricRing = __ds_scope.MetricRing;

__ds_ns.PhaseDots = __ds_scope.PhaseDots;

__ds_ns.StatDisplay = __ds_scope.StatDisplay;

})();
