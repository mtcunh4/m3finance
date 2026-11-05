// Roda a cada publicação (vercel-build).
// - Sem nenhum usuário: cria o dono (SEED_ADMIN_EMAIL, senha SEED_DEFAULT_PASSWORD) com o espaço "Meu Espaço".
// - Com SEED_RESET_PASSWORD=true: volta a senha do dono para SEED_DEFAULT_PASSWORD (para quando esquecer a senha).
import "dotenv/config";
import bcrypt from "bcryptjs";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "../src/generated/prisma/client";

const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL! }) });

async function main() {
  const email = (process.env.SEED_ADMIN_EMAIL ?? "").trim().toLowerCase();
  const senha = process.env.SEED_DEFAULT_PASSWORD ?? "";
  const senhaOk = senha.length >= 8 && /[A-Za-z]/.test(senha) && /\d/.test(senha);

  if (process.env.SEED_RESET_PASSWORD === "true" && email) {
    if (!senhaOk) throw new Error("SEED_DEFAULT_PASSWORD precisa ter pelo menos 8 caracteres, com letras e números.");
    const u = await prisma.usuarios.findUnique({ where: { email } });
    if (u) {
      await prisma.usuarios.update({ where: { id: u.id }, data: { senha_hash: await bcrypt.hash(senha, 10), ativo: true } });
      console.log(`Senha de ${email} redefinida. Lembre de tirar SEED_RESET_PASSWORD.`);
    }
  }

  if (await prisma.usuarios.count()) {
    console.log("Já existe usuário; nada a criar.");
    return;
  }
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    console.warn("SEED_ADMIN_EMAIL não configurado: o usuário não foi criado.");
    return;
  }
  if (!senhaOk) throw new Error("SEED_DEFAULT_PASSWORD precisa ter pelo menos 8 caracteres, com letras e números.");
  const u = await prisma.usuarios.create({
    data: { email, nome: process.env.SEED_ADMIN_NAME?.trim() || "", senha_hash: await bcrypt.hash(senha, 10) },
  });
  const ws = await prisma.workspaces.create({ data: { nome: "Meu Espaço", owner_id: u.id } });
  await prisma.workspace_members.create({ data: { workspace_id: ws.id, user_id: u.id, papel: "owner" } });
  console.log(`Usuário criado: ${email}`);
}

main().finally(() => prisma.$disconnect());
