import { LandingScreen } from './screens/LandingScreen';
import { InfoScreen } from './screens/InfoScreen';
import { NotFoundScreen } from './screens/NotFoundScreen';

const infoRoutes = new Set(['/sobre', '/como-medimos', '/privacidade', '/termos', '/suporte']);

export default function App() {
  const pathname = window.location.pathname.replace(/\/$/, '') || '/';

  if (pathname === '/') {
    return <LandingScreen />;
  }

  if (infoRoutes.has(pathname)) {
    return <InfoScreen pathname={pathname} />;
  }

  return <NotFoundScreen />;
}
