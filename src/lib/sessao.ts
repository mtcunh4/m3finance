import { NextRequest, NextResponse } from "next/server";
import { getToken } from "next-auth/jwt";
import { prisma } from "./prisma";

export type Usuario = { id: string; email: string; nome: string };

/** Usuário da sessão, conferido no banco (ativo). */
export async function usuarioDaRequisicao(req: NextRequest): Promise<Usuario | null> {
  const token = await getToken({ req, secret: process.env.NEXTAUTH_SECRET });
  if (!token?.sub) return null;
  const u = await prisma.usuarios.findUnique({ where: { id: token.sub } }).catch(() => null);
  if (!u || !u.ativo) return null;
  return { id: u.id, email: u.email, nome: u.nome };
}

/** Pedidos que mudam dados precisam vir do próprio site (proteção contra envio de outro site). */
export function mesmaOrigem(req: NextRequest) {
  const origem = req.headers.get("origin");
  if (!origem) return true;
  try {
    return new URL(origem).host === (req.headers.get("x-forwarded-host") ?? req.headers.get("host"));
  } catch {
    return false;
  }
}

export const erro = (msg: string, status = 400) => NextResponse.json({ erro: msg }, { status, headers: { "Cache-Control": "no-store" } });
export const ok = (dados: unknown) => NextResponse.json(dados ?? null, { headers: { "Cache-Control": "no-store" } });

/** Traduz os erros levantados pelas funções do banco para mensagens ao usuário. */
export function erroDoBanco(e: unknown) {
  const x = e as { code?: string; message?: string };
  if (x.code === "42501") return erro(x.message || "Você não tem permissão para isso.", 403);
  if (x.code === "P0001") return erro(x.message || "Não foi possível concluir.");
  if (x.code === "22P02" || x.code === "22007" || x.code === "22008" || x.code === "22003") return erro("Algum valor informado é inválido (data ou número). Confira e tente de novo.");
  if (x.code === "23514") return erro("Algum campo tem um valor que não é aceito. Confira e tente de novo.");
  console.error("banco", e);
  return erro("Não foi possível concluir. Tente de novo.", 500);
}
