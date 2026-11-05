import { promises as fs } from "fs";
import path from "path";
import { del as blobDel, get as blobGet, list as blobList, put as blobPut } from "@vercel/blob";
import { comUsuario } from "./db";

/**
 * Backups na nuvem (tela Segurança): um arquivo JSON por backup, em backups/<espaço>/<nome>.
 *  - "blob": Vercel Blob privado, usado na Vercel (a ligação do Blob com o projeto cria BLOB_STORE_ID;
 *    ligações antigas criam BLOB_READ_WRITE_TOKEN; as duas funcionam).
 *  - "local": pasta no disco, para testes no computador.
 */
const NOME_RE = /^backup-[0-9-]{10}-[0-9]{10,16}\.json$/;
const WS_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
export const nomeValido = (n: string) => NOME_RE.test(n);
export const espacoValido = (w: string) => WS_RE.test(w);

type Modo = "blob" | "local";
function modo(): Modo {
  if (process.env.BLOB_STORE_ID || process.env.BLOB_READ_WRITE_TOKEN) return "blob";
  if (process.env.VERCEL) throw new Error("Armazenamento não configurado: conecte um Vercel Blob ao projeto (Storage → Blob) e publique de novo.");
  return "local";
}
const ROOT = path.resolve(process.env.UPLOAD_DIR ?? "./storage/backups");
const chave = (ws: string, nome: string) => `backups/${ws}/${nome}`;

/** O banco confere se quem está logado pode ver (ou gravar, com gravar=true) os backups do espaço. */
export async function podeEspaco(uid: string, ws: string, gravar: boolean) {
  if (!espacoValido(ws)) return false;
  return !!(await comUsuario(uid, async (c) => (await c.query("select public.pode_espaco($1::uuid, $2) as ok", [ws, gravar])).rows[0]?.ok));
}

export type ItemBackup = { name: string; created_at: string; metadata: { size: number } };

export async function listar(ws: string): Promise<ItemBackup[]> {
  if (modo() === "blob") {
    const itens: ItemBackup[] = [];
    let cursor: string | undefined;
    do {
      const r = await blobList({ prefix: `backups/${ws}/`, cursor, limit: 1000 });
      for (const b of r.blobs) itens.push({ name: b.pathname.split("/").pop()!, created_at: b.uploadedAt.toISOString(), metadata: { size: b.size } });
      cursor = r.hasMore ? r.cursor : undefined;
    } while (cursor);
    return itens.sort((a, b) => b.created_at.localeCompare(a.created_at));
  }
  const dir = path.join(ROOT, ws);
  const nomes = await fs.readdir(dir).catch(() => [] as string[]);
  const itens = await Promise.all(nomes.filter(nomeValido).map(async (n) => {
    const s = await fs.stat(path.join(dir, n));
    return { name: n, created_at: s.mtime.toISOString(), metadata: { size: s.size } };
  }));
  return itens.sort((a, b) => b.created_at.localeCompare(a.created_at));
}

export async function salvar(ws: string, nome: string, conteudo: string) {
  if (modo() === "blob") {
    await blobPut(chave(ws, nome), conteudo, { access: "private", contentType: "application/json", addRandomSuffix: false, allowOverwrite: false });
    return;
  }
  await fs.mkdir(path.join(ROOT, ws), { recursive: true });
  await fs.writeFile(path.join(ROOT, ws, nome), conteudo, { mode: 0o600, flag: "wx" });
}

export async function abrir(ws: string, nome: string): Promise<ReadableStream | Buffer | null> {
  if (modo() === "blob") {
    const r = await blobGet(chave(ws, nome), { access: "private", useCache: false }).catch(() => null);
    return r && r.statusCode === 200 ? r.stream : null;
  }
  return fs.readFile(path.join(ROOT, ws, nome)).catch(() => null);
}

export async function apagar(ws: string, nome: string) {
  if (modo() === "blob") await blobDel(chave(ws, nome));
  else await fs.rm(path.join(ROOT, ws, nome), { force: true });
}
