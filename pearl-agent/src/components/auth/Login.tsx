import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { authService } from '../../services/auth.service';
import './auth.css';

const Login: React.FC = () => {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [remember, setRemember] = useState(false);
  const [errors, setErrors] = useState<{ email?: string; password?: string; general?: string }>({});
  const [isLoading, setIsLoading] = useState(false);
  const [isDarkMode, setIsDarkMode] = useState(() => {
    return localStorage.getItem('theme') === 'dark';
  });

  const validateEmail = (email: string): boolean => {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
  };

  const validateForm = (): boolean => {
    const newErrors: typeof errors = {};

    if (!email) {
      newErrors.email = 'Please enter your email address';
    } else if (!validateEmail(email)) {
      newErrors.email = 'Please enter a valid email address';
    }

    if (!password) {
      newErrors.password = 'Please enter your password';
    } else if (password.length < 6) {
      newErrors.password = 'Password must be at least 6 characters';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) return;

    setIsLoading(true);
    setErrors({});

    try {
      const success = await authService.signin(email, password);
      if (success) {
        if (remember) {
          localStorage.setItem('pearl_remember_email', email);
        }
        navigate('/dashboard');
      } else {
        setErrors({ general: 'Invalid email or password' });
      }
    } catch (error: any) {
      setErrors({ general: error.message || 'Sign in failed. Please try again.' });
    } finally {
      setIsLoading(false);
    }
  };

  const toggleTheme = () => {
    const newMode = !isDarkMode;
    setIsDarkMode(newMode);
    if (newMode) {
      document.body.classList.add('dark');
      localStorage.setItem('theme', 'dark');
    } else {
      document.body.classList.remove('dark');
      localStorage.setItem('theme', 'light');
    }
  };

  return (
    <div className="auth-container">
      {/* Hero Section */}
      <div className="hero-section">
        <div className="hero-content">
          <h1>Welcome Back to PEARL</h1>
          <p>Sign in to continue your journey. Access your personalized dashboard, track your progress, and enjoy a seamless experience.</p>

          <div className="features">
            <div className="feature">
              <span className="icon">🔒</span>
              <span>Secure & encrypted login protection</span>
            </div>
            <div className="feature">
              <span className="icon">📱</span>
              <span>Access from any device, anywhere</span>
            </div>
            <div className="feature">
              <span className="icon">⏱️</span>
              <span>Quick access to your history & preferences</span>
            </div>
          </div>

          <div className="testimonial">
            <p className="quote">"PEARL has completely transformed how I manage my daily workflow. The intuitive interface makes everything so simple!"</p>
            <p className="author">— Alex Morgan, Premium Member</p>
          </div>
        </div>
      </div>

      {/* Card Section */}
      <div className="card-section">
        <div className="top-bar">
          <Link to="/" className="back-btn">
            ← Back
          </Link>

          <button className="theme-toggle" onClick={toggleTheme} title="Toggle theme">
            {isDarkMode ? '☀️' : '🌙'}
          </button>
        </div>

        <div className="logo">
          <img src="/assets/plaro_logo.png" alt="PEARL Logo" />
        </div>

        <h1 className="brand-title">PEARL</h1>
        <h2>Sign In</h2>
        <p className="subtitle">Welcome back! Please enter your details</p>

        {errors.general && <div className="alert alert-error">{errors.general}</div>}

        <form onSubmit={handleSubmit}>
          <div className="field">
            <label htmlFor="email">Email Address</label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={(e) => {
                setEmail(e.target.value);
                if (errors.email) setErrors({ ...errors, email: '' });
              }}
              placeholder="Enter your email address"
              disabled={isLoading}
            />
            {errors.email && <div className="error">{errors.email}</div>}
          </div>

          <div className="field">
            <label htmlFor="password">Password</label>
            <div className="password-input-wrapper">
              <input
                type={showPassword ? 'text' : 'password'}
                id="password"
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value);
                  if (errors.password) setErrors({ ...errors, password: '' });
                }}
                placeholder="Enter your password"
                disabled={isLoading}
              />
              <button
                type="button"
                className="password-toggle"
                onClick={() => setShowPassword(!showPassword)}
              >
                {showPassword ? '👁️' : '👁️‍🗨️'}
              </button>
            </div>
            {errors.password && <div className="error">{errors.password}</div>}
          </div>

          <div className="options">
            <label className="remember">
              <input
                type="checkbox"
                checked={remember}
                onChange={(e) => setRemember(e.target.checked)}
                disabled={isLoading}
              />
              <span>Remember me for 30 days</span>
            </label>
            <Link to="/forgot-password" className="forgot-link">
              Forgot password?
            </Link>
          </div>

          <button type="submit" className="btn btn-primary" disabled={isLoading}>
            {isLoading ? 'Signing in...' : 'Sign In'}
          </button>

          <div className="divider">
            <span>or continue with</span>
          </div>

          <div className="social-login">
            <button type="button" className="social-btn google" disabled={isLoading}>
              <span>Google</span>
            </button>
            <button type="button" className="social-btn microsoft" disabled={isLoading}>
              <span>Microsoft</span>
            </button>
          </div>
        </form>

        <div className="footer">
          Don't have an account?{' '}
          <Link to="/signup" className="signup-link">
            Sign Up
          </Link>
        </div>
      </div>
    </div>
  );
};

export default Login;
