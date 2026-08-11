/* @ds-bundle: {"format":4,"namespace":"LinkaDesignSystem_60151f","components":[{"name":"Wordmark","sourcePath":"components/brand/Wordmark.jsx"},{"name":"ComparisonTable","sourcePath":"components/content/ComparisonTable.jsx"},{"name":"LegalSection","sourcePath":"components/content/LegalSection.jsx"},{"name":"StepItem","sourcePath":"components/content/StepItem.jsx"},{"name":"ValueCard","sourcePath":"components/content/ValueCard.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Card","sourcePath":"components/core/Card.jsx"},{"name":"Eyebrow","sourcePath":"components/core/Eyebrow.jsx"},{"name":"Icon","sourcePath":"components/core/Icon.jsx"},{"name":"StatusLabel","sourcePath":"components/core/StatusLabel.jsx"},{"name":"TextLink","sourcePath":"components/core/TextLink.jsx"},{"name":"PageHero","sourcePath":"components/layout/PageHero.jsx"},{"name":"SiteFooter","sourcePath":"components/layout/SiteFooter.jsx"},{"name":"SiteHeader","sourcePath":"components/layout/SiteHeader.jsx"},{"name":"AdSlot","sourcePath":"components/speedtest/AdSlot.jsx"},{"name":"DetailsDisclosure","sourcePath":"components/speedtest/DetailsDisclosure.jsx"},{"name":"MetricRing","sourcePath":"components/speedtest/MetricRing.jsx"},{"name":"PhaseDots","sourcePath":"components/speedtest/PhaseDots.jsx"},{"name":"StatDisplay","sourcePath":"components/speedtest/StatDisplay.jsx"}],"sourceHashes":{"components/brand/Wordmark.jsx":"d419c45dc0ed","components/content/ComparisonTable.jsx":"fc301628d7b6","components/content/LegalSection.jsx":"8d542d8f003d","components/content/StepItem.jsx":"44ea0cd8c3a6","components/content/ValueCard.jsx":"2eeff7e56187","components/core/Button.jsx":"c7856a20c7a9","components/core/Card.jsx":"a710afcdf7f4","components/core/Eyebrow.jsx":"1fed75f4fe49","components/core/Icon.jsx":"41ff395aefbe","components/core/StatusLabel.jsx":"75b3357a6b1a","components/core/TextLink.jsx":"80ba359b974e","components/layout/PageHero.jsx":"c8fa47063408","components/layout/SiteFooter.jsx":"f278d4fffd7b","components/layout/SiteHeader.jsx":"436e755d54df","components/speedtest/AdSlot.jsx":"c79a623dc57a","components/speedtest/DetailsDisclosure.jsx":"6d55e1ee57fd","components/speedtest/MetricRing.jsx":"17afe797e965","components/speedtest/PhaseDots.jsx":"f8b51106c2e8","components/speedtest/StatDisplay.jsx":"b9280f061240","guidelines/frames/browser-window.jsx":"ffeb1267e10b","guidelines/frames/ios-frame.jsx":"24642b887be3","guidelines/frames/macos-window.jsx":"d7346db5cca8"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.LinkaDesignSystem_60151f = window.LinkaDesignSystem_60151f || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/brand/Wordmark.jsx
try { (() => {
const HEIGHTS = {
  sm: 22,
  md: 28,
  lg: 60
};
function Wordmark({
  size = 'md',
  color,
  dotColor
}) {
  const h = HEIGHTS[size] || HEIGHTS.md;
  const fg = color || 'var(--text-primary)';
  return /*#__PURE__*/React.createElement("svg", {
    role: "img",
    "aria-label": "linka",
    viewBox: "48 53 170 71",
    height: h,
    width: h * (170 / 71),
    style: {
      display: 'block',
      overflow: 'visible'
    }
  }, /*#__PURE__*/React.createElement("g", {
    fill: "none",
    stroke: fg,
    strokeWidth: "9.6",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M53.5 59V108"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M92.5 75V108"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M92.5 87c0-8 8-12.5 17.5-12.5 6.5 0 9.5 5.5 9.5 12v21"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M139 59.5V107.5"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M163.5 75.5 142.5 96.5"
  }), /*#__PURE__*/React.createElement("path", {
    d: "m149 91 16.5 16.5"
  }), /*#__PURE__*/React.createElement("ellipse", {
    cx: "195.5",
    cy: "91.5",
    rx: "16.25",
    ry: "17.8"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M211.5 75v32.5"
  })), /*#__PURE__*/React.createElement("path", {
    d: "M72.5 86.75v30.25",
    fill: "none",
    stroke: fg,
    strokeWidth: "11.4",
    strokeLinecap: "round"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "72.5",
    cy: "67.5",
    r: "10",
    fill: dotColor || 'var(--color-accent-warm)'
  }));
}
Object.assign(__ds_scope, { Wordmark });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/brand/Wordmark.jsx", error: String((e && e.message) || e) }); }

// components/content/ComparisonTable.jsx
try { (() => {
function ComparisonTable({
  columns = [],
  rows = [],
  highlight = 0,
  style
}) {
  const grid = {
    display: 'grid',
    gridTemplateColumns: '1.4fr ' + columns.map(() => '1fr').join(' ')
  };
  const cell = {
    padding: '14px 16px',
    fontSize: 'var(--text-sm)'
  };
  return /*#__PURE__*/React.createElement("div", {
    style: {
      border: 'var(--border-width) solid var(--border-default)',
      borderRadius: 'var(--radius-lg)',
      overflow: 'hidden',
      textAlign: 'left',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      ...grid,
      background: 'var(--color-fg-soft)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: cell
  }), columns.map((c, i) => /*#__PURE__*/React.createElement("div", {
    key: c,
    style: {
      ...cell,
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-caption2)',
      letterSpacing: 'var(--tracking-wide)',
      textTransform: 'uppercase',
      color: i === highlight ? 'var(--text-primary)' : 'var(--text-secondary)',
      fontWeight: i === highlight ? 'var(--weight-semibold)' : 'var(--weight-regular)'
    }
  }, c))), rows.map(r => /*#__PURE__*/React.createElement("div", {
    key: r.label,
    style: {
      ...grid,
      borderTop: 'var(--border-width) solid var(--border-default)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      ...cell,
      color: 'var(--text-secondary)'
    }
  }, r.label), r.values.map((v, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      ...cell,
      color: i === highlight ? 'var(--text-primary)' : 'var(--text-secondary)'
    }
  }, v)))));
}
Object.assign(__ds_scope, { ComparisonTable });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/content/ComparisonTable.jsx", error: String((e && e.message) || e) }); }

