/**
 * API Service - Centralized HTTP client for backend communication
 * Handles all requests to FastAPI backend with proper authentication
 */

/// <reference types="vite/client" />

import axios, { AxiosInstance, AxiosError } from 'axios';

// API Base Configuration
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

// Interfaces
export interface User {
  id: string;
  email: string;
  username: string;
  profile?: Record<string, any>;
}

export interface AuthResponse {
  success: boolean;
  user: User;
  access_token: string;
  refresh_token?: string;
  requires_verification?: boolean;
  requires_onboarding?: boolean;
}

export interface CareerGoalResponse {
  success: boolean;
  session_id: string;
  skills_identified: Array<{ name: string; confidence: number }>;
  learning_paths: Record<string, any>;
  estimated_weeks: number;
  job_market_insight?: string;
}

export interface Module {
  id: string;
  name: string;
  description: string;
  estimated_hours: number;
  difficulty: string;
  status: 'locked' | 'active' | 'completed';
  type: string;
  completion_percentage: number;
}

export interface Job {
  id: string;
  title: string;
  company: string;
  location: string;
  salary_min?: number;
  salary_max?: number;
  description: string;
  url: string;
  posted_date?: string;
}

export interface JobMatch {
  job: Job;
  match_percentage: number;
  matched_skills: string[];
  missing_skills: string[];
  match_reason: string;
}

export interface ContentResource {
  id: string;
  provider: 'youtube' | 'freecodecamp' | 'mit_ocw';
  title: string;
  description?: string;
  url: string;
  difficulty: string;
  duration_minutes: number;
  tags: string[];
  thumbnail_url?: string;
  completion_status: string;
}

export interface CheckpointResult {
  success: boolean;
  score: number;
  passed: boolean;
  correct_answers: number;
  total_questions: number;
  explanation?: string;
  next_action?: string;
  rewards?: Record<string, any>;
}

// API Service Class
class ApiService {
  private client: AxiosInstance;
  private token: string | null = null;
  private refreshToken: string | null = null;

