import type { NextAuthOptions } from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";
import bcrypt from "bcryptjs";
import { prisma } from "./prisma";

const DUMMY_HASH = bcrypt.hashSync("usuario-inexistente", 10);

async function registrar(userId: string | null, email: string | null, evento: string) {
  await prisma.acessos.create({ data: { user_id: userId, email, evento } }).catch((e) => console.error("acessos", e));
}

export const authOptions: NextAuthOptions = {
  session: { strategy: "jwt", maxAge: 30 * 24 * 60 * 60 }, // continua conectado por 30 dias
  pages: { signIn: "/" },
  providers: [
    CredentialsProvider({
      name: "E-mail e senha",
      credentials: { email: { type: "email" }, password: { type: "password" } },
      async authorize(raw) {
        const email = String(raw?.email ?? "").trim().toLowerCase().slice(0, 200);
        const senha = String(raw?.password ?? "");
        if (!email || !senha) return null;
        // Limite de tentativas guardado no banco: vale mesmo com várias instâncias (Vercel)
        const desde = new Date(Date.now() - 15 * 60 * 1000);
        const falhas = await prisma.acessos.count({ where: { evento: "login_falhou", email, at: { gte: desde } } });
        if (falhas >= 8) throw new Error("Muitas tentativas. Espere 15 minutos e tente de novo.");
        const u = await prisma.usuarios.findUnique({ where: { email } });
        // Compara mesmo quando o usuário não existe, para não revelar e-mails cadastrados pelo tempo de resposta
        const ok = await bcrypt.compare(senha, u?.senha_hash ?? DUMMY_HASH);
        if (!u || !u.senha_hash || !ok) {
          await registrar(u?.id ?? null, email, "login_falhou");
          return null;
        }
        if (!u.ativo) throw new Error("Este acesso está desativado.");
        await prisma.usuarios.update({ where: { id: u.id }, data: { ultimo_acesso: new Date() } });
        await registrar(u.id, u.email, "login");
        return { id: u.id, name: u.nome, email: u.email };
      },
    }),
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) token.sub = user.id;
      return token;
    },
  },
  secret: process.env.NEXTAUTH_SECRET,
};