// components/content/LegalSection.jsx
try { (() => {
function LegalSection({
  title,
  children,
  spacing = 28,
  style
}) {
  return /*#__PURE__*/React.createElement("section", {
    style: {
      marginBottom: spacing,
      ...style
    }
  }, /*#__PURE__*/React.createElement("h2", {
    style: {
      fontFamily: 'var(--font-display)',
      fontSize: 'var(--text-title3)',
      fontWeight: 'var(--weight-semibold)',
      margin: '0 0 10px'
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 'var(--text-subheadline)',
      lineHeight: 1.65,
      color: 'var(--text-secondary)'
    }
  }, children));
}
Object.assign(__ds_scope, { LegalSection });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/content/LegalSection.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
const VARIANTS = {
  plain: {
    bg: 'transparent',
    fg: 'var(--text-primary)',
    fgHover: 'var(--brand-accent)'
  },
  subtle: {
    bg: 'transparent',
    fg: 'var(--text-secondary)',
    fgHover: 'var(--brand-accent)'
  },
  tinted: {
    bg: 'var(--color-accent-soft)',
    fg: 'var(--brand-accent)',
    fgHover: 'var(--brand-accent)'
  },
  filled: {
    bg: 'var(--brand-accent)',
    fg: 'var(--text-on-accent)',
    fgHover: 'var(--text-on-accent)'
  }
};
function Button({
  children,
  icon,
  variant = 'plain',
  onClick,
  style
}) {
  const v = VARIANTS[variant] || VARIANTS.plain;
  const raised = variant === 'filled' || variant === 'tinted';
  const base = {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 7,
    fontFamily: 'var(--font-body)',
    fontSize: 'var(--text-headline)',
    fontWeight: 'var(--weight-semibold)',
    padding: raised ? '10px 18px' : '10px 4px',
    minHeight: raised ? 'var(--touch-target)' : undefined,
    borderRadius: raised ? 'var(--radius)' : 'var(--radius-sm)',
    border: 0,
    background: v.bg,
    color: v.fg,
    cursor: 'pointer',
    transition: 'transform var(--duration-fast) var(--ease-spring), opacity var(--duration-fast) var(--ease-standard), color var(--duration-fast) var(--ease-standard)'
  };
  return /*#__PURE__*/React.createElement("button", {
    onClick: onClick,
    style: {
      ...base,
      ...style
    },
    onMouseEnter: e => {
      if (!raised) e.currentTarget.style.color = v.fgHover;
    },
    onMouseLeave: e => {
      e.currentTarget.style.color = v.fg;
      e.currentTarget.style.transform = 'none';
      e.currentTarget.style.opacity = 1;
    },
    onMouseDown: e => {
      e.currentTarget.style.transform = 'scale(var(--press-scale))';
      e.currentTarget.style.opacity = 0.75;
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = 'none';
      e.currentTarget.style.opacity = 1;
    }
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
      border: `${dashed ? 'var(--border-width)' : 'var(--hairline)'} ${dashed ? 'dashed' : 'solid'} var(--border-default)`,
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

// components/core/Eyebrow.jsx
try { (() => {
const SIZES = {
  sm: {
    fontSize: 11,
    letterSpacing: 'var(--tracking-wide)'
  },
  md: {
    fontSize: 12,
    letterSpacing: 'var(--tracking-wider)'
  }
};
const TONES = {
  secondary: 'var(--text-secondary)',
  primary: 'var(--text-primary)',
  accent: 'var(--color-accent-warm)'
};
function Eyebrow({
  children,
  size = 'md',
  tone = 'secondary',
  as = 'p',
  style
}) {
  const Tag = as;
  return /*#__PURE__*/React.createElement(Tag, {
    style: {
      margin: 0,
      fontFamily: 'var(--font-mono)',
      fontWeight: 'var(--weight-regular)',
      textTransform: 'uppercase',
      color: TONES[tone] || TONES.secondary,
      ...(SIZES[size] || SIZES.md),
      ...style
    }
  }, children);
}
Object.assign(__ds_scope, { Eyebrow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Eyebrow.jsx", error: String((e && e.message) || e) }); }

// components/content/StepItem.jsx
try { (() => {
function StepItem({
  number,
  label,
  children,
  style
}) {
  return /*#__PURE__*/React.createElement(__ds_scope.Card, {
    style: style
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 20,
      alignItems: 'flex-start',
      textAlign: 'left'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-footnote)',
      color: 'var(--text-secondary)',
      minWidth: 20
    }
  }, number), /*#__PURE__*/React.createElement("div", null, label && /*#__PURE__*/React.createElement(__ds_scope.Eyebrow, {
    size: "sm",
    style: {
      marginBottom: 8
    }
  }, label), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 'var(--text-subheadline)',
      lineHeight: 1.55,
      color: 'var(--text-primary)',
      margin: 0,
      textWrap: 'pretty'
    }
  }, children))));
}
Object.assign(__ds_scope, { StepItem });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/content/StepItem.jsx", error: String((e && e.message) || e) }); }

// components/content/ValueCard.jsx
try { (() => {
function ValueCard({
  label,
  children,
  action,
  align = 'left',
  style
}) {
  return /*#__PURE__*/React.createElement(__ds_scope.Card, {
    style: {
      display: 'flex',
      flexDirection: 'column',
      textAlign: align,
      ...style
    }
  }, label && /*#__PURE__*/React.createElement(__ds_scope.Eyebrow, {
    size: "sm",
    style: {
      marginBottom: 10
    }
  }, label), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 'var(--text-subheadline)',
      lineHeight: 1.55,
      color: 'var(--text-primary)',
      margin: 0,
      textWrap: 'pretty'
    }
  }, children), action && /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14
    }
  }, action));
}
Object.assign(__ds_scope, { ValueCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/content/ValueCard.jsx", error: String((e && e.message) || e) }); }

// components/core/Icon.jsx
try { (() => {
const PATHS = {
  'chevron-down': ['M6 9l6 6 6-6'],
  'chevron-right': ['M9 6l6 6-6 6'],
  'chevron-left': ['M15 6l-6 6 6 6'],
  retry: ['M3 12a9 9 0 1 1 3 6.7', 'M3 21v-6h6'],
  'arrow-right': ['M5 12h14', 'M13 5l7 7-7 7'],
  close: ['M6 6l12 12', 'M18 6L6 18'],
  menu: ['M4 7h16', 'M4 12h16', 'M4 17h16']
};
function Icon({
  name,
  size = 16,
  rotate = 0,
  style
}) {
  const d = PATHS[name] || [];
  return /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2",
    strokeLinecap: "round",
    strokeLinejoin: "round",
    style: {
      width: size,
      height: size,
      flexShrink: 0,
      transform: rotate ? 'rotate(' + rotate + 'deg)' : undefined,
      transition: 'transform var(--duration-fast, .2s) var(--ease-spring)',
      ...style
    }
  }, d.map((p, i) => /*#__PURE__*/React.createElement("path", {
    key: i,
    d: p
  })));
}
Object.assign(__ds_scope, { Icon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Icon.jsx", error: String((e && e.message) || e) }); }

// components/core/StatusLabel.jsx
try { (() => {
function StatusLabel({
  children,
  tone = 'active',
  align = 'center',
  style
}) {
  const dot = tone === 'active' ? 'var(--color-accent-warm)' : 'var(--border-default)';
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: align === 'center' ? 'center' : 'flex-start',
      gap: 8,
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 6,
      height: 6,
      borderRadius: '50%',
      background: dot,
      flexShrink: 0
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-caption2)',
      letterSpacing: 'var(--tracking-wide)',
      textTransform: 'uppercase',
      color: 'var(--text-secondary)'
    }
  }, children));
}
Object.assign(__ds_scope, { StatusLabel });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/StatusLabel.jsx", error: String((e && e.message) || e) }); }

// components/core/TextLink.jsx
try { (() => {
function TextLink({
  children,
  href = '#',
  arrow = true,
  onClick,
  style
}) {
  return /*#__PURE__*/React.createElement("a", {
    href: href,
    onClick: onClick,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 5,
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-footnote)',
      color: 'var(--text-primary)',
      textDecoration: 'none',
      transition: 'color var(--duration-fast, .15s) var(--ease-standard)',
      ...style
    },
    onMouseEnter: e => e.currentTarget.style.color = 'var(--color-accent-warm)',
    onMouseLeave: e => e.currentTarget.style.color = 'var(--text-primary)'
  }, children, arrow && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "arrow-right",
    size: 13
  }));
}
Object.assign(__ds_scope, { TextLink });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/TextLink.jsx", error: String((e && e.message) || e) }); }

// components/layout/PageHero.jsx
try { (() => {
function PageHero({
  eyebrow,
  title,
  lead,
  children,
  align = 'center',
  maxWidth = 720,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth,
      width: '100%',
      textAlign: align,
      ...style
    }
  }, eyebrow && /*#__PURE__*/React.createElement(__ds_scope.Eyebrow, {
    style: {
      marginBottom: 16
    }
  }, eyebrow), /*#__PURE__*/React.createElement("h1", {
    style: {
      fontFamily: 'var(--font-display)',
      fontSize: 40,
      fontWeight: 'var(--weight-bold)',
      letterSpacing: 'var(--tracking-snug)',
      lineHeight: 1.15,
      margin: '0 0 24px',
      textWrap: 'pretty'
    }
  }, title), lead && /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 'var(--text-md)',
      lineHeight: 1.6,
      color: 'var(--text-secondary)',
      margin: 0,
      textWrap: 'pretty'
    }
  }, lead), children);
}
Object.assign(__ds_scope, { PageHero });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/layout/PageHero.jsx", error: String((e && e.message) || e) }); }

// components/layout/SiteFooter.jsx
try { (() => {
function SiteFooter({
  copyright = '© 2026 Linka Speedtest',
  tagline = 'Meça sua internet em segundos.',
  style
}) {
  return /*#__PURE__*/React.createElement("footer", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: 16,
      padding: '20px var(--gutter)',
      borderTop: 'var(--hairline) solid var(--border-default)',
      fontSize: 'var(--text-caption1)',
      color: 'var(--text-secondary)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Wordmark, {
    size: "sm"
  }), /*#__PURE__*/React.createElement("span", null, copyright)), /*#__PURE__*/React.createElement("span", null, tagline));
}
Object.assign(__ds_scope, { SiteFooter });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/layout/SiteFooter.jsx", error: String((e && e.message) || e) }); }

// components/layout/SiteHeader.jsx
try { (() => {
function SiteHeader({
  items = [],
  activeHref,
  homeHref = '#',
  style
}) {
  return /*#__PURE__*/React.createElement("header", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: 'var(--gutter)',
      padding: '22px var(--gutter)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("a", {
    href: homeHref,
    "aria-label": "linka",
    style: {
      display: 'block',
      lineHeight: 0
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Wordmark, {
    size: "md"
  })), /*#__PURE__*/React.createElement("nav", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 28,
      flexWrap: 'wrap'
    }
  }, items.map(it => {
    const active = it.href === activeHref;
    return /*#__PURE__*/React.createElement("a", {
      key: it.href + it.label,
      href: active ? '#' : it.href,
      "aria-current": active ? 'page' : undefined,
      style: {
        fontSize: 'var(--text-sm)',
        color: active ? 'var(--text-primary)' : 'var(--text-secondary)',
        textDecoration: 'none',
        transition: 'color var(--duration-fast, .15s) var(--ease-standard)'
      },
      onMouseEnter: e => e.currentTarget.style.color = 'var(--text-primary)',
      onMouseLeave: e => e.currentTarget.style.color = active ? 'var(--text-primary)' : 'var(--text-secondary)'
    }, it.label);
  })));
}
Object.assign(__ds_scope, { SiteHeader });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/layout/SiteHeader.jsx", error: String((e && e.message) || e) }); }

// components/speedtest/AdSlot.jsx
try { (() => {
const SIZES = {
  leaderboard: {
    w: 728,
    h: 90,
    minHeight: 180,
    label: '728×90'
  },
  banner: {
    w: 320,
    h: 50,
    minHeight: 90,
    label: '320×50'
  }
};
function AdSlot({
  format = 'leaderboard',
  label = 'Publicidade',
  note,
  style
}) {
  const s = SIZES[format] || SIZES.leaderboard;
  return /*#__PURE__*/React.createElement(__ds_scope.Card, {
    dashed: true,
    label: label,
    style: {
      width: '100%',
      maxWidth: s.w,
      minHeight: s.minHeight,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--text-caption1)',
      color: 'var(--text-secondary)'
    }
  }, note || 'Espaço reservado para anúncio · ' + s.label));
}
Object.assign(__ds_scope, { AdSlot });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/speedtest/AdSlot.jsx", error: String((e && e.message) || e) }); }

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
      borderRadius: 'var(--radius-sm)',
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
    strokeWidth: "1.75",
    strokeLinecap: "round",
    strokeLinejoin: "round",
    style: {
      width: 13,
      height: 13,
      transition: 'transform var(--duration-base) var(--ease-spring)',
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
      transition: 'max-height var(--duration-slow) var(--ease-spring), opacity var(--duration-base) var(--ease-standard), margin-top var(--duration-slow) var(--ease-spring)'
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
        fontWeight: current ? 'var(--weight-semibold)' : 'var(--weight-regular)',
        transition: 'color var(--duration-base) var(--ease-standard)'
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

// guidelines/frames/browser-window.jsx
try { (() => {
// @ds-adherence-ignore -- omelette starter scaffold (raw elements/hex/px by design)
// Copied omelette starter. Re-running copy_starter_component with this kind overwrites this file with the latest version (page content is unaffected).

/* BEGIN USAGE */
// Chrome.jsx — Simplified Chrome browser window (dark theme, macOS)
// No dependencies, no image assets. All inline styles + inline SVG.
// Exports (to window): ChromeWindow, ChromeTabBar, ChromeToolbar, ChromeTab, ChromeTrafficLights
//
// Usage — wrap your page content in <ChromeWindow> to get the tab bar + URL bar:
//
//   <ChromeWindow width={1100} height={680} url="acme.design/pricing">
//     ...your page content...
//   </ChromeWindow>
/* END USAGE */

const CHROME_C = {
  barBg: '#202124',
  tabBg: '#35363a',
  text: '#e8eaed',
  dim: '#9aa0a6',
  urlBg: '#282a2d'
};
function ChromeTrafficLights() {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      padding: '0 14px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 12,
      height: 12,
      borderRadius: '50%',
      background: '#ff5f57'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 12,
      height: 12,
      borderRadius: '50%',
      background: '#febc2e'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 12,
      height: 12,
      borderRadius: '50%',
      background: '#28c840'
    }
  }));
}

// Single tab (active has curved scoops)
function ChromeTab({
  title = 'New Tab',
  active = false
}) {
  const curve = flip => /*#__PURE__*/React.createElement("svg", {
    width: "8",
    height: "10",
    viewBox: "0 0 8 10",
    style: {
      position: 'absolute',
      bottom: 0,
      [flip ? 'right' : 'left']: -8,
      transform: flip ? 'scaleX(-1)' : 'none'
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M0 10C2 9 6 8 8 0V10H0Z",
    fill: CHROME_C.tabBg
  }));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      height: 34,
      alignSelf: 'flex-end',
      padding: '0 12px',
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      background: active ? CHROME_C.tabBg : 'transparent',
      borderRadius: '8px 8px 0 0',
      minWidth: 120,
      maxWidth: 220,
      fontFamily: 'system-ui, sans-serif',
      fontSize: 12,
      color: active ? CHROME_C.text : CHROME_C.dim
    }
  }, active && curve(false), active && curve(true), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 14,
      height: 14,
      borderRadius: '50%',
      background: '#5f6368',
      flexShrink: 0
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, title));
}
function ChromeTabBar({
  tabs = [{
    title: 'New Tab'
  }],
  activeIndex = 0
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      height: 44,
      background: CHROME_C.barBg,
      paddingRight: 8
    }
  }, /*#__PURE__*/React.createElement(ChromeTrafficLights, null), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-end',
      height: '100%',
      paddingLeft: 4,
      flex: 1
    }
  }, tabs.map((t, i) => /*#__PURE__*/React.createElement(ChromeTab, {
    key: i,
    title: t.title,
    active: i === activeIndex
  }))));
}
function ChromeToolbar({
  url = 'example.com'
}) {
  const iconDot = /*#__PURE__*/React.createElement("div", {
    style: {
      width: 28,
      height: 28,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 16,
      height: 16,
      borderRadius: '50%',
      background: CHROME_C.dim,
      opacity: 0.4
    }
  }));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: 40,
      background: CHROME_C.tabBg,
      display: 'flex',
      alignItems: 'center',
      gap: 4,
      padding: '0 8px'
    }
  }, iconDot, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 30,
      borderRadius: 15,
      background: CHROME_C.urlBg,
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      padding: '0 14px',
      margin: '0 6px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 12,
      height: 12,
      borderRadius: '50%',
      background: CHROME_C.dim,
      opacity: 0.4
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      color: CHROME_C.text,
      fontSize: 13,
      fontFamily: 'system-ui, sans-serif'
    }
  }, url)), iconDot);
}
function ChromeWindow({
  tabs = [{
    title: 'New Tab'
  }],
  activeIndex = 0,
  url = 'example.com',
  width = 900,
  height = 600,
  children
}) {
  return (
    /*#__PURE__*/
    // data-om-starter: inert presence marker — Claude Design's starter-usage
    // probe reads it; it renders nothing. Keep it on this root element.
    React.createElement("div", {
      "data-om-starter": "browser-window",
      style: {
        width,
        height,
        borderRadius: 10,
        overflow: 'hidden',
        boxShadow: '0 24px 80px rgba(0,0,0,0.35), 0 0 0 1px rgba(0,0,0,0.1)',
        display: 'flex',
        flexDirection: 'column',
        background: CHROME_C.tabBg
      }
    }, /*#__PURE__*/React.createElement(ChromeTabBar, {
      tabs: tabs,
      activeIndex: activeIndex
    }), /*#__PURE__*/React.createElement(ChromeToolbar, {
      url: url
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        background: '#fff',
        overflow: 'auto'
      }
    }, children))
  );
}
Object.assign(window, {
  ChromeWindow,
  ChromeTabBar,
  ChromeToolbar,
  ChromeTab,
  ChromeTrafficLights
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "guidelines/frames/browser-window.jsx", error: String((e && e.message) || e) }); }

