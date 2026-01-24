import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { authService } from '../../services/auth.service';
import type { AuthState } from '../../services/auth.service';
import './usermenu.css';

interface UserMenuProps {
  onLogout?: () => void;
}

/**
 * User Menu Component
 * Displays authenticated user info and logout button
 * Shows loading state if user data is being fetched
 */
const UserMenu: React.FC<UserMenuProps> = ({ onLogout }) => {
  const navigate = useNavigate();
  const [authState, setAuthState] = useState<AuthState>(authService.getState());
  const [isOpen, setIsOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    // Subscribe to auth state changes
    const unsubscribe = authService.subscribe((newState) => {
      setAuthState(newState);
    });

    return unsubscribe;
  }, []);

  const handleLogout = async () => {
    setIsLoading(true);
    try {
      await authService.signout();
      setIsOpen(false);
      onLogout?.();
      navigate('/');
    } catch (error) {
      console.error('[UserMenu] Logout failed:', error);
    } finally {
      setIsLoading(false);
    }
  };

  if (!authState.isAuthenticated) {
    return (
      <div className="user-menu-guest">
        <Link to="/signin" className="btn btn-secondary">
          Sign In
        </Link>
        <Link to="/signup" className="btn btn-primary">
          Sign Up
        </Link>
      </div>
    );
  }

  const userName = authState.user?.email?.split('@')[0] || authState.user?.email || 'User';

  return (
    <div className="user-menu-container">
      <button
        className="user-menu-button"
        onClick={() => setIsOpen(!isOpen)}
        aria-expanded={isOpen}
        aria-label="User menu"
      >
        <span className="avatar">
          {authState.user?.email ? authState.user.email.charAt(0).toUpperCase() : 'U'}
        </span>
        <span className="username">{userName}</span>
        <span className={`chevron ${isOpen ? 'open' : ''}`}>▼</span>
      </button>

      {isOpen && (
        <div className="user-menu-dropdown">
          <div className="menu-header">
            <p className="email">{authState.user?.email}</p>
          </div>

          <div className="menu-divider"></div>

          <Link to="/profile" className="menu-item" onClick={() => setIsOpen(false)}>
            <span className="icon">👤</span>
            <span>Profile</span>
          </Link>

          <Link to="/settings" className="menu-item" onClick={() => setIsOpen(false)}>
            <span className="icon">⚙️</span>
            <span>Settings</span>
          </Link>

          <Link to="/help" className="menu-item" onClick={() => setIsOpen(false)}>
            <span className="icon">❓</span>
            <span>Help & Support</span>
          </Link>

          <div className="menu-divider"></div>

          <button
            className="menu-item logout-btn"
            onClick={handleLogout}
            disabled={isLoading}
          >
            <span className="icon">🚪</span>
            <span>{isLoading ? 'Signing out...' : 'Sign Out'}</span>
          </button>
        </div>
      )}

      {isOpen && <div className="menu-overlay" onClick={() => setIsOpen(false)} />}
    </div>
  );
};

export default UserMenu;
