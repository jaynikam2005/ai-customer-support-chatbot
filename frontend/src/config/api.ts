import axios, { AxiosResponse, AxiosError, InternalAxiosRequestConfig } from 'axios';
import { isTokenExpired } from '@/services/tokenUtils';

// API Configuration
export const API_BASE_URL = import.meta.env.VITE_API_URL || 
  (process.env.NODE_ENV === 'production' 
    ? 'https://your-domain.com'  // Replace with your production URL
    : 'http://localhost:8080');   // Java backend URL

// Debug logging
console.log('Frontend API Configuration:', {
  VITE_API_URL: import.meta.env.VITE_API_URL,
  NODE_ENV: process.env.NODE_ENV,
  API_BASE_URL
});

export const AI_SERVICE_URL = process.env.NODE_ENV === 'production'
  ? 'https://your-ai-domain.com'  // Replace with your production AI service URL
  : 'http://localhost:5000';      // Python AI service URL

// Create axios instances
export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const aiClient = axios.create({
  baseURL: AI_SERVICE_URL,
  timeout: 30000, // Longer timeout for AI responses
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = localStorage.getItem('auth_token');
    
    console.log('Interceptor: Processing request to', config.url);
    console.log('Interceptor: Token exists:', !!token);
    
    if (token) {
      if (isTokenExpired(token)) {
        console.log('Interceptor: Token expired, clearing localStorage');
        localStorage.removeItem('auth_token');
        localStorage.removeItem('username');
        // Dispatch logout event to notify the app
        window.dispatchEvent(new CustomEvent('auth-logout'));
        
        // For non-auth endpoints, reject the request
        if (config.url && !config.url.includes('/auth/')) {
          console.log('Interceptor: Rejecting authenticated request with expired token');
          return Promise.reject(new Error('Token expired'));
        }
      } else {
        config.headers.Authorization = `Bearer ${token}`;
        console.log('Interceptor: Added valid token to request header');
      }
    } else {
      console.log('Interceptor: No token found in localStorage');
      
      // If this is a request to a protected endpoint without a token, reject it
      if (config.url && !config.url.includes('/auth/') && !config.url.includes('/health')) {
        console.log('Interceptor: Rejecting protected request without token');
        return Promise.reject(new Error('No authentication token'));
      }
    }
    return config;
  },
  (error: AxiosError) => Promise.reject(new Error(error.message))
);

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response: AxiosResponse) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      const token = localStorage.getItem('auth_token');
      if (token && isTokenExpired(token)) {
        console.log('401 due to expired token, clearing and prompting re-login.');
      } else {
        console.log('401 received (non-expiry). Clearing token.');
      }
      localStorage.removeItem('auth_token');
      localStorage.removeItem('username');
      // Soft signal to app instead of hard reload: dispatch an event
      window.dispatchEvent(new CustomEvent('auth-logout'));
    }
    return Promise.reject(error);
  }
);