// guidelines/frames/ios-frame.jsx
try { (() => {
// @ds-adherence-ignore -- omelette starter scaffold (raw elements/hex/px by design)
// Copied omelette starter. Re-running copy_starter_component with this kind overwrites this file with the latest version (page content is unaffected).

/* BEGIN USAGE */
// iOS.jsx — Simplified iOS 26 (Liquid Glass) device frame
// Based on the iOS 26 UI Kit + Figma status bar spec. No assets, no deps.
// Exports (to window): IOSDevice, IOSStatusBar, IOSNavBar, IOSGlassPill, IOSList, IOSListRow, IOSKeyboard
//
// Usage — wrap your screen content in <IOSDevice> to get the bezel, status bar
// and home indicator (props: title, dark, keyboard):
//
//   <IOSDevice title="Settings">
//     ...your screen content...
//   </IOSDevice>
//   <IOSDevice dark title="Search" keyboard>…</IOSDevice>
/* END USAGE */

// ─────────────────────────────────────────────────────────────
// Status bar
// ─────────────────────────────────────────────────────────────
function IOSStatusBar({
  dark = false,
  time = '9:41'
}) {
  const c = dark ? '#fff' : '#000';
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 154,
      alignItems: 'center',
      justifyContent: 'center',
      padding: '21px 24px 19px',
      boxSizing: 'border-box',
      position: 'relative',
      zIndex: 20,
      width: '100%'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 22,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      paddingTop: 1.5
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: 590,
      fontSize: 17,
      lineHeight: '22px',
      color: c
    }
  }, time)), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 22,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 7,
      paddingTop: 1,
      paddingRight: 1
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "19",
    height: "12",
    viewBox: "0 0 19 12"
  }, /*#__PURE__*/React.createElement("rect", {
    x: "0",
    y: "7.5",
    width: "3.2",
    height: "4.5",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "4.8",
    y: "5",
    width: "3.2",
    height: "7",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "9.6",
    y: "2.5",
    width: "3.2",
    height: "9.5",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "14.4",
    y: "0",
    width: "3.2",
    height: "12",
    rx: "0.7",
    fill: c
  })), /*#__PURE__*/React.createElement("svg", {
    width: "17",
    height: "12",
    viewBox: "0 0 17 12"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M8.5 3.2C10.8 3.2 12.9 4.1 14.4 5.6L15.5 4.5C13.7 2.7 11.2 1.5 8.5 1.5C5.8 1.5 3.3 2.7 1.5 4.5L2.6 5.6C4.1 4.1 6.2 3.2 8.5 3.2Z",
    fill: c
  }), /*#__PURE__*/React.createElement("path", {
    d: "M8.5 6.8C9.9 6.8 11.1 7.3 12 8.2L13.1 7.1C11.8 5.9 10.2 5.1 8.5 5.1C6.8 5.1 5.2 5.9 3.9 7.1L5 8.2C5.9 7.3 7.1 6.8 8.5 6.8Z",
    fill: c
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "8.5",
    cy: "10.5",
    r: "1.5",
    fill: c
  })), /*#__PURE__*/React.createElement("svg", {
    width: "27",
    height: "13",
    viewBox: "0 0 27 13"
  }, /*#__PURE__*/React.createElement("rect", {
    x: "0.5",
    y: "0.5",
    width: "23",
    height: "12",
    rx: "3.5",
    stroke: c,
    strokeOpacity: "0.35",
    fill: "none"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "2",
    y: "2",
    width: "20",
    height: "9",
    rx: "2",
    fill: c
  }), /*#__PURE__*/React.createElement("path", {
    d: "M25 4.5V8.5C25.8 8.2 26.5 7.2 26.5 6.5C26.5 5.8 25.8 4.8 25 4.5Z",
    fill: c,
    fillOpacity: "0.4"
  }))));
}

