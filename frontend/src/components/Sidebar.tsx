import * as React from 'react';
import { useChat } from '@/context/ChatContext';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Plus, Moon, Sun, LogOut, MessageCircle } from 'lucide-react';
import { useTheme } from '@/components/ThemeProvider';
import { formatDistanceToNow } from 'date-fns';

export default function Sidebar() {
  const { state, createNewChat, switchChat, logout } = useChat();
  const { theme, setTheme } = useTheme();

  const toggleTheme = () => {
    setTheme(theme === 'dark' ? 'light' : 'dark');
  };

  const truncateText = (text: string, maxLength: number = 30) => {
    return text.length > maxLength ? text.slice(0, maxLength) + '...' : text;
  };

  return (
    <div className="w-80 bg-background border-r border-border flex flex-col h-full">
      {/* Header */}
      <div className="p-4 border-b border-border">
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-lg font-semibold">AI Support Chat</h1>
          <div className="flex gap-1">
            <Button
              onClick={toggleTheme}
              className="w-8 h-8 p-0"
            >
              {theme === 'dark' ? (
                <Sun className="h-4 w-4" />
              ) : (
                <Moon className="h-4 w-4" />
              )}
            </Button>
            <Button
              onClick={logout}
              className="w-8 h-8 p-0"
              title="Logout"
            >
              <LogOut className="h-4 w-4" />
            </Button>
          </div>
        </div>
        
        <Button 
          onClick={createNewChat} 
          className="w-full gap-2"
        >
          <Plus className="h-4 w-4" />
          New Chat
        </Button>
      </div>

      {/* Chat History */}
      <div className="flex-1 p-4">
        <div className="mb-2">
          <h2 className="text-sm font-medium text-muted-foreground">Recent Chats</h2>
          {state.username && (
            <p className="text-xs text-muted-foreground">Welcome, {state.username}</p>
          )}
        </div>
        
        <ScrollArea className="h-full">
          <div className="space-y-2">
            {state.sessions.map((session) => (
              <Button
                key={session.id}
                className="w-full justify-start text-left p-3 h-auto"
                onClick={() => switchChat(session.id)}
              >
                <div className="flex flex-col items-start gap-1">
                  <div className="flex items-center gap-2">
                    <MessageCircle className="h-4 w-4" />
                    <span className="text-sm font-medium">
                      {truncateText(session.title)}
                    </span>
                  </div>
                  <span className="text-xs text-muted-foreground">
                    {formatDistanceToNow(session.lastMessage, { addSuffix: true })}
                  </span>
                </div>
              </Button>
            ))}
          </div>
        </ScrollArea>
      </div>
    </div>
  );
}