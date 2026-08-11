import { useState, useRef, useEffect, useCallback } from 'react';
import { TopBar } from '../components/TopBar';
import type { SpeedTestResult, ConnectionType } from '../types';

const WORKER_URL =
  'https://linka-ai-diagnosis-worker.giammattey-luiz.workers.dev/api/ai/diagnostico-conexao';

interface Message {
  role: 'user' | 'assistant';
  content: string;
}

interface Props {
  result: SpeedTestResult;
  connectionType?: ConnectionType | null;
  onBack: () => void;
}

async function* streamMessages(
  userMessage: string,
  history: Message[],
  result: SpeedTestResult,
  connectionType?: ConnectionType | null,
): AsyncGenerator<string> {
  const response = await fetch(`${WORKER_URL}?stream=true`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      schemaVersion: '3',
      generatedAtEpochMs: Date.now(),
      connectionType: connectionType ?? 'unknown',
      metricasAtuais: {
        downloadMbps: result.dl,
        uploadMbps: result.ul,
        latenciaMs: result.latency,
        jitterMs: result.jitter,
        perdaPacotesPercentual: result.packetLoss,
      },
      feedbackUsuario: userMessage,
      historico: history.map((m) => ({ role: m.role, content: m.content })),
    }),
  });

  if (!response.ok || !response.body) {
    throw new Error(`Erro na requisicao: ${response.status}`);
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() ?? '';
      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = line.slice(6).trim();
          if (data === '[DONE]') return;
          try {
            const parsed = JSON.parse(data) as { text?: string };
            if (parsed.text) yield parsed.text;
          } catch {
            // ignora chunks malformados
          }
        }
      }
    }
  } finally {
    reader.releaseLock();
  }
}

// Ponto animado enquanto a IA esta "digitando"
function TypingIndicator() {
  const [dots, setDots] = useState('.');
  useEffect(() => {
    const id = setInterval(() => {
      setDots((d) => (d.length >= 3 ? '.' : d + '.'));
    }, 400);
    return () => clearInterval(id);
  }, []);
  return (
    <div
      style={{
        alignSelf: 'flex-start',
        background: '#1E1130',
        borderRadius: '16px 16px 16px 4px',
        padding: '10px 14px',
        maxWidth: '80%',
      }}
    >
      <span style={{ color: '#9CA3AF', fontSize: 18, letterSpacing: 2 }}>{dots}</span>
    </div>
  );
}

