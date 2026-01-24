import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { authService } from '../../services/auth.service';
import './auth.css';

const Signup: React.FC = () => {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [acceptTerms, setAcceptTerms] = useState(false);
  const [errors, setErrors] = useState<{
    email?: string;
    username?: string;
    password?: string;
    confirmPassword?: string;
    terms?: string;
    general?: string;
  }>({});
  const [isLoading, setIsLoading] = useState(false);
  const [isDarkMode, setIsDarkMode] = useState(() => {
    return localStorage.getItem('theme') === 'dark';
  });

  const validateEmail = (email: string): boolean => {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
  };

  const validateUsername = (username: string): boolean => {
    return username.length >= 3 && username.length <= 30 && /^[a-zA-Z0-9_-]+$/.test(username);
  };

  const validateForm = (): boolean => {
    const newErrors: typeof errors = {};

    if (!email) {
      newErrors.email = 'Please enter your email address';
    } else if (!validateEmail(email)) {
      newErrors.email = 'Please enter a valid email address';
    }

    if (!username) {
      newErrors.username = 'Please enter a username';
    } else if (!validateUsername(username)) {
      newErrors.username = 'Username must be 3-30 characters (letters, numbers, - and _)';
    }

    if (!password) {
      newErrors.password = 'Please enter a password';
    } else if (password.length < 8) {
      newErrors.password = 'Password must be at least 8 characters';
    } else if (!/[A-Z]/.test(password) || !/[0-9]/.test(password)) {
      newErrors.password = 'Password must contain uppercase letter and number';
    }

    if (!confirmPassword) {
      newErrors.confirmPassword = 'Please confirm your password';
    } else if (password !== confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }

    if (!acceptTerms) {
      newErrors.terms = 'Please accept the terms and conditions';
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
      const success = await authService.signup(email, password, username);
      if (success) {
        navigate('/dashboard');
      } else {
        setErrors({ general: 'Sign up failed. Please try again.' });
      }
    } catch (error: any) {
      setErrors({ general: error.message || 'Sign up failed. Please try again.' });
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
          <h1>Welcome to PEARL</h1>
          <p>Join thousands of users who trust PEARL for their daily needs. Get access to exclusive features and a seamless experience.</p>

          <div className="features">
            <div className="feature">
              <span className="icon">🔒</span>
              <span>Secure & encrypted data protection</span>
            </div>
            <div className="feature">
              <span className="icon">🔄</span>
              <span>Sync across all your devices</span>
            </div>
            <div className="feature">
              <span className="icon">⭐</span>
              <span>Premium features included</span>
            </div>
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
        <h2>Create Account</h2>
        <p className="subtitle">Join our community today</p>

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
            <label htmlFor="username">Username</label>
            <input
              type="text"
              id="username"
              value={username}
              onChange={(e) => {
                setUsername(e.target.value);
                if (errors.username) setErrors({ ...errors, username: '' });
              }}
              placeholder="Choose a unique username"
              disabled={isLoading}
            />
            {errors.username && <div className="error">{errors.username}</div>}
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
                placeholder="Create a strong password"
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

          <div className="field">
            <label htmlFor="confirmPassword">Confirm Password</label>
            <div className="password-input-wrapper">
              <input
                type={showConfirmPassword ? 'text' : 'password'}
                id="confirmPassword"
                value={confirmPassword}
                onChange={(e) => {
                  setConfirmPassword(e.target.value);
                  if (errors.confirmPassword) setErrors({ ...errors, confirmPassword: '' });
                }}
                placeholder="Re-enter your password"
                disabled={isLoading}
              />
              <button
                type="button"
                className="password-toggle"
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
              >
                {showConfirmPassword ? '👁️' : '👁️‍🗨️'}
              </button>
            </div>
            {errors.confirmPassword && <div className="error">{errors.confirmPassword}</div>}
          </div>

          <div className="terms">
            <input
              type="checkbox"
              id="terms"
              checked={acceptTerms}
              onChange={(e) => {
                setAcceptTerms(e.target.checked);
                if (errors.terms) setErrors({ ...errors, terms: '' });
              }}
              disabled={isLoading}
            />
            <span>
              I agree to the{' '}
              <a href="/terms" target="_blank" rel="noopener noreferrer">
                Terms & Conditions
              </a>{' '}
              and{' '}
              <a href="/privacy" target="_blank" rel="noopener noreferrer">
                Privacy Policy
              </a>
            </span>
          </div>
          {errors.terms && <div className="error">{errors.terms}</div>}

          <button type="submit" className="btn btn-primary" disabled={isLoading}>
            {isLoading ? 'Creating Account...' : 'Create Account'}
          </button>
        </form>

        <div className="footer">
          Already have an account?{' '}
          <Link to="/signin" className="signin-link">
            Sign In
          </Link>
        </div>
      </div>
    </div>
  );
};

export default Signup;
