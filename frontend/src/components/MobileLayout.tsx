import React, { useState } from 'react';
import { useChat } from '@/context/ChatContext';
import { Button } from '@/components/ui/button';
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet';
import { Menu } from 'lucide-react';
import Sidebar from './Sidebar';
import ChatWindow from './ChatWindow';
import { useIsMobile } from '@/hooks/use-mobile';

export default function MobileLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const isMobile = useIsMobile();

  if (!isMobile) {
    return (
      <div className="h-screen flex bg-background overflow-hidden">
        <Sidebar />
        <ChatWindow />
      </div>
    );
  }

  return (
    <div className="h-screen flex flex-col bg-background overflow-hidden">
      {/* Mobile Header */}
      <div className="flex items-center justify-between p-4 border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <Sheet open={sidebarOpen} onOpenChange={setSidebarOpen}>
          <SheetTrigger asChild>
            <Button variant="ghost" size="icon">
              <Menu className="w-5 h-5" />
            </Button>
          </SheetTrigger>
          <SheetContent side="left" className="p-0 w-80">
            <Sidebar />
          </SheetContent>
        </Sheet>
        
        <h1 className="font-semibold text-lg">AI Support</h1>
        <div className="w-10" /> {/* Spacer for centering */}
      </div>

      {/* Chat Window */}
      <div className="flex-1 overflow-hidden">
        <ChatWindow />
      </div>
    </div>
  );
}