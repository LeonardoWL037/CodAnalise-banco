create or replace function pagamento_aula()
returns trigger as $$


DECLARE
saldao NUMERIC (10,2);
saldopendente NUMERIC (10,2);
curs CURSOR for select cast(vl_pago as double precision) from public.pagamento where public.pagamento.id = new.pagamento_id;
curspendente CURSOR for select SUM(cast(vl_pago as double precision)) from public.pagamento, public.aula where public.pagamento.id = public.aula.pagamento_id and public.pagamento.mentor_pag_id = new.id_mentor and public.aula.conf_mentor = false and public.aula.conf_usuario = false; 
Begin
open curs;
open curspendente;
fetch curs into saldao;
fetch curspendente into saldopendente;
close curs;
close curspendente;
if new.conf_mentor and new.conf_usuario and Not Exists(select mentor_id from carteira where mentor_id = new.id_mentor) then
insert into public.carteira(mentor_id,saldo,saldo_pendente) values(new.id_mentor, saldao * 0.85 , saldopendente * 0.85);
update public.postagem set estado = 'RESOLVIDO' from 
(select public.postagem.estado from public.postagem , public.proposta , public.aula, public.pagamento 
where new.pagamento_id = public.pagamento.id and public.pagamento.proposta_id = public.proposta.id and public.proposta.postagem_id = public.postagem.id) as estado;
return null;

elsif new.conf_mentor = false or new.conf_usuario = false then
update public.carteira set saldo_pendente = saldopendente;
return null;

elsif new.conf_mentor and new.conf_usuario then
update public.carteira set saldo = (saldo + (saldao * 0.85)) , saldo_pendente = (saldopendente * 0.85);
update public.postagem set estado = 'RESOLVIDO' from 
(select public.postagem.estado from public.postagem , public.proposta , public.aula, public.pagamento 
where new.pagamento_id = public.pagamento.id and public.pagamento.proposta_id = public.proposta.id and public.proposta.postagem_id = public.postagem.id) as estado;

return null;

else
return null;

end if;
END;

$$ language 'plpgsql';


	CREATE TRIGGER trg_carteira
    AFTER INSERT OR UPDATE 
    ON public.aula
    FOR EACH ROW
    EXECUTE FUNCTION public.pagamento_aula();