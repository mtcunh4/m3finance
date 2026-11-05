# M3 Finance · controle financeiro

> **Para publicar online de graça (Vercel + Neon + Vercel Blob), siga o guia [COLOCAR-NO-AR.md](COLOCAR-NO-AR.md).**

Controle financeiro pessoal: lançamentos (receitas e despesas), cartões e faturas, contas bancárias, categorias, contas a pagar e a receber, importação de extratos, relatórios em PDF e Excel, combustível, consórcio, bloco de notas, calculadora e backups. Migrado em 05/11/2026 do Cloudflare Worker + Supabase (esquema `financeiro` do projeto `painel-loteamentos`) para o mesmo formato do LIGA e dos autos.

| | |
|---|---|
| Versão | 5.0, em `public/app.html` (`APP_VERSION`) e `package.json` |
| Site e servidor | Next.js 14 na Vercel (região São Paulo, `gru1`) |
| Banco | PostgreSQL no Neon, com migrações do Prisma |
| Login | NextAuth (e-mail e senha, sessão de 30 dias) |
| Backups na nuvem | Vercel Blob, privado |

## Como as peças se ligam

```
navegador (public/app.html) ──► /api/fin ──► funções do banco (Neon) ──► tabelas
                             └─► /api/backups ──► Vercel Blob (backups/<espaço>/<arquivo>.json)
```

- **Tela.** O sistema inteiro é uma página só: `public/app.html`, com as bibliotecas (Chart.js, jsPDF, pdf.js) embutidas. O endereço principal (`/`) abre essa página.
- **Dados.** A tela fala com o banco só pelo objeto `DB` (perto do começo do último `<script>`). Ele chama `POST /api/fin` com `{ acao, ws, store, ... }`: `espacos`, `listar`, `obter`, `gravar`, `excluir`, `limpar`.
- **Regras de acesso no banco.** As funções `meus_espacos`, `fin_listar`, `fin_obter`, `fin_gravar`, `fin_excluir` e `fin_limpar` (`prisma/migrations/*/migration.sql`) conferem se quem está logado é membro do espaço de trabalho; `owner` e `editor` gravam, `visualizador` só lê. O servidor informa o usuário com `set_config('app.uid', ...)`, lido por `auth.uid()`.
- **Tabelas.** As mesmas do sistema original, com os mesmos nomes de colunas: `lancamentos`, `cartoes`, `comprasCartao`, `parcelas`, `faturaPagamentos`, `contas`, `categorias`, `contasPagar`, `contasReceber`, `config`, `historico`, `consorcios`, `abastecimentos`, `notas`, `emprestimos`, `bet_lancamentos`. Novas: `usuarios` (no lugar do Supabase Auth) e `acessos`.
- **Login.** `POST /api/auth/callback/credentials` (NextAuth). Senhas com bcrypt em `usuarios.senha_hash`. Troca de senha: `POST /api/senha`. Não há cadastro de contas novas pela tela; o primeiro usuário e o espaço "Meu Espaço" são criados por `prisma/seed.ts`.
- **Backups.** "Fazer Backup" baixa o JSON e guarda uma cópia na nuvem (`PUT /api/backups/<espaço>/<arquivo>`). "Restaurar" substitui as tabelas que vieram no arquivo. Com o tamanho atual (cerca de 2 MB), cabe folgado no limite de 4,5 MB por envio da Vercel; o download no computador funciona sempre.

## Rodar no computador

Requisitos: Node.js 20.19 ou superior e PostgreSQL 14 ou superior.

```bash
cp .env.example .env    # preencha DATABASE_URL, NEXTAUTH_SECRET e SEED_*
npm install
npx prisma migrate deploy
npx prisma db seed
npm run dev
```

Sem `BLOB_STORE_ID` (ou `BLOB_READ_WRITE_TOKEN`), os backups vão para `./storage/backups`.

## Mudanças

- **Tela:** edite `public/app.html`. A cada mudança publicada, suba `APP_VERSION` e `APP_VERSION_DESC` ali e a versão em `package.json`.
- **Banco:** nova pasta em `prisma/migrations/` com data e hora no nome. Nunca edite uma migração já publicada. Coluna nova numa tabela: basta a migração (o `DB.put` grava qualquer coluna que existir). Tabela nova: incluir na lista de `_loja(...)` e em `STORES` na tela. Depois rode `npx prisma db pull`.
- **Publicações na Vercel:** os ramos `claude/*` não geram publicação de teste (`git.deploymentEnabled` em `vercel.json`), para não gastar o limite diário do plano gratuito. Só o `main` publica.
- **Nunca** grave chaves, senhas, planilhas ou cópias de segurança no repositório.