// ─────────────────────────────────────────────────────────────
// Liquid glass pill — blur + tint + shine
// ─────────────────────────────────────────────────────────────
function IOSGlassPill({
  children,
  dark = false,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: 44,
      minWidth: 44,
      borderRadius: 9999,
      position: 'relative',
      overflow: 'hidden',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      boxShadow: dark ? '0 2px 6px rgba(0,0,0,0.35), 0 6px 16px rgba(0,0,0,0.2)' : '0 1px 3px rgba(0,0,0,0.07), 0 3px 10px rgba(0,0,0,0.06)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 9999,
      backdropFilter: 'blur(12px) saturate(180%)',
      WebkitBackdropFilter: 'blur(12px) saturate(180%)',
      background: dark ? 'rgba(120,120,128,0.28)' : 'rgba(255,255,255,0.5)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 9999,
      boxShadow: dark ? 'inset 1.5px 1.5px 1px rgba(255,255,255,0.15), inset -1px -1px 1px rgba(255,255,255,0.08)' : 'inset 1.5px 1.5px 1px rgba(255,255,255,0.7), inset -1px -1px 1px rgba(255,255,255,0.4)',
      border: dark ? '0.5px solid rgba(255,255,255,0.15)' : '0.5px solid rgba(0,0,0,0.06)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 1,
      display: 'flex',
      alignItems: 'center',
      padding: '0 4px'
    }
  }, children));
}

