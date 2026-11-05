# Como colocar o M3 Finance no ar (grátis: Vercel + Neon + Vercel Blob)

Mesmo caminho usado no LIGA e nos autos. Ao final, o sistema estará num endereço como `https://m3finance.vercel.app`, com todos os dados do sistema atual.

| Serviço | Para que serve | Custo |
| --- | --- | --- |
| **Vercel** | Deixa o sistema no ar e publica sozinho cada atualização do GitHub | Grátis (plano Hobby) |
| **Neon** | Guarda os dados: lançamentos, cartões, faturas, contas, categorias… | Grátis, até 0,5 GB |
| **Vercel Blob** | Guarda os backups na nuvem (tela Segurança) | Grátis, até cerca de 1 GB |

Tempo estimado: 20 minutos.

---

## Parte 1: salvar os dados do sistema atual

1. Abra o sistema atual (`m3finance.mtcunh400.workers.dev`) e entre.
2. No menu, clique em **Segurança** e depois em **⬇ Fazer Backup (JSON)**. Guarde o arquivo `controle-financeiro-backup-....json`.

O sistema atual continua funcionando até você decidir desligá-lo.

---

## Parte 2: criar o projeto na Vercel

1. Em **vercel.com**, clique em **Add New… → Project** e importe o repositório `m3finance`.
2. Não clique em **Add** no "Prisma Postgres" que a Vercel sugere.
3. Abra o projeto e vá em **Settings › Environment Variables**. Cadastre:

   | Key | Value |
   | --- | --- |
   | `NEXTAUTH_SECRET` | um texto aleatório: abra **https://generate-secret.vercel.app/32** e copie |
   | `SEED_ADMIN_EMAIL` | o seu e-mail; será o seu login |
   | `SEED_ADMIN_NAME` | o seu nome |
   | `SEED_DEFAULT_PASSWORD` | uma senha provisória com pelo menos 8 caracteres, letras e números (troque depois em Segurança) |

---

## Parte 3: banco de dados (Neon)

1. No projeto, aba **Storage › Create Database › Neon**. Região **São Paulo (sa-east-1)**, plano **Free**, nome `m3finance`.
2. Na tela de ligação com o projeto:
   - deixe as caixas de **Create database branch** desmarcadas;
   - em **Custom Prefix**, escreva **`DATABASE`**.

## Parte 4: backups na nuvem (Vercel Blob)

1. Em **Storage › Create Database › Blob**, nome `m3finance-backups`, acesso **Private**.
2. Confira se ele ficou ligado ao projeto (em **Projects**, o `m3finance` aparece). A Vercel cria sozinha `BLOB_STORE_ID`; não é preciso copiar chave. **Não clique em "Revoke Token".**

---

## Parte 5: publicar e trazer os dados

1. Em **Deployments**, publique (**Redeploy**) e espere aparecer **Ready**.
2. Abra o endereço e entre com o e-mail e a senha provisória.
3. Vá em **Segurança › ⬆ Restaurar Backup**, escolha o arquivo da Parte 1 e confirme em **Restaurar**.
4. Confira o Dashboard e as Faturas.
5. Em **Segurança › Alterar senha**, troque a senha provisória pela sua.

---

## Esqueci a senha

1. Na Vercel, em **Settings › Environment Variables**, crie `SEED_RESET_PASSWORD` com o valor `true` (e, se quiser, mude `SEED_DEFAULT_PASSWORD`).
2. Em **Deployments**, faça **Redeploy**. A sua senha volta a ser a de `SEED_DEFAULT_PASSWORD`.
3. Entre, troque a senha em **Segurança** e **apague** a variável `SEED_RESET_PASSWORD`.

## Depois de publicado

- **Atualizações:** quando o código muda no GitHub, a Vercel publica sozinha, sem perder dados.
- **Sistema antigo:** quando tudo estiver conferido, apague o Worker `m3finance` no Cloudflare. Os dados antigos no Supabase podem ser removidos depois (o projeto do Supabase continua com o controle de loteamento).

## Se algo der errado

| Sintoma | O que fazer |
| --- | --- |
| A publicação falha com `P1001`, "Can't reach database" ou "DATABASE_URL não configurada" | Confira a Parte 3 (Neon ligado ao projeto, prefixo `DATABASE`) e faça **Redeploy**. |
| A publicação falha com "SEED_DEFAULT_PASSWORD precisa ter pelo menos 8 caracteres" | Corrija a variável e faça **Redeploy**. |
| O login não funciona | Confira `NEXTAUTH_SECRET` e faça **Redeploy**. |
| "Backups na Nuvem" não lista nada ou dá erro | Confira a Parte 4 (Blob ligado ao projeto) e faça **Redeploy**. |
| Qualquer outra coisa | Em **Deployments**, abra a publicação e **Build Logs**; copie as últimas linhas vermelhas e peça ajuda. |
