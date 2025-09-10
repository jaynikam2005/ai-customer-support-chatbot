import { useEffect } from 'react';
import { useChat } from '@/context/ChatContext';
import MobileLayout from '@/components/MobileLayout';

const Index = () => {
  const { loadHistory } = useChat();

  useEffect(() => {
    loadHistory();
  }, [loadHistory]);

  return <MobileLayout />;
};

export default Index;
