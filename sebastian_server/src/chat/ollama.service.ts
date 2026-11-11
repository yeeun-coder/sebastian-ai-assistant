import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export type OllamaChatMessage = {
  role: 'system' | 'user' | 'assistant';
  content: string;
};

type OllamaChatResponse = {
  message?: { role?: string; content?: string };
};

@Injectable()
export class OllamaService {
  private readonly logger = new Logger(OllamaService.name);

  constructor(private readonly config: ConfigService) {}

  async chat(messages: OllamaChatMessage[]): Promise<string> {
    const baseUrl = (
      this.config.get<string>('OLLAMA_BASE_URL') ?? 'http://127.0.0.1:11434'
    ).replace(/\/$/, '');
    const model = this.config.get<string>('OLLAMA_MODEL') ?? 'llama3.2';
    const timeoutMs = Number(
      this.config.get<string>('OLLAMA_TIMEOUT_MS') ?? '120000',
    );

    const url = `${baseUrl}/api/chat`;
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);

    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model,
          messages,
          stream: false,
        }),
        signal: controller.signal,
      });

      const rawText = await res.text();

      if (!res.ok) {
        throw new Error(
          `HTTP ${res.status}: ${rawText.slice(0, 300)}`,
        );
      }

      let data: OllamaChatResponse;
      try {
        data = JSON.parse(rawText) as OllamaChatResponse;
      } catch {
        throw new Error('Ollama 응답 JSON 파싱 실패');
      }

      const content = data.message?.content;
      if (typeof content !== 'string' || !content.trim()) {
        throw new Error('Ollama 응답에 assistant 내용이 없습니다');
      }

      return content.trim();
    } catch (err: unknown) {
      const name = err instanceof Error ? err.name : '';
      if (name === 'AbortError') {
        this.logger.warn(`Ollama 요청 타임아웃 (${timeoutMs}ms)`);
        throw new Error(`Ollama 응답 시간 초과(${timeoutMs}ms)`);
      }
      if (err instanceof Error) {
        this.logger.warn(`Ollama 호출 실패: ${err.message}`);
        throw err;
      }
      throw new Error(String(err));
    } finally {
      clearTimeout(timer);
    }
  }
}