// ─────────────────────────────────────────────────────────────
// Navigation bar — glass pills + large title
// ─────────────────────────────────────────────────────────────
function IOSNavBar({
  title = 'Title',
  dark = false,
  trailingIcon = true
}) {
  const muted = dark ? 'rgba(255,255,255,0.6)' : '#404040';
  const text = dark ? '#fff' : '#000';
  const pillIcon = content => /*#__PURE__*/React.createElement(IOSGlassPill, {
    dark: dark
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 36,
      height: 36,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, content));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 10,
      paddingTop: 62,
      paddingBottom: 10,
      position: 'relative',
      zIndex: 5
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 16px'
    }
  }, pillIcon(/*#__PURE__*/React.createElement("svg", {
    width: "12",
    height: "20",
    viewBox: "0 0 12 20",
    fill: "none",
    style: {
      marginLeft: -1
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M10 2L2 10l8 8",
    stroke: muted,
    strokeWidth: "2.5",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }))), trailingIcon && pillIcon(/*#__PURE__*/React.createElement("svg", {
    width: "22",
    height: "6",
    viewBox: "0 0 22 6"
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "3",
    cy: "3",
    r: "2.5",
    fill: muted
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "11",
    cy: "3",
    r: "2.5",
    fill: muted
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "19",
    cy: "3",
    r: "2.5",
    fill: muted
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '0 16px',
      fontFamily: '-apple-system, system-ui',
      fontSize: 34,
      fontWeight: 700,
      lineHeight: '41px',
      color: text,
      letterSpacing: 0.4
    }
  }, title));
}

