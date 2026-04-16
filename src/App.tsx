import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Sidebar } from './components/Layout/Sidebar';
import { BottomNav } from './components/Layout/BottomNav';
import { DashboardPage } from './pages/Dashboard';
import { DevicesPage } from './pages/Devices';
import { SecurityPage } from './pages/Security';
import { AutomationsPage } from './pages/Automations';
import { SettingsPage } from './pages/Settings';
import { LoginPage } from './pages/Login';
import { useLang } from './contexts/LanguageContext';
import { useAuth } from './hooks/useAuth';
import './App.css';

function App() {
  const { dir, lang } = useLang();
  const { isLoggedIn } = useAuth();

  if (!isLoggedIn) {
    return (
      <div dir={dir} lang={lang}>
        <LoginPage />
      </div>
    );
  }

  return (
    <BrowserRouter>
      <div className="app-layout" dir={dir} lang={lang}>
        <Sidebar />
        <main className="main-content">
          <Routes>
            <Route path="/"            element={<DashboardPage />} />
            <Route path="/devices"     element={<DevicesPage />} />
            <Route path="/security"    element={<SecurityPage />} />
            <Route path="/automations" element={<AutomationsPage />} />
            <Route path="/settings"    element={<SettingsPage />} />
            <Route path="*"            element={<Navigate to="/" replace />} />
          </Routes>
        </main>
        <BottomNav />
      </div>
    </BrowserRouter>
  );
}

export default App;
