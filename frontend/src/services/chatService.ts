import { apiClient } from '@/config/api';

export interface ChatMessage {
  message: string;
}

export interface ChatResponse {
  reply: string;
  intent: string;
  confidence: number;
  timestamp: string;
}

export interface ConversationHistory {
  id: number;
  query: string;
  reply: string;
  intent: string;
  timestamp: string;
}

export const chatService = {
  async sendMessage(message: string): Promise<ChatResponse> {
    try {
      console.log('Sending chat message:', message);
      const response = await apiClient.post('/api/chat', { message });
      console.log('Chat response received:', response.data);
      return response.data;
    } catch (error) {
      console.error('Failed to send chat message:', error);
      throw error;
    }
  },

  async getHistory(): Promise<ConversationHistory[]> {
    const username = localStorage.getItem('username');
    if (!username) {
      console.error('No username found for history request');
      throw new Error('User not authenticated');
    }
    
    try {
      console.log('Fetching chat history for user:', username);
      const response = await apiClient.get(`/api/history/${username}`);
      console.log('Chat history received:', response.data);
      return response.data;
    } catch (error) {
      console.error('Failed to fetch chat history:', error);
      throw error;
    }
  }
};