export function ChatDiagnosticoScreen({ result, connectionType, onBack }: Props) {
  const [messages, setMessages] = useState<Message[]>([
    {
      role: 'assistant',
      content: 'Ola! Analisei os resultados do seu teste. O que gostaria de saber?',
    },
  ]);
  const [input, setInput] = useState('');
  const [streaming, setStreaming] = useState(false);
  const [streamError, setStreamError] = useState<string | null>(null);

  const listEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Scroll automatico ao fim das mensagens
  useEffect(() => {
    listEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, streaming]);

  const handleSend = useCallback(async () => {
    const text = input.trim();
    if (!text || streaming) return;

    const userMsg: Message = { role: 'user', content: text };
    const historyBeforeSend = [...messages];

    setMessages((prev) => [...prev, userMsg]);
    setInput('');
    setStreaming(true);
    setStreamError(null);

    // Adiciona placeholder para a resposta da IA (string vazia que vai crescendo)
    setMessages((prev) => [...prev, { role: 'assistant', content: '' }]);

    try {
      const gen = streamMessages(text, historyBeforeSend, result, connectionType);
      for await (const chunk of gen) {
        setMessages((prev) => {
          const updated = [...prev];
          const last = updated[updated.length - 1];
          if (last.role === 'assistant') {
            updated[updated.length - 1] = {
              ...last,
              content: last.content + chunk,
            };
          }
          return updated;
        });
      }
    } catch (err) {
      setStreamError(err instanceof Error ? err.message : 'Erro ao conectar com a IA');
      // Remove placeholder vazio se deu erro sem nenhum conteudo
      setMessages((prev) => {
        const last = prev[prev.length - 1];
        if (last.role === 'assistant' && last.content === '') {
          return prev.slice(0, -1);
        }
        return prev;
      });
    } finally {
      setStreaming(false);
      // Foca o input apos resposta
      setTimeout(() => inputRef.current?.focus(), 100);
    }
  }, [input, streaming, messages, result, connectionType]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLInputElement>) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        void handleSend();
      }
    },
    [handleSend],
  );

  const orbitBg = '#0D0D1A';
  const accent = '#6C2BFF';
  const orbitBorder = 'rgba(124, 95, 255, 0.18)';

  return (
    <div
      style={{
        background: orbitBg,
        minHeight: '100dvh',
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      {/* TopBar escura */}
      <div
        style={{
          background: orbitBg,
          borderBottom: `1px solid ${orbitBorder}`,
          position: 'sticky',
          top: 0,
          zIndex: 10,
        }}
      >
        <TopBar
          onBack={onBack}
          title="Chat com a IA"
          showTitle
        />
      </div>

      {/* Lista de mensagens */}
      <div
        style={{
          flex: 1,
          overflowY: 'auto',
          padding: '16px 16px 8px',
          display: 'flex',
          flexDirection: 'column',
          gap: 10,
        }}
        role="log"
        aria-live="polite"
        aria-label="Conversa com a IA"
      >
        {messages.map((msg, index) => (
          <div
            key={index}
            style={{
              display: 'flex',
              justifyContent: msg.role === 'user' ? 'flex-end' : 'flex-start',
            }}
          >
            <div
              style={{
                background: msg.role === 'user' ? accent : '#1E1130',
                color: '#F3F4F6',
                borderRadius:
                  msg.role === 'user'
                    ? '16px 16px 4px 16px'
                    : '16px 16px 16px 4px',
                padding: '10px 14px',
                maxWidth: '80%',
                fontSize: 14,
                lineHeight: 1.6,
                wordBreak: 'break-word',
                // Mensagem placeholder vazia nao deve aparecer antes do streaming comecar
                opacity: msg.content === '' ? 0 : 1,
              }}
            >
              {msg.content}
            </div>
          </div>
        ))}

        {/* Indicador de digitacao durante streaming (antes do primeiro chunk) */}
        {streaming && messages[messages.length - 1]?.content === '' && (
          <TypingIndicator />
        )}

        {/* Erro de stream */}
        {streamError && (
          <div
            style={{
              alignSelf: 'flex-start',
              background: 'rgba(239, 68, 68, 0.12)',
              border: '1px solid rgba(239, 68, 68, 0.3)',
              borderRadius: '12px 12px 12px 4px',
              padding: '8px 12px',
              maxWidth: '80%',
            }}
          >
            <p style={{ color: '#EF4444', fontSize: 13, margin: 0 }}>{streamError}</p>
          </div>
        )}

        <div ref={listEndRef} />
      </div>

      {/* Input fixo na parte inferior */}
      <div
        style={{
          background: orbitBg,
          borderTop: `1px solid ${orbitBorder}`,
          padding: `12px 16px calc(12px + var(--safe-bottom, 0px)) 16px`,
          display: 'flex',
          gap: 8,
          alignItems: 'center',
        }}
      >
        <input
          ref={inputRef}
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Digite sua pergunta..."
          disabled={streaming}
          aria-label="Mensagem para a IA"
          style={{
            flex: 1,
            background: '#1A0B2E',
            border: `1px solid ${orbitBorder}`,
            borderRadius: 24,
            padding: '10px 16px',
            color: '#F3F4F6',
            fontSize: 14,
            outline: 'none',
            opacity: streaming ? 0.6 : 1,
            transition: 'opacity 0.2s',
          }}
        />
        <button
          onClick={() => void handleSend()}
          disabled={streaming || !input.trim()}
          aria-label="Enviar mensagem"
          style={{
            background: streaming || !input.trim() ? 'rgba(108, 43, 255, 0.3)' : accent,
            border: 'none',
            borderRadius: '50%',
            width: 44,
            height: 44,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: streaming || !input.trim() ? 'not-allowed' : 'pointer',
            flexShrink: 0,
            transition: 'background 0.2s',
          }}
        >
          {/* Icone de envio — seta para cima */}
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#FFFFFF"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <line x1="12" y1="19" x2="12" y2="5" />
            <polyline points="5 12 12 5 19 12" />
          </svg>
        </button>
      </div>
    </div>
  );
}
