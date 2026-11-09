-- Pagamento parcial: quanto já foi pago de uma despesa ou conta a pagar que ainda não foi quitada.
-- Vazio (null) = nada pago ainda. Quando o item fica "Pago", vale o valor inteiro.
alter table public.lancamentos add column if not exists "valorPago" numeric;
alter table public."contasPagar" add column if not exists "valorPago" numeric;
