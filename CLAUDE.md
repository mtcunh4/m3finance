# Instruções para o Claude Code

- Responda e escreva textos de interface em português do Brasil. O usuário não é programador: explique mudanças em linguagem simples.
- Leia o README antes de mudar qualquer coisa.
- Formato igual ao LIGA e aos autos: Next.js na Vercel, banco Neon com Prisma, login NextAuth, backups no Vercel Blob. Publicar é enviar ao GitHub: a Vercel publica sozinha.
- A tela é uma página só: `public/app.html`. Não reescreva em React nem divida em arquivos sem pedido explícito.
- Toda regra de acesso fica no banco: a tela só usa `/api/fin`, que chama as funções `fin_*` (conferem espaço e papel). Não crie rotas que leiam tabelas direto.
- Mudança no banco = nova pasta em `prisma/migrations/` com data e hora no nome. Nunca edite uma migração já publicada.
- A cada mudança publicada, suba `APP_VERSION`/`APP_VERSION_DESC` em `public/app.html` e a versão em `package.json`.
- Numeração das versões: só um dígito depois do ponto. Depois de x.9 vem a (x+1).0 (ex.: 6.8, 6.9, 7.0; nunca 6.10). Em `package.json` fica com `.0` no fim (6.7 → 6.7.0).
- Antes de publicar: `npx tsc --noEmit` e `npx next build` sem erros.
- Nunca grave chaves, senhas, dados financeiros ou cópias de segurança no repositório.