// ─────────────────────────────────────────────────────────────
// Grouped list (inset card, r:26) + row (52px)
// ─────────────────────────────────────────────────────────────
function IOSListRow({
  title,
  detail,
  icon,
  chevron = true,
  isLast = false,
  dark = false
}) {
  const text = dark ? '#fff' : '#000';
  const sec = dark ? 'rgba(235,235,245,0.6)' : 'rgba(60,60,67,0.6)';
  const ter = dark ? 'rgba(235,235,245,0.3)' : 'rgba(60,60,67,0.3)';
  const sep = dark ? 'rgba(84,84,88,0.65)' : 'rgba(60,60,67,0.12)';
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      minHeight: 52,
      padding: '0 16px',
      position: 'relative',
      fontFamily: '-apple-system, system-ui',
      fontSize: 17,
      letterSpacing: -0.43
    }
  }, icon && /*#__PURE__*/React.createElement("div", {
    style: {
      width: 30,
      height: 30,
      borderRadius: 7,
      background: icon,
      marginRight: 12,
      flexShrink: 0
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      color: text
    }
  }, title), detail && /*#__PURE__*/React.createElement("span", {
    style: {
      color: sec,
      marginRight: 6
    }
  }, detail), chevron && /*#__PURE__*/React.createElement("svg", {
    width: "8",
    height: "14",
    viewBox: "0 0 8 14",
    style: {
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M1 1l6 6-6 6",
    stroke: ter,
    strokeWidth: "2",
    fill: "none",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  })), !isLast && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 0,
      right: 0,
      left: icon ? 58 : 16,
      height: 0.5,
      background: sep
    }
  }));
}
function IOSList({
  header,
  children,
  dark = false
}) {
  const hc = dark ? 'rgba(235,235,245,0.6)' : 'rgba(60,60,67,0.6)';
  const bg = dark ? '#1C1C1E' : '#fff';
  return /*#__PURE__*/React.createElement("div", null, header && /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: '-apple-system, system-ui',
      fontSize: 13,
      color: hc,
      textTransform: 'uppercase',
      padding: '8px 36px 6px',
      letterSpacing: -0.08
    }
  }, header), /*#__PURE__*/React.createElement("div", {
    style: {
      background: bg,
      borderRadius: 26,
      margin: '0 16px',
      overflow: 'hidden'
    }
  }, children));
}

// ─────────────────────────────────────────────────────────────
// Device frame
// ─────────────────────────────────────────────────────────────
function IOSDevice({
  children,
  width = 402,
  height = 874,
  dark = false,
  title,
  keyboard = false
}) {
  return (
    /*#__PURE__*/
    // data-om-starter: inert presence marker — Claude Design's starter-usage
    // probe reads it; it renders nothing. Keep it on this root element.
    React.createElement("div", {
      "data-om-starter": "ios-frame",
      style: {
        width,
        height,
        borderRadius: 48,
        overflow: 'hidden',
        position: 'relative',
        background: dark ? '#000' : '#F2F2F7',
        boxShadow: '0 40px 80px rgba(0,0,0,0.18), 0 0 0 1px rgba(0,0,0,0.12)',
        fontFamily: '-apple-system, system-ui, sans-serif',
        WebkitFontSmoothing: 'antialiased'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        top: 11,
        left: '50%',
        transform: 'translateX(-50%)',
        width: 126,
        height: 37,
        borderRadius: 24,
        background: '#000',
        zIndex: 50
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        zIndex: 10
      }
    }, /*#__PURE__*/React.createElement(IOSStatusBar, {
      dark: dark
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        height: '100%',
        display: 'flex',
        flexDirection: 'column'
      }
    }, title !== undefined && /*#__PURE__*/React.createElement(IOSNavBar, {
      title: title,
      dark: dark
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        overflow: 'auto'
      }
    }, children), keyboard && /*#__PURE__*/React.createElement(IOSKeyboard, {
      dark: dark
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        zIndex: 60,
        height: 34,
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'flex-end',
        paddingBottom: 8,
        pointerEvents: 'none'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: 139,
        height: 5,
        borderRadius: 100,
        background: dark ? 'rgba(255,255,255,0.7)' : 'rgba(0,0,0,0.25)'
      }
    })))
  );
}

