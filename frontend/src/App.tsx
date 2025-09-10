import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { ThemeProvider } from "@/components/ThemeProvider";
import { ChatProvider, useChat } from "@/context/ChatContext";
import Index from "./pages/Index";
import NotFound from "./pages/NotFound";
import LoginForm from "./components/LoginForm";

const queryClient = new QueryClient();

function AppContent() {
  const { state } = useChat();

  if (!state.isAuthenticated) {
    return <LoginForm />;
  }

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Index />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </BrowserRouter>
  );
}

const App = () => (
  <QueryClientProvider client={queryClient}>
    <ThemeProvider defaultTheme="light" storageKey="chatbot-theme">
      <TooltipProvider>
        <ChatProvider>
          <Toaster />
          <Sonner />
          <AppContent />
        </ChatProvider>
      </TooltipProvider>
    </ThemeProvider>
  </QueryClientProvider>
);

export default App;