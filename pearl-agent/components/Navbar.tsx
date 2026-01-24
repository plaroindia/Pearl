import React from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import UserMenu from '../src/components/auth/UserMenu';

/**
 * Navbar Component
 * Main navigation bar with links and user menu
 * Appears on all protected pages
 */
const Navbar: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const navItems = [
    { id: 'dashboard', label: 'Dashboard', path: '/dashboard', icon: '🏠' },
    { id: 'roadmap', label: 'Roadmap', path: '/roadmap', icon: '🗺️' },
    { id: 'progress', label: 'Progress', path: '/progress', icon: '📊' },
    { id: 'jobs', label: 'Jobs', path: '/jobs', icon: '💼' },
    { id: 'profile', label: 'Profile', path: '/profile', icon: '👤' },
  ];

  const isActive = (path: string) => location.pathname === path;

  return (
    <nav className="fixed top-0 left-0 right-0 z-40 border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 transition-all shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        {/* Logo */}
        <Link to="/" className="flex items-center gap-2 cursor-pointer hover:opacity-80 transition-opacity">
          <div className="w-8 h-8 bg-gradient-to-br from-blue-600 to-blue-700 rounded-lg flex items-center justify-center text-white font-bold italic text-lg">
            P
          </div>
          <span className="text-xl font-extrabold text-slate-900 dark:text-white">PEARL</span>
        </Link>

        {/* Desktop Navigation */}
        <div className="hidden md:flex items-center gap-1">
          {navItems.map((item) => (
            <Link
              key={item.id}
              to={item.path}
              className={`flex items-center gap-2 px-3 py-2 rounded-md font-medium transition-all ${
                isActive(item.path)
                  ? 'text-blue-600 bg-blue-50 dark:bg-blue-900/20'
                  : 'text-slate-600 hover:text-blue-600 dark:text-slate-400 dark:hover:text-blue-400'
              }`}
            >
              <span>{item.icon}</span>
              <span>{item.label}</span>
            </Link>
          ))}
        </div>

        {/* Right Actions */}
        <div className="flex items-center gap-4">
          {/* Theme Toggle */}
          <button
            onClick={() => {
              const html = document.documentElement;
              const isDark = html.classList.contains('dark');
              if (isDark) {
                html.classList.remove('dark');
                localStorage.setItem('theme', 'light');
              } else {
                html.classList.add('dark');
                localStorage.setItem('theme', 'dark');
              }
            }}
            className="p-2 rounded-full hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
            title="Toggle dark mode"
          >
            <span className="text-xl">
              {document.documentElement.classList.contains('dark') ? '☀️' : '🌙'}
            </span>
          </button>

          {/* User Menu */}
          <UserMenu onLogout={() => navigate('/signin')} />
        </div>

        {/* Mobile Menu Button */}
        <button className="md:hidden p-2 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors">
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </button>
      </div>
    </nav>
  );
};

export default Navbar;
