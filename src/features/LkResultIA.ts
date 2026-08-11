import type { SpeedTestResult } from '../types';

export async function generateResultSentence(result: SpeedTestResult): Promise<string> {
  const apiKey = import.meta.env.VITE_GEMINI_API_KEY;
  if (!apiKey) {
    console.error('VITE_GEMINI_API_KEY is missing');
    return 'Erro: Chave da IA não encontrada (Reinicie o npm run dev).'; 
  }

  // Tratamento do packetLoss caso venha como número direto ou como objeto
  const pl = result.packetLoss;
  const plStr = typeof pl === 'number' 
    ? pl.toFixed(1) + '%' 
    : (pl && typeof (pl as any).lossPercent === 'number' ? (pl as any).lossPercent.toFixed(1) + '%' : 'N/A');

  const prompt = `Você é o assistente do Linka Speedtest. Avalie a conexão do usuário baseado nestes resultados reais:
Download: ${result.dl.toFixed(1)} Mbps
Upload: ${result.ul.toFixed(1)} Mbps
Ping: ${Math.round(result.latency)} ms
Jitter: ${Math.round(result.jitter)} ms
Packet Loss: ${plStr}

Crie UMA única frase curta (máximo 12 palavras) resumindo a qualidade da conexão.
O tom deve ser direto, leve, moderno e amigável.
Exemplos de formato:
"Sua conexão está ótima para qualquer tarefa."
"Sua internet está rápida, mas o ping pode causar travamentos."
"Conexão básica, ideal para navegação leve."

Regras rigorosas:
- NÃO use aspas na resposta.
- NÃO use números, numeração, listas ou marcadores (ex: não comece com "1.").
- NÃO dê notas para a conexão.
- Retorne APENAS o texto da frase, absolutamente mais nada.
- Faça apenas um julgamento qualitativo amigável em português.`;

  try {
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.7,
        }
      })
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error('Gemini API falhou:', response.status, errText);
      return `Erro API: ${response.status} (veja o console)`;
    }

    const data = await response.json();
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
    
    if (text) {
      // Retira possíveis aspas ou quebras de linha enviadas pela IA
      return text.trim().replace(/^"|"$/g, '').replace(/\n/g, ' ');
    }
  } catch (err) {
    console.error('Erro de rede no LkResultIA:', err);
    return 'Erro de rede ao chamar IA.';
  }
  
  return 'Sua conexão está pronta.';
}
