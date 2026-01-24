
import React, { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { authService } from './src/services/auth.service';

// Auth Components
import Login from './src/components/auth/Login';
import Signup from './src/components/auth/Signup';
import ProtectedRoute from './src/components/auth/ProtectedRoute';

// Main Components
import Dashboard from './components/Dashboard';
import Onboarding from './components/Onboarding';
import Roadmap from './components/Roadmap';
import Analytics from './components/Analytics';
import Jobs from './components/Jobs';
import Profile from './components/Profile';
import TaikenStory from './components/TaikenStory';
import Navbar from './components/Navbar';

/**
 * App Component
 * Main application entry point with routing
 * Handles authentication, theme management, and page routing
 */
const App: React.FC = () => {
  const [authState, setAuthState] = React.useState(authService.getState());

  useEffect(() => {
    // Initialize theme from localStorage
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'dark') {
      document.documentElement.classList.add('dark');
    }

    // Subscribe to auth state changes
    const unsubscribe = authService.subscribe((state) => {
      setAuthState(state);
    });

    // Only attempt to load current user if we have a token stored
    const token = localStorage.getItem('pearl_auth_state');
    if (token) {
      authService.loadCurrentUser().catch((error) => {
        console.log('[App] No existing session:', error);
      });
    }

    return unsubscribe;
  }, []);

  return (
    <Router>
      <div className="min-h-screen bg-light dark:bg-dark transition-colors duration-300">
        <Routes>
          {/* Public Auth Routes */}
          <Route path="/signin" element={<Login />} />
          <Route path="/login" element={<Navigate to="/signin" replace />} />
          <Route path="/signup" element={<Signup />} />

          {/* Protected Routes */}
          <Route
            path="/"
            element={
              authState.isAuthenticated ? (
                <>
                  <Navbar />
                  <Dashboard />
                </>
              ) : (
                <Navigate to="/signin" replace />
              )
            }
          />

          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <>
                  <Navbar />
                  <Dashboard />
                </>
              </ProtectedRoute>
            }
          />

          <Route
            path="/onboarding"
            element={
              <ProtectedRoute>
                <Onboarding />
              </ProtectedRoute>
            }
          />

          <Route
            path="/roadmap"
            element={
              <ProtectedRoute>
                <>
                  <Navbar />
                  <Roadmap />
                </>
              </ProtectedRoute>
            }
          />

          <Route
            path="/progress"
            element={
              <ProtectedRoute>
                <>
                  <Navbar />
                  <Analytics />
                </>
              </ProtectedRoute>
            }
          />

          <Route
            path="/jobs"
            element={
              <ProtectedRoute>
                <>
                  <Navbar />
                  <Jobs />
                </>
              </ProtectedRoute>
            }
          />

          <Route
            path="/profile"
            element={
              <ProtectedRoute>
                <>
                  <Navbar />
                  <Profile />
                </>
              </ProtectedRoute>
            }
          />

          <Route
            path="/learning/:skillId"
            element={
              <ProtectedRoute>
                <>
                  <Navbar />
                  <TaikenStory />
                </>
              </ProtectedRoute>
            }
          />

          {/* 404 Fallback */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </div>
    </Router>
  );
};

export default App;
