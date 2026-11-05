# Instruções para o Claude Code

- Responda e escreva textos de interface em português do Brasil. O usuário não é programador: explique mudanças em linguagem simples.
- Leia o README antes de mudar qualquer coisa.
- Formato igual ao LIGA e aos autos: Next.js na Vercel, banco Neon com Prisma, login NextAuth, backups no Vercel Blob. Publicar é enviar ao GitHub: a Vercel publica sozinha.
- A tela é uma página só: `public/app.html`. Não reescreva em React nem divida em arquivos sem pedido explícito.
- Toda regra de acesso fica no banco: a tela só usa `/api/fin`, que chama as funções `fin_*` (conferem espaço e papel). Não crie rotas que leiam tabelas direto.
- Mudança no banco = nova pasta em `prisma/migrations/` com data e hora no nome. Nunca edite uma migração já publicada.
- A cada mudança publicada, suba `APP_VERSION`/`APP_VERSION_DESC` em `public/app.html` e a versão em `package.json`.
- Antes de publicar: `npx tsc --noEmit` e `npx next build` sem erros.
- Nunca grave chaves, senhas, dados financeiros ou cópias de segurança no repositório.
