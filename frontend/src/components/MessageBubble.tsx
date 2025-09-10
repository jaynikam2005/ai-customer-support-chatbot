import React from 'react';
import { Message } from '@/context/ChatContext';
import { formatDistanceToNow } from 'date-fns';
import { Bot, User } from 'lucide-react';

interface MessageBubbleProps {
  message: Message;
}

const TypingIndicator = () => (
  <div className="flex items-center space-x-1 py-2">
    <div className="flex space-x-1">
      <div className="w-2 h-2 bg-primary/60 rounded-full typing-dots" style={{ animationDelay: '0ms' }} />
      <div className="w-2 h-2 bg-primary/60 rounded-full typing-dots" style={{ animationDelay: '200ms' }} />
      <div className="w-2 h-2 bg-primary/60 rounded-full typing-dots" style={{ animationDelay: '400ms' }} />
    </div>
    <span className="text-xs text-muted-foreground ml-2">AI is typing...</span>
  </div>
);

export default function MessageBubble({ message }: MessageBubbleProps) {
  const isUser = message.type === 'user';
  const timeAgo = formatDistanceToNow(message.timestamp, { addSuffix: true });

  return (
    <div className={`flex gap-3 group slide-in-up ${isUser ? 'justify-end' : 'justify-start'}`}>
      {!isUser && (
        <div className="flex-shrink-0 w-8 h-8 rounded-full bg-accent flex items-center justify-center">
          <Bot className="w-4 h-4 text-accent-foreground" />
        </div>
      )}
      
      <div className={`flex flex-col ${isUser ? 'items-end' : 'items-start'}`}>
        <div className={`${isUser ? 'message-user' : 'message-bot'} relative`}>
          {message.isLoading ? (
            <TypingIndicator />
          ) : (
            <p className="text-sm leading-relaxed whitespace-pre-wrap">
              {message.content}
            </p>
          )}
        </div>
        
        <div className="text-xs text-muted-foreground mt-1 opacity-0 group-hover:opacity-100 transition-opacity">
          {timeAgo}
        </div>
      </div>

      {isUser && (
        <div className="flex-shrink-0 w-8 h-8 rounded-full bg-primary flex items-center justify-center">
          <User className="w-4 h-4 text-primary-foreground" />
        </div>
      )}
    </div>
  );
}