// ─────────────────────────────────────────────────────────────
// Keyboard — iOS 26 liquid glass
// ─────────────────────────────────────────────────────────────
function IOSKeyboard({
  dark = false
}) {
  const glyph = dark ? 'rgba(255,255,255,0.7)' : '#595959';
  const sugg = dark ? 'rgba(255,255,255,0.6)' : '#333';
  const keyBg = dark ? 'rgba(255,255,255,0.22)' : 'rgba(255,255,255,0.85)';

  // special-key icons
  const icons = {
    shift: /*#__PURE__*/React.createElement("svg", {
      width: "19",
      height: "17",
      viewBox: "0 0 19 17"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M9.5 1L1 9.5h4.5V16h8V9.5H18L9.5 1z",
      fill: glyph
    })),
    del: /*#__PURE__*/React.createElement("svg", {
      width: "23",
      height: "17",
      viewBox: "0 0 23 17"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M7 1h13a2 2 0 012 2v11a2 2 0 01-2 2H7l-6-7.5L7 1z",
      fill: "none",
      stroke: glyph,
      strokeWidth: "1.6",
      strokeLinejoin: "round"
    }), /*#__PURE__*/React.createElement("path", {
      d: "M10 5l7 7M17 5l-7 7",
      stroke: glyph,
      strokeWidth: "1.6",
      strokeLinecap: "round"
    })),
    ret: /*#__PURE__*/React.createElement("svg", {
      width: "20",
      height: "14",
      viewBox: "0 0 20 14"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M18 1v6H4m0 0l4-4M4 7l4 4",
      fill: "none",
      stroke: "#fff",
      strokeWidth: "1.8",
      strokeLinecap: "round",
      strokeLinejoin: "round"
    }))
  };
  const key = (content, {
    w,
    flex,
    ret,
    fs = 25,
    k
  } = {}) => /*#__PURE__*/React.createElement("div", {
    key: k,
    style: {
      height: 42,
      borderRadius: 8.5,
      flex: flex ? 1 : undefined,
      width: w,
      minWidth: 0,
      background: ret ? '#08f' : keyBg,
      boxShadow: '0 1px 0 rgba(0,0,0,0.075)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: '-apple-system, "SF Compact", system-ui',
      fontSize: fs,
      fontWeight: 458,
      color: ret ? '#fff' : glyph
    }
  }, content);
  const row = (keys, pad = 0) => /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6.5,
      justifyContent: 'center',
      padding: `0 ${pad}px`
    }
  }, keys.map(l => key(l, {
    flex: true,
    k: l
  })));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 15,
      borderRadius: 27,
      overflow: 'hidden',
      padding: '11px 0 2px',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      boxShadow: dark ? '0 -2px 20px rgba(0,0,0,0.09)' : '0 -1px 6px rgba(0,0,0,0.018), 0 -3px 20px rgba(0,0,0,0.012)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 27,
      backdropFilter: 'blur(12px) saturate(180%)',
      WebkitBackdropFilter: 'blur(12px) saturate(180%)',
      background: dark ? 'rgba(120,120,128,0.14)' : 'rgba(255,255,255,0.25)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 27,
      boxShadow: dark ? 'inset 1.5px 1.5px 1px rgba(255,255,255,0.15)' : 'inset 1.5px 1.5px 1px rgba(255,255,255,0.7), inset -1px -1px 1px rgba(255,255,255,0.4)',
      border: dark ? '0.5px solid rgba(255,255,255,0.15)' : '0.5px solid rgba(0,0,0,0.06)',
      pointerEvents: 'none'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 20,
      alignItems: 'center',
      padding: '8px 22px 13px',
      width: '100%',
      boxSizing: 'border-box',
      position: 'relative'
    }
  }, ['"The"', 'the', 'to'].map((w, i) => /*#__PURE__*/React.createElement(React.Fragment, {
    key: i
  }, i > 0 && /*#__PURE__*/React.createElement("div", {
    style: {
      width: 1,
      height: 25,
      background: '#ccc',
      opacity: 0.3
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      textAlign: 'center',
      fontFamily: '-apple-system, system-ui',
      fontSize: 17,
      color: sugg,
      letterSpacing: -0.43,
      lineHeight: '22px'
    }
  }, w)))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 13,
      padding: '0 6.5px',
      width: '100%',
      boxSizing: 'border-box',
      position: 'relative'
    }
  }, row(['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']), row(['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'], 20), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14.25,
      alignItems: 'center'
    }
  }, key(icons.shift, {
    w: 45,
    k: 'shift'
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6.5,
      flex: 1
    }
  }, ['z', 'x', 'c', 'v', 'b', 'n', 'm'].map(l => key(l, {
    flex: true,
    k: l
  }))), key(icons.del, {
    w: 45,
    k: 'del'
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6,
      alignItems: 'center'
    }
  }, key('ABC', {
    w: 92.25,
    fs: 18,
    k: 'abc'
  }), key('', {
    flex: true,
    k: 'space'
  }), key(icons.ret, {
    w: 92.25,
    ret: true,
    k: 'ret'
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 56,
      width: '100%',
      position: 'relative'
    }
  }));
}
Object.assign(window, {
  IOSDevice,
  IOSStatusBar,
  IOSNavBar,
  IOSGlassPill,
  IOSList,
  IOSListRow,
  IOSKeyboard
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "guidelines/frames/ios-frame.jsx", error: String((e && e.message) || e) }); }

// guidelines/frames/macos-window.jsx
try { (() => {
// @ds-adherence-ignore -- omelette starter scaffold (raw elements/hex/px by design)
// Copied omelette starter. Re-running copy_starter_component with this kind overwrites this file with the latest version (page content is unaffected).

/* BEGIN USAGE */
// MacOS.jsx — Simplified macOS Tahoe (Liquid Glass) window
// Based on the macOS Tahoe UI Kit. No image assets, no dependencies.
// Exports (to window): MacWindow, MacSidebar, MacSidebarItem, MacSidebarHeader, MacToolbar, MacGlass, MacTrafficLights
//
// Usage — wrap your app content in <MacWindow> to get the window chrome
// (traffic lights + titlebar). Props: width, height, title, sidebar (pass a
// <MacSidebar> element); compose MacToolbar/MacGlass inside as needed:
//
//   <MacWindow width={980} height={620} title="Documents"
//              sidebar={<MacSidebar>…</MacSidebar>}>
//     ...your app content...
//   </MacWindow>
/* END USAGE */

const MAC_FONT = '-apple-system, BlinkMacSystemFont, "SF Pro", "Helvetica Neue", sans-serif';

// ─────────────────────────────────────────────────────────────
// Liquid glass primitive — blur + white tint + inset highlight
// ─────────────────────────────────────────────────────────────
function MacGlass({
  children,
  radius = 296,
  dark = false,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      borderRadius: radius,
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: radius,
      background: dark ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.35)',
      backdropFilter: 'blur(40px) saturate(180%)',
      WebkitBackdropFilter: 'blur(40px) saturate(180%)',
      border: dark ? '0.5px solid rgba(255,255,255,0.12)' : '0.5px solid rgba(255,255,255,0.6)',
      boxShadow: dark ? '0 8px 40px rgba(0,0,0,0.2)' : '0 8px 40px rgba(0,0,0,0.08), inset 0 1px 0 rgba(255,255,255,0.4)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 1
    }
  }, children));
}

