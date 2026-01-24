/**
 * Authentication Service - Manages auth state and operations
 * Wraps API service with business logic
 */

import { apiService, AuthResponse, User } from './api.service';

export interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  token: string | null;
}

class AuthService {
  private listeners: ((state: AuthState) => void)[] = [];
  private state: AuthState = {
    user: null,
    isAuthenticated: false,
    isLoading: false,
    error: null,
    token: null,
  };

  constructor() {
    // Initialize state from stored data
    this.initializeFromStorage();
    // Verify token is still valid
    this.verifyToken();
  }

  // ==================== Public Methods ====================

  async signup(email: string, password: string, username: string): Promise<boolean> {
    try {
      this.setState({ isLoading: true, error: null });
      const response = await apiService.signup(email, password, username);

      this.setState({
        user: response.user,
        isAuthenticated: true,
        token: response.access_token,
        isLoading: false,
        error: null,
      });

      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Signup failed';
      this.setState({
        isLoading: false,
        error: message,
      });
      return false;
    }
  }

  async signin(email: string, password: string): Promise<boolean> {
    try {
      this.setState({ isLoading: true, error: null });
      const response = await apiService.signin(email, password);

      this.setState({
        user: response.user,
        isAuthenticated: true,
        token: response.access_token,
        isLoading: false,
        error: null,
      });

      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Signin failed';
      this.setState({
        isLoading: false,
        error: message,
      });
      return false;
    }
  }

  async signout(): Promise<void> {
    try {
      await apiService.signout();
    } finally {
      this.setState({
        user: null,
        isAuthenticated: false,
        token: null,
        error: null,
      });
    }
  }

  async loadCurrentUser(): Promise<boolean> {
    try {
      this.setState({ isLoading: true });
      const response = await apiService.getCurrentUser();

      this.setState({
        user: response.user,
        isAuthenticated: true,
        isLoading: false,
      });

      return true;
    } catch (error) {
      this.setState({
        isLoading: false,
        error: error instanceof Error ? error.message : 'Failed to load user',
      });
      return false;
    }
  }

  async updateProfile(updates: Record<string, any>): Promise<any> {
    const user = this.state.user;
    if (!user) throw new Error('Not authenticated');
    
    return await apiService.updateUserProfile(user.id, updates);
  }

  // ==================== State Management ====================

  getState(): AuthState {
    return { ...this.state };
  }

  subscribe(listener: (state: AuthState) => void): () => void {
    this.listeners.push(listener);

    // Return unsubscribe function
    return () => {
      this.listeners = this.listeners.filter((l) => l !== listener);
    };
  }

  private setState(updates: Partial<AuthState>): void {
    this.state = { ...this.state, ...updates };
    this.listeners.forEach((listener) => listener(this.getState()));
  }

  // ==================== Private Methods ====================

  private initializeFromStorage(): void {
    try {
      const stored = localStorage.getItem('pearl_auth_state');
      if (stored) {
        const parsed = JSON.parse(stored);
        this.state = { ...this.state, ...parsed };
      }
    } catch (error) {
      console.warn('Failed to load auth state from storage', error);
    }
  }

  private async verifyToken(): Promise<void> {
    if (!apiService.isAuthenticated()) {
      return;
    }

    try {
      const response = await apiService.getCurrentUser();
      this.setState({
        user: response.user,
        isAuthenticated: true,
      });
    } catch (error) {
      // Token is invalid or expired
      this.setState({
        user: null,
        isAuthenticated: false,
        token: null,
        error: 'Session expired. Please sign in again.',
      });
    }
  }
}

// Export singleton instance
export const authService = new AuthService();
export default authService;
