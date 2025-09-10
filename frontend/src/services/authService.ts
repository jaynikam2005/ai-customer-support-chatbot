import { apiClient } from '@/config/api';
import { isTokenExpired, getTokenRemainingSeconds } from './tokenUtils';

export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  password: string;
}

export interface AuthResponse {
  token: string;
  username: string;
}

export const authService = {
  async login(credentials: LoginRequest): Promise<AuthResponse> {
    try {
      console.log('Attempting login for user:', credentials.username);
      const response = await apiClient.post('/api/auth/login', credentials);
      const { token, username } = response.data;
      
      console.log('Login successful, storing token for user:', username);
      // Store token in localStorage
      localStorage.setItem('auth_token', token);
      localStorage.setItem('username', username);
      
      return { token, username };
    } catch (error) {
      console.error('Login failed:', error);
      throw error;
    }
  },

  async register(userData: RegisterRequest): Promise<AuthResponse> {
    try {
      console.log('Attempting registration for user:', userData.username);
      const response = await apiClient.post('/api/auth/register', userData);
      const { token, username } = response.data;
      
      console.log('Registration successful, storing token for user:', username);
      // Store token in localStorage
      localStorage.setItem('auth_token', token);
      localStorage.setItem('username', username);
      
      return { token, username };
    } catch (error) {
      console.error('Registration failed:', error);
      throw error;
    }
  },

  logout(): void {
    console.log('Logging out user');
    localStorage.removeItem('auth_token');
    localStorage.removeItem('username');
  },

  getToken(): string | null {
    const token = localStorage.getItem('auth_token');
    if (!token) {
      console.log('No token found in localStorage');
      return null;
    }
    if (isTokenExpired(token)) {
      console.log('Stored token expired, clearing');
      localStorage.removeItem('auth_token');
      localStorage.removeItem('username');
      return null;
    }
    const remaining = getTokenRemainingSeconds(token);
    if (remaining !== null) {
      console.log(`Token valid, remaining seconds: ${remaining}`);
    }
    return token;
  },

  getUsername(): string | null {
    return localStorage.getItem('username');
  },

  isAuthenticated(): boolean {
    const token = this.getToken();
    const isAuth = !!token;
    console.log('Authentication check (with expiry):', isAuth);
    return isAuth;
  }
};