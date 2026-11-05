import { NextRequest } from "next/server";
import bcrypt from "bcryptjs";
import { prisma } from "@/lib/prisma";
import { erro, mesmaOrigem, ok, usuarioDaRequisicao } from "@/lib/sessao";

export const dynamic = "force-dynamic";

// Troca de senha de quem está logado (tela Segurança › Alterar senha)
export async function POST(req: NextRequest) {
  if (!mesmaOrigem(req)) return erro("Pedido recusado.", 403);
  const u = await usuarioDaRequisicao(req);
  if (!u) return erro("Sua sessão terminou. Entre de novo.", 401);
  const nova = String((await req.json().catch(() => ({})))?.nova ?? "");
  if (nova.length < 8) return erro("A senha precisa ter pelo menos 8 caracteres.");
  if (Buffer.byteLength(nova) > 72) return erro("A senha pode ter no máximo 72 caracteres.");
  const atual = await prisma.usuarios.findUnique({ where: { id: u.id } });
  if (atual?.senha_hash && (await bcrypt.compare(nova, atual.senha_hash))) return erro("A nova senha precisa ser diferente da atual.");
  await prisma.usuarios.update({ where: { id: u.id }, data: { senha_hash: await bcrypt.hash(nova, 10) } });
  await prisma.acessos.create({ data: { user_id: u.id, email: u.email, evento: "senha_alterada" } }).catch(() => {});
  return ok({ ok: true });
}
