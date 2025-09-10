import { createContext, useContext, useReducer, useCallback, useMemo, useEffect } from 'react';
import { useToast } from '@/hooks/use-toast';
import { chatService } from '@/services/chatService';
import { authService } from '@/services/authService';

export interface Message {
  id: string;
  content: string;
  type: 'user' | 'bot';
  timestamp: Date;
  isLoading?: boolean;
  intent?: string;
  confidence?: number;
}

export interface ChatSession {
  id: string;
  title: string;
  messages: Message[];
  lastMessage: Date;
}

interface ChatState {
  sessions: ChatSession[];
  activeSessionId: string | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  username: string | null;
}

type ChatAction =
  | { type: 'SET_SESSIONS'; payload: ChatSession[] }
  | { type: 'SET_ACTIVE_SESSION'; payload: string }
  | { type: 'ADD_MESSAGE'; payload: { sessionId: string; message: Message } }
  | { type: 'UPDATE_MESSAGE'; payload: { sessionId: string; messageId: string; updates: Partial<Message> } }
  | { type: 'CREATE_SESSION'; payload: ChatSession }
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_AUTH'; payload: { isAuthenticated: boolean; username: string | null } };

const initialState: ChatState = {
  sessions: [],
  activeSessionId: null,
  isLoading: false,
  isAuthenticated: authService.isAuthenticated(),
  username: authService.getUsername(),
};

function chatReducer(state: ChatState, action: ChatAction): ChatState {
  switch (action.type) {
    case 'SET_SESSIONS':
      return { 
        ...state, 
        sessions: action.payload,
        activeSessionId: action.payload.length > 0 ? action.payload[0]?.id || null : null
      };
    case 'SET_ACTIVE_SESSION':
      return { ...state, activeSessionId: action.payload };
    case 'ADD_MESSAGE':
      return {
        ...state,
        sessions: state.sessions.map(session =>
          session.id === action.payload.sessionId
            ? {
                ...session,
                messages: [...session.messages, action.payload.message],
                lastMessage: action.payload.message.timestamp,
                title: session.messages.length === 0 
                  ? action.payload.message.content.slice(0, 30) + '...' 
                  : session.title
              }
            : session
        ),
      };
    case 'UPDATE_MESSAGE':
      return {
        ...state,
        sessions: state.sessions.map(session =>
          session.id === action.payload.sessionId
            ? {
                ...session,
                messages: session.messages.map(msg =>
                  msg.id === action.payload.messageId
                    ? { ...msg, ...action.payload.updates }
                    : msg
                ),
              }
            : session
        ),
      };
    case 'CREATE_SESSION':
      return {
        ...state,
        sessions: [action.payload, ...state.sessions],
        activeSessionId: action.payload.id,
      };
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
    case 'SET_AUTH':
      return { 
        ...state, 
        isAuthenticated: action.payload.isAuthenticated,
        username: action.payload.username
      };
    default:
      return state;
  }
}

interface ChatContextType {
  state: ChatState;
  sendMessage: (content: string) => Promise<void>;
  createNewChat: () => void;
  switchChat: (sessionId: string) => void;
  loadHistory: () => Promise<void>;
  getCurrentSession: () => ChatSession | undefined;
  login: (username: string, password: string) => Promise<void>;
  register: (username: string, password: string) => Promise<void>;
  logout: () => void;
}

const ChatContext = createContext<ChatContextType | undefined>(undefined);

