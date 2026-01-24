import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { authService } from '../../services/auth.service';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requiredRoles?: string[];
}

/**
 * Protected Route Component
 * Prevents unauthenticated users from accessing protected pages
 * Redirects to login if not authenticated
 */
const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children, requiredRoles }) => {
  const location = useLocation();
  const authState = authService.getState();
  const isAuthenticated = authState.isAuthenticated;

  if (!isAuthenticated) {
    // Redirect to login, but save the location they were trying to access
    return <Navigate to="/signin" state={{ from: location }} replace />;
  }

  // TODO: Add role-based access control if needed
  if (requiredRoles && requiredRoles.length > 0) {
    // Check user roles here if implemented
  }

  return <>{children}</>;
};

export default ProtectedRoute;