// ─────────────────────────────────────────────────────────────
// Traffic lights (14px, Tahoe colors)
// ─────────────────────────────────────────────────────────────
function MacTrafficLights({
  style = {}
}) {
  const dot = bg => /*#__PURE__*/React.createElement("div", {
    style: {
      width: 14,
      height: 14,
      borderRadius: '50%',
      background: bg,
      border: '0.5px solid rgba(0,0,0,0.1)'
    }
  });
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 9,
      alignItems: 'center',
      padding: 1,
      ...style
    }
  }, dot('#ff736a'), dot('#febc2e'), dot('#19c332'));
}

// ─────────────────────────────────────────────────────────────
// Toolbar — title + single glass pill icon
// ─────────────────────────────────────────────────────────────
function MacToolbar({
  title = 'Folder'
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      alignItems: 'center',
      padding: 8,
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: MAC_FONT,
      fontSize: 15,
      fontWeight: 700,
      color: 'rgba(0,0,0,0.85)',
      whiteSpace: 'nowrap',
      paddingLeft: 8
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }), /*#__PURE__*/React.createElement(MacGlass, null, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 36,
      height: 36,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 14,
      height: 14,
      borderRadius: '50%',
      background: '#4c4c4c',
      opacity: 0.4
    }
  }))), /*#__PURE__*/React.createElement(MacGlass, null, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 140,
      height: 36,
      display: 'flex',
      alignItems: 'center',
      gap: 6,
      padding: '0 12px'
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "13",
    height: "13",
    viewBox: "0 0 13 13",
    fill: "none"
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "5.5",
    cy: "5.5",
    r: "4",
    stroke: "#727272",
    strokeWidth: "1.5"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M8.5 8.5l3 3",
    stroke: "#727272",
    strokeWidth: "1.5",
    strokeLinecap: "round"
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: MAC_FONT,
      fontSize: 13,
      fontWeight: 500,
      color: '#727272'
    }
  }, "Search"))));
}

// ─────────────────────────────────────────────────────────────
// Sidebar — frosted glass panel floating inside the window
// ─────────────────────────────────────────────────────────────
function MacSidebarItem({
  label,
  selected = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 6,
      height: 24,
      padding: '4px 10px 4px 6px',
      margin: '0 10px',
      borderRadius: 8,
      position: 'relative',
      fontFamily: MAC_FONT,
      fontSize: 11,
      fontWeight: 500
    }
  }, selected && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 8,
      background: 'rgba(0,0,0,0.11)',
      mixBlendMode: 'multiply'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 14,
      height: 14,
      borderRadius: '50%',
      background: selected ? '#007aff' : 'rgba(0,0,0,0.4)',
      opacity: selected ? 1 : 0.5,
      flexShrink: 0,
      position: 'relative'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'rgba(0,0,0,0.85)',
      position: 'relative'
    }
  }, label));
}
function MacSidebar({
  children
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: 220,
      height: '100%',
      padding: 8,
      flexShrink: 0,
      position: 'relative',
      display: 'flex',
      flexDirection: 'column'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 8,
      borderRadius: 18,
      background: 'rgba(210,225,245,0.45)',
      backdropFilter: 'blur(50px) saturate(200%)',
      WebkitBackdropFilter: 'blur(50px) saturate(200%)',
      border: '0.5px solid rgba(255,255,255,0.5)',
      boxShadow: '0 8px 40px rgba(0,0,0,0.10), inset 0 1px 0 rgba(255,255,255,0.35)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 1,
      padding: '10px 0',
      display: 'flex',
      flexDirection: 'column',
      gap: 2
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: 32,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 10px',
      marginBottom: 4
    }
  }, /*#__PURE__*/React.createElement(MacTrafficLights, null)), children));
}
function MacSidebarHeader({
  title
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '14px 18px 5px',
      fontFamily: MAC_FONT,
      fontSize: 11,
      fontWeight: 700,
      color: 'rgba(0,0,0,0.5)'
    }
  }, title);
}

// ─────────────────────────────────────────────────────────────
// Window — r:26, big shadow, sidebar + toolbar + content
// ─────────────────────────────────────────────────────────────
function MacWindow({
  width = 900,
  height = 600,
  title = 'Folder',
  sidebar,
  children
}) {
  return (
    /*#__PURE__*/
    // data-om-starter: inert presence marker — Claude Design's starter-usage
    // probe reads it; it renders nothing. Keep it on this root element.
    React.createElement("div", {
      "data-om-starter": "macos-window",
      style: {
        width,
        height,
        borderRadius: 26,
        overflow: 'hidden',
        background: '#fff',
        boxShadow: '0 0 0 1px rgba(0,0,0,0.23), 0 16px 48px rgba(0,0,0,0.35)',
        display: 'flex',
        position: 'relative',
        fontFamily: MAC_FONT
      }
    }, /*#__PURE__*/React.createElement(MacSidebar, null, sidebar), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        display: 'flex',
        flexDirection: 'column'
      }
    }, /*#__PURE__*/React.createElement(MacToolbar, {
      title: title
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        overflow: 'auto',
        padding: '4px 8px'
      }
    }, children)))
  );
}
Object.assign(window, {
  MacWindow,
  MacSidebar,
  MacSidebarItem,
  MacSidebarHeader,
  MacToolbar,
  MacGlass,
  MacTrafficLights
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "guidelines/frames/macos-window.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Wordmark = __ds_scope.Wordmark;

__ds_ns.ComparisonTable = __ds_scope.ComparisonTable;

__ds_ns.LegalSection = __ds_scope.LegalSection;

__ds_ns.StepItem = __ds_scope.StepItem;

__ds_ns.ValueCard = __ds_scope.ValueCard;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.Eyebrow = __ds_scope.Eyebrow;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.StatusLabel = __ds_scope.StatusLabel;

__ds_ns.TextLink = __ds_scope.TextLink;

__ds_ns.PageHero = __ds_scope.PageHero;

__ds_ns.SiteFooter = __ds_scope.SiteFooter;

__ds_ns.SiteHeader = __ds_scope.SiteHeader;

__ds_ns.AdSlot = __ds_scope.AdSlot;

__ds_ns.DetailsDisclosure = __ds_scope.DetailsDisclosure;

__ds_ns.MetricRing = __ds_scope.MetricRing;

__ds_ns.PhaseDots = __ds_scope.PhaseDots;

__ds_ns.StatDisplay = __ds_scope.StatDisplay;

})();