  constructor() {
    this.token = this.getStoredToken();
    this.refreshToken = this.getStoredRefreshToken();

    // Create axios instance with defaults
    this.client = axios.create({
      baseURL: API_BASE_URL,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor - add auth token
    this.client.interceptors.request.use(
      (config) => {
        if (this.token) {
          config.headers['Authorization'] = `Bearer ${this.token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Response interceptor - handle auth errors
    this.client.interceptors.response.use(
      (response) => response,
      async (error: AxiosError) => {
        const original = error.config;

        // Handle 401 Unauthorized
        if (error.response?.status === 401) {
          // Try to refresh token if available
          if (this.refreshToken && original) {
            try {
              const newToken = await this.refreshAccessToken();
              if (newToken) {
                this.token = newToken;
                this.storeToken(newToken);
                original.headers['Authorization'] = `Bearer ${newToken}`;
                return this.client(original);
              }
            } catch (refreshError) {
              // Refresh failed, redirect to login
              this.clearAuth();
              window.location.href = '/login';
            }
          } else {
            // No refresh token, redirect to login
            this.clearAuth();
            window.location.href = '/login';
          }
        }

        return Promise.reject(error);
      }
    );
  }

  // ==================== Authentication ====================

  async signup(email: string, password: string, username: string): Promise<AuthResponse> {
    try {
      const response = await this.client.post<AuthResponse>('/auth/signup', {
        email,
        password,
        username,
      });
      
      if (response.data.access_token) {
        this.setAuth(response.data.access_token, response.data.refresh_token);
      }
      
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Signup failed');
    }
  }

  async signin(email: string, password: string): Promise<AuthResponse> {
    try {
      const response = await this.client.post<AuthResponse>('/auth/signin', {
        email,
        password,
      });
      
      if (response.data.access_token) {
        this.setAuth(response.data.access_token, response.data.refresh_token);
      }
      
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Signin failed');
    }
  }

  async signout(): Promise<void> {
    try {
      await this.client.post('/auth/signout');
    } finally {
      this.clearAuth();
    }
  }

  async getCurrentUser(): Promise<{ success: boolean; user: User }> {
    try {
      const response = await this.client.get('/auth/me');
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to get current user');
    }
  }

  async getUserProfile(userId: string): Promise<any> {
    try {
      const response = await this.client.get(`/auth/profile/${userId}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to get user profile');
    }
  }

  async updateUserProfile(userId: string, updates: Record<string, any>): Promise<any> {
    try {
      const response = await this.client.post(`/auth/profile/${userId}`, { updates });
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to update profile');
    }
  }

  private async refreshAccessToken(): Promise<string | null> {
    if (!this.refreshToken) return null;

    try {
      const response = await axios.post(`${API_BASE_URL}/auth/refresh`, {
        refresh_token: this.refreshToken,
      });
      return response.data.access_token;
    } catch {
      return null;
    }
  }

  // ==================== Learning Paths ====================

  async parseCareerGoal(goal: string, jdText?: string): Promise<CareerGoalResponse> {
    try {
      const response = await this.client.post<CareerGoalResponse>('/agent/parse-jd', {
        goal,
        jd_text: jdText,
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to parse career goal');
    }
  }

  async getModules(skill: string, difficulty?: string): Promise<Module[]> {
    try {
      const response = await this.client.get(`/agent/modules/${skill}`, {
        params: { difficulty },
      });
      return response.data.modules || [];
    } catch (error) {
      throw this.handleError(error, 'Failed to get modules');
    }
  }

  async getSession(sessionId: string): Promise<any> {
    try {
      const response = await this.client.get(`/agent/session/${sessionId}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to get session');
    }
  }

  async submitModuleAction(
    sessionId: string,
    skill: string,
    moduleId: number,
    actionIndex: number,
    completionData: Record<string, any>
  ): Promise<any> {
    try {
      const response = await this.client.post('/agent/module-action', {
        session_id: sessionId,
        skill,
        module_id: moduleId,
        action_index: actionIndex,
        completion_data: completionData,
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to submit module action');
    }
  }

  // ==================== Checkpoints ====================

  async submitCheckpoint(
    sessionId: string,
    skill: string,
    moduleId: number,
    answers: number[]
  ): Promise<CheckpointResult> {
    try {
      const response = await this.client.post<CheckpointResult>('/agent/checkpoint', {
        session_id: sessionId,
        skill,
        module_id: moduleId,
        answers,
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to submit checkpoint');
    }
  }

  // ==================== Learning Optimization ====================

  async optimizeLearningPath(
    userSkills: Record<string, number>,
    requiredSkills: string[],
    weeks: number
  ): Promise<any> {
    try {
      const response = await this.client.post('/agent/optimize-path', {
        user_skills: userSkills,
        required_skills: requiredSkills,
        time_constraint_weeks: weeks,
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to optimize learning path');
    }
  }

  // ==================== Job Recommendations ====================

  async getJobRecommendations(skills: string[], location?: string): Promise<JobMatch[]> {
    try {
      const response = await this.client.get('/agent/jobs/recommendations', {
        params: {
          skills: skills.join(','),
          location: location || 'Chennai',
        },
      });
      return response.data.matched_jobs || [];
    } catch (error) {
      throw this.handleError(error, 'Failed to get job recommendations');
    }
  }

  // ==================== Content Resources ====================

  async getContentForSkill(
    skill: string,
    difficulty?: string,
    contentType?: string
  ): Promise<ContentResource[]> {
    try {
      const response = await this.client.get(`/agent/content-providers/${skill}`, {
        params: {
          difficulty,
          type: contentType,
        },
      });
      return response.data.resources || [];
    } catch (error) {
      throw this.handleError(error, 'Failed to get content');
    }
  }

  async getLearningRoadmap(skill: string, secondarySkills?: string[]): Promise<any> {
    try {
      const response = await this.client.get(`/agent/learning-roadmap/${skill}`, {
        params: {
          secondary_skills: secondarySkills?.join(','),
        },
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to get learning roadmap');
    }
  }

  // ==================== Gamification ====================

  async getPlaroPoints(userId: string): Promise<number> {
    try {
      const response = await this.client.get(`/api/plaro/points/${userId}`);
      return response.data.total_points || 0;
    } catch (error) {
      return 0;
    }
  }

  // ==================== Auth Token Management ====================

  private setAuth(token: string, refreshToken?: string): void {
    this.token = token;
    if (refreshToken) {
      this.refreshToken = refreshToken;
      this.storeRefreshToken(refreshToken);
    }
    this.storeToken(token);
  }

  private clearAuth(): void {
    this.token = null;
    this.refreshToken = null;
    localStorage.removeItem('pearl_auth_token');
    localStorage.removeItem('pearl_refresh_token');
  }

  private storeToken(token: string): void {
    localStorage.setItem('pearl_auth_token', token);
  }

  private getStoredToken(): string | null {
    return localStorage.getItem('pearl_auth_token');
  }

  private storeRefreshToken(token: string): void {
    localStorage.setItem('pearl_refresh_token', token);
  }

  private getStoredRefreshToken(): string | null {
    return localStorage.getItem('pearl_refresh_token');
  }

  // ==================== Error Handling ====================

  private handleError(error: any, defaultMessage: string): Error {
    let message = defaultMessage;

    if (axios.isAxiosError(error)) {
      const response = error.response?.data as any;
      
      if (response?.error) {
        message = response.error;
      } else if (response?.detail) {
        message = response.detail;
      } else if (error.response?.statusText) {
        message = error.response.statusText;
      }

      console.error(`[API Error] ${message}`, error.response?.data);
    } else if (error instanceof Error) {
      message = error.message;
      console.error(`[API Error] ${message}`);
    }

    return new Error(message);
  }

  // ==================== Health Check ====================

  async healthCheck(): Promise<boolean> {
    try {
      const response = await this.client.get('/health');
      return response.status === 200;
    } catch {
      return false;
    }
  }

  // ==================== Helper Methods ====================

  isAuthenticated(): boolean {
    return !!this.token;
  }

  getToken(): string | null {
    return this.token;
  }
}

// Export singleton instance
export const apiService = new ApiService();
export default apiService;
