import { useState, useEffect } from 'react';
import { DraggableSheet } from '../../components/DraggableSheet';

interface SettingsSheetProps {
  open: boolean;
  onClose: () => void;
}

export function SettingsSheet({ open, onClose }: SettingsSheetProps) {
  const [theme, setTheme] = useState('dark');

  useEffect(() => {
    const currentTheme = document.documentElement.getAttribute('data-theme') || 'dark';
    setTheme(currentTheme);
  }, [open]);

  const toggleTheme = () => {
    const newTheme = theme === 'dark' ? 'light' : 'dark';
    setTheme(newTheme);
    document.documentElement.setAttribute('data-theme', newTheme);
  };

  return (
    <DraggableSheet open={open} onClose={onClose} initialSnap="compact">
      <div style={{ padding: '24px 24px calc(24px + env(safe-area-inset-bottom))', display: 'flex', flexDirection: 'column', gap: 24, textAlign: 'left', color: 'var(--text-primary)' }}>
        <h2 style={{ fontSize: 20, margin: 0, fontWeight: 600 }}>Ajustes</h2>
        
        <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
          {/* Tema */}
          <div onClick={toggleTheme} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', cursor: 'pointer' }}>
            <span style={{ fontSize: 17 }}>Tema</span>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ color: 'var(--text-secondary)', fontSize: 17 }}>{theme === 'dark' ? 'Escuro' : 'Claro'}</span>
              <svg width="8" height="14" viewBox="0 0 8 14" fill="none">
                <path d="M1 1l6 6-6 6" stroke="var(--text-secondary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
          </div>
          
          <div style={{ height: 1, backgroundColor: 'var(--border-default)' }} />
          
          {/* Idioma */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', cursor: 'pointer' }}>
            <span style={{ fontSize: 17 }}>Idioma</span>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ color: 'var(--text-secondary)', fontSize: 17 }}>Português</span>
              <svg width="8" height="14" viewBox="0 0 8 14" fill="none">
                <path d="M1 1l6 6-6 6" stroke="var(--text-secondary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
          </div>

          <div style={{ height: 1, backgroundColor: 'var(--border-default)' }} />
          
          {/* Link SignallQ */}
          <a href="https://signallq.com" target="_blank" rel="noopener noreferrer" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: 'var(--text-primary)', textDecoration: 'none' }}>
            <span style={{ fontSize: 17 }}>Diagnóstico no SignallQ</span>
            <svg width="8" height="14" viewBox="0 0 8 14" fill="none">
              <path d="M1 1l6 6-6 6" stroke="var(--text-secondary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </a>
        </div>
      </div>
    </DraggableSheet>
  );
}