export function ChatProvider({ children }: Readonly<{ children: React.ReactNode }>) {
  const [state, dispatch] = useReducer(chatReducer, initialState);
  const { toast } = useToast();

  // Initialize authentication state from localStorage on mount
  useEffect(() => {
    console.log('ChatProvider: Initializing authentication state');
    const isAuth = authService.isAuthenticated();
    const username = authService.getUsername();
    
    console.log('ChatProvider: Initial auth check result:', {
      isAuthenticated: isAuth,
      username: username
    });

    if (isAuth && username) {
      dispatch({ 
        type: 'SET_AUTH', 
        payload: { isAuthenticated: true, username } 
      });
    }

    // Listen for token expiry events from axios interceptor
    const handleAuthLogout = () => {
      console.log('ChatProvider: Received auth-logout event, updating state');
      dispatch({ 
        type: 'SET_AUTH', 
        payload: { isAuthenticated: false, username: null } 
      });
      dispatch({ type: 'SET_SESSIONS', payload: [] });
      toast({
        title: "Session Expired",
        description: "Your session has expired. Please log in again.",
        variant: "destructive",
      });
    };

    window.addEventListener('auth-logout', handleAuthLogout);
    
    return () => {
      window.removeEventListener('auth-logout', handleAuthLogout);
    };
  }, [toast]);

  // Add dynamic title updates
  useEffect(() => {
    // Calculate unread messages (messages from bot that user hasn't seen)
    const currentSession = state.sessions.find(session => session.id === state.activeSessionId);
    
    if (!state.isAuthenticated) {
      document.title = 'AI Customer Support ChatBot - Login';
      return;
    }

    if (!currentSession) {
      document.title = 'AI Customer Support ChatBot';
      return;
    }

    // Get the last few messages to check for new bot responses
    const recentMessages = currentSession.messages.slice(-5);
    const hasNewBotMessages = recentMessages.some(msg => 
      msg.type === 'bot' && 
      !msg.isLoading && 
      msg.timestamp > new Date(Date.now() - 30000) // Messages from last 30 seconds
    );

    // Count recent bot messages as "unread"
    const unreadCount = recentMessages.filter(msg => 
      msg.type === 'bot' && 
      !msg.isLoading && 
      msg.timestamp > new Date(Date.now() - 60000) // Messages from last minute
    ).length;

    // Update document title
    if (hasNewBotMessages && unreadCount > 0) {
      document.title = `(${unreadCount}) AI ChatBot - New Messages!`;
    } else {
      document.title = 'AI Customer Support ChatBot';
    }
  }, [state.sessions, state.activeSessionId, state.isAuthenticated]);

  const getCurrentSession = useCallback(() => {
    return state.sessions.find((session: ChatSession) => session.id === state.activeSessionId);
  }, [state.sessions, state.activeSessionId]);

  const generateId = () => Math.random().toString(36).substring(2, 11);

  const sendMessage = useCallback(async (content: string) => {
    const currentSession = getCurrentSession();
    if (!currentSession) return;

    // Debug authentication state
    const token = localStorage.getItem('auth_token');
    console.log('SendMessage Debug:', {
      isAuthenticated: state.isAuthenticated,
      hasToken: !!token,
      tokenLength: token?.length,
      username: state.username
    });

    if (!state.isAuthenticated || !token) {
      console.error('User not authenticated when trying to send message');
      return;
    }

    // Add user message
    const userMessage: Message = {
      id: generateId(),
      content,
      type: 'user',
      timestamp: new Date(),
    };

    dispatch({
      type: 'ADD_MESSAGE',
      payload: { sessionId: currentSession.id, message: userMessage }
    });

    // Add loading bot message
    const loadingMessage: Message = {
      id: generateId(),
      content: '',
      type: 'bot',
      timestamp: new Date(),
      isLoading: true,
    };

    dispatch({
      type: 'ADD_MESSAGE',
      payload: { sessionId: currentSession.id, message: loadingMessage }
    });

    try {
      // Call real chat API
      const response = await chatService.sendMessage(content);

      // Update loading message with actual response
      dispatch({
        type: 'UPDATE_MESSAGE',
        payload: {
          sessionId: currentSession.id,
          messageId: loadingMessage.id,
          updates: {
            content: response.reply,
            isLoading: false,
            intent: response.intent,
            confidence: response.confidence,
          }
        }
      });
    } catch (error) {
      // Handle error
      console.error('Failed to send message:', error);
      
      let errorMessage = 'Sorry, I\'m having trouble connecting. Please try again.';
      let toastMessage = 'Unable to reach the server. Please check your connection.';
      let toastTitle = 'Connection Error';
      
      // Check if it's an authentication error
      if (error instanceof Error) {
        if (error.message === 'Token expired') {
          errorMessage = 'Your session has expired. Please log in again.';
          toastMessage = 'Your session has expired. Please log in again.';
          toastTitle = 'Session Expired';
        } else if (error.message === 'No authentication token') {
          errorMessage = 'Please log in to continue.';
          toastMessage = 'Authentication required. Please log in.';
          toastTitle = 'Authentication Required';
        }
      }
      
      dispatch({
        type: 'UPDATE_MESSAGE',
        payload: {
          sessionId: currentSession.id,
          messageId: loadingMessage.id,
          updates: {
            content: errorMessage,
            isLoading: false,
          }
        }
      });

      toast({
        title: toastTitle,
        description: toastMessage,
        variant: "destructive",
      });
    }
  }, [state.isAuthenticated, state.username, getCurrentSession, toast]);

  const createNewChat = useCallback(() => {
    const newSession: ChatSession = {
      id: generateId(),
      title: 'New Chat',
      messages: [],
      lastMessage: new Date(),
    };

    dispatch({ type: 'CREATE_SESSION', payload: newSession });
  }, []);

  const switchChat = useCallback((sessionId: string) => {
    dispatch({ type: 'SET_ACTIVE_SESSION', payload: sessionId });
  }, []);

  const loadHistory = useCallback(async () => {
    if (!state.isAuthenticated) return;
    
    dispatch({ type: 'SET_LOADING', payload: true });
    
    try {
      const history = await chatService.getHistory();
      
      const sessions: ChatSession[] = history.length > 0 
        ? [
            {
              id: generateId(),
              title: 'Previous Conversations',
              messages: history.map(item => ([
                {
                  id: generateId(),
                  content: item.query,
                  type: 'user' as const,
                  timestamp: new Date(item.timestamp),
                },
                {
                  id: generateId(),
                  content: item.reply,
                  type: 'bot' as const,
                  timestamp: new Date(item.timestamp),
                  intent: item.intent,
                }
              ])).flat(),
              lastMessage: new Date(history[0]?.timestamp || Date.now()),
            }
          ]
        : [
            {
              id: generateId(),
              title: 'Welcome Chat',
              messages: [
                {
                  id: generateId(),
                  content: 'Hello! I\'m your AI customer support assistant. How can I help you today?',
                  type: 'bot',
                  timestamp: new Date(),
                }
              ],
              lastMessage: new Date(),
            }
          ];
      
      dispatch({ type: 'SET_SESSIONS', payload: sessions });
    } catch (error) {
      // Create default session if error
      console.error('Failed to load history:', error);
      const defaultSession: ChatSession = {
        id: generateId(),
        title: 'Welcome Chat',
        messages: [
          {
            id: generateId(),
            content: 'Hello! I\'m your AI customer support assistant. How can I help you today?',
            type: 'bot',
            timestamp: new Date(),
          }
        ],
        lastMessage: new Date(),
      };
      
      dispatch({ type: 'SET_SESSIONS', payload: [defaultSession] });
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  }, [state.isAuthenticated]);

  const login = useCallback(async (username: string, password: string) => {
    try {
      const response = await authService.login({ username, password });
      dispatch({ 
        type: 'SET_AUTH', 
        payload: { isAuthenticated: true, username: response.username } 
      });
      await loadHistory();
      toast({
        title: "Login Successful",
        description: `Welcome back, ${response.username}!`,
      });
    } catch (error) {
      toast({
        title: "Login Failed",
        description: "Invalid username or password.",
        variant: "destructive",
      });
      throw error;
    }
  }, [loadHistory, toast]);

  const register = useCallback(async (username: string, password: string) => {
    try {
      const response = await authService.register({ username, password });
      dispatch({ 
        type: 'SET_AUTH', 
        payload: { isAuthenticated: true, username: response.username } 
      });
      await loadHistory();
      toast({
        title: "Registration Successful",
        description: `Welcome, ${response.username}!`,
      });
    } catch (error) {
      toast({
        title: "Registration Failed",
        description: "Username already exists or other error occurred.",
        variant: "destructive",
      });
      throw error;
    }
  }, [loadHistory, toast]);

  const logout = useCallback(() => {
    authService.logout();
    dispatch({ 
      type: 'SET_AUTH', 
      payload: { isAuthenticated: false, username: null } 
    });
    dispatch({ type: 'SET_SESSIONS', payload: [] });
    toast({
      title: "Logged Out",
      description: "You have been successfully logged out.",
    });
  }, [toast]);

  const value = useMemo<ChatContextType>(() => ({
    state,
    sendMessage,
    createNewChat,
    switchChat,
    loadHistory,
    getCurrentSession,
    login,
    register,
    logout,
  }), [state, sendMessage, createNewChat, switchChat, loadHistory, getCurrentSession, login, register, logout]);

  return (
    <ChatContext.Provider value={value}>
      {children}
    </ChatContext.Provider>
  );
}

export function useChat() {
  const context = useContext(ChatContext);
  if (context === undefined) {
    throw new Error('useChat must be used within a ChatProvider');
  }
  return context;
}