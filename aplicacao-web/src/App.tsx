import { LandingScreen } from './screens/LandingScreen';
import { InfoScreen } from './screens/InfoScreen';

const infoRoutes = new Set(['/sobre', '/como-medimos', '/privacidade', '/termos', '/suporte']);

export default function App() {
  const pathname = window.location.pathname.replace(/\/$/, '') || '/';
  if (infoRoutes.has(pathname)) {
    return <InfoScreen pathname={pathname} />;
  }

  return (
    <LandingScreen />
  );
}
