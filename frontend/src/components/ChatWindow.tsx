import React, { useState, useRef, useEffect } from 'react';
import { useChat } from '@/context/ChatContext';
import MessageBubble from './MessageBubble';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Send, Loader2 } from 'lucide-react';

export default function ChatWindow() {
  const { state, sendMessage, getCurrentSession } = useChat();
  const [inputValue, setInputValue] = useState('');
  const [isSending, setIsSending] = useState(false);
  const scrollAreaRef = useRef<HTMLDivElement>(null);
  const currentSession = getCurrentSession();

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    if (scrollAreaRef.current) {
      const scrollElement = scrollAreaRef.current.querySelector('[data-radix-scroll-area-viewport]');
      if (scrollElement) {
        scrollElement.scrollTop = scrollElement.scrollHeight;
      }
    }
  }, [currentSession?.messages]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputValue.trim() || isSending || !currentSession) return;

    const message = inputValue.trim();
    setInputValue('');
    setIsSending(true);

    try {
      await sendMessage(message);
    } finally {
      setIsSending(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit(e);
    }
  };

  if (!currentSession) {
    return (
      <div className="flex-1 flex items-center justify-center bg-secondary/20">
        <div className="text-center">
          <div className="w-16 h-16 bg-accent rounded-full flex items-center justify-center mx-auto mb-4">
            <Send className="w-8 h-8 text-accent-foreground" />
          </div>
          <h2 className="text-xl font-semibold mb-2">Welcome to AI Support</h2>
          <p className="text-muted-foreground mb-6 max-w-md">
            Select a conversation from the sidebar or start a new chat to begin talking with our AI assistant.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col h-full bg-background">
      {/* Chat Header */}
      <div className="border-b border-border p-4">
        <h2 className="font-semibold text-lg">
          {currentSession.title === 'New Chat' && currentSession.messages.length > 0
            ? currentSession.messages[0]?.content.slice(0, 30) + '...' || 'Chat'
            : currentSession.title
          }
        </h2>
        <p className="text-sm text-muted-foreground">
          AI Assistant • Always here to help
        </p>
      </div>

      {/* Messages Area */}
      <ScrollArea ref={scrollAreaRef} className="flex-1 p-4">
        <div className="space-y-6 max-w-4xl mx-auto">
          {currentSession.messages.length === 0 ? (
            <div className="text-center py-12">
              <div className="w-12 h-12 bg-primary rounded-full flex items-center justify-center mx-auto mb-4">
                <Send className="w-6 h-6 text-primary-foreground" />
              </div>
              <h3 className="text-lg font-medium mb-2">Start the conversation</h3>
              <p className="text-muted-foreground">
                Type a message below to begin chatting with your AI assistant.
              </p>
            </div>
          ) : (
            currentSession.messages.map((message) => (
              <MessageBubble key={message.id} message={message} />
            ))
          )}
        </div>
      </ScrollArea>

      {/* Input Area */}
      <div className="border-t border-border p-4">
        <form onSubmit={handleSubmit} className="max-w-4xl mx-auto">
          <div className="flex gap-3">
            <Input
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              onKeyPress={handleKeyPress}
              placeholder="Type your message here..."
              disabled={isSending}
              className="flex-1"
            />
            <Button 
              type="submit" 
              disabled={!inputValue.trim() || isSending}
              size="icon"
            >
              {isSending ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Send className="w-4 h-4" />
              )}
            </Button>
          </div>
          <p className="text-xs text-muted-foreground mt-2 text-center">
            Press Enter to send, Shift + Enter for new line
          </p>
        </form>
      </div>
    </div>
  );
}