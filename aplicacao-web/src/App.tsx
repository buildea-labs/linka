import { useState, useEffect } from 'react';
import { SiteHeader } from './ui/components/layout/SiteHeader';
import { SiteFooter } from './ui/components/layout/SiteFooter';
import { SpeedTestScreen } from './screens/SpeedTestScreen';
import { AppsScreen } from './screens/AppsScreen';
import { MethodologyScreen } from './screens/MethodologyScreen';
import { PrivacyScreen } from './screens/PrivacyScreen';
import { AboutScreen } from './screens/AboutScreen';

export default function App() {
  const [currentPath, setCurrentPath] = useState(window.location.pathname);

  useEffect(() => {
    const handlePopState = () => setCurrentPath(window.location.pathname);
    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, []);

  const navigate = (href: string) => {
    if (href !== window.location.pathname) {
      window.history.pushState({}, '', href);
      setCurrentPath(href);
    }
  };

  const navItems = [
    { label: 'Resultado', href: '/' },
    { label: 'Sobre Nós', href: '/sobre' },
    { label: 'Como medimos', href: '/metodologia' },
    { label: 'Privacidade & Termos de Uso', href: '/privacidade' },
    { label: 'Aplicativos', href: '/apps' }
  ];

  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      flexDirection: 'column', 
      fontFamily: 'var(--font-body)', 
      color: 'var(--text-primary)',
      background: 'var(--surface-page)'
    }}>
      {/* @ts-ignore */}
      <SiteHeader items={navItems} activeHref={currentPath} homeHref="/" onNavigate={navigate} style={{}} />
      
      <main style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
        <div style={{ display: currentPath === '/' ? 'flex' : 'none', flex: 1, flexDirection: 'column' }}>
          <SpeedTestScreen />
        </div>
        {currentPath === '/apps' && <AppsScreen />}
        {currentPath === '/metodologia' && <MethodologyScreen />}
        {currentPath === '/privacidade' && <PrivacyScreen />}
        {currentPath === '/sobre' && <AboutScreen />}
      </main>

      <SiteFooter style={{}} />
    </div>
  );
}
