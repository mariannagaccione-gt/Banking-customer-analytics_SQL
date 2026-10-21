/* 
INDICATORI PER CLIENTE - database banca
--------------------------------------------------------------------------
Prerequisito: il database banca deve essere già caricato (tabelle cliente, conto, tipo_conto, transazioni,
tipo_transazione). Lo script si può rieseguire: ogni oggetto viene eliminato e ricreato.*/
   
drop view if exists banca.v_cliente_conti;
drop view if exists banca.v_cliente_transazioni;
drop view if exists banca.v_cliente_transazioni_per_tipo_conto;
drop table if exists banca.cliente_indicatori;

  /* Il lavoro è diviso in blocchi, ogni blocco parte dalla tabella cliente, collega le altre tabelle
con LEFT JOIN(che conserva tutte le righe di cliente, anche senza conti o senza transazioni)
e produce una riga per ogni cliente in anagrafica:

 blocco 1  ->  v_cliente_conti                        (quanti conti tot, quanti conti per tipologia)
 blocco 2  ->  v_cliente_transazioni                  (quante transazioni, importo transato)
 blocco 3  ->  v_cliente_transazioni_per_tipo_conto   (come blocco 2 ma per tipologia di conto)
 blocco 4  ->  creazione della tabella finale
 blocco 5  ->  unione dei blocchi 1,2, e 3 e popolamento della tabella
-----------------------------------------------------------------------------------------------------*/
       
       
/*-----------------------------------------------------------------------------------------------------
BLOCCO 1 - INDICATORI SUI CONTI
Conteggio dei conti per cliente e calcolo, per ciscun cliente, dei conti per tipologia
crendo una colonna per tipologia di conto (chi non possiede un certo tipo di conto assume valore 0)
-----------------------------------------------------------------------------------------------------*/

create view banca.v_cliente_conti as
select cl.id_cliente,
count(co.id_conto) as numero_conti_totale,
sum(case when tc.desc_tipo_conto='Conto Base' then 1 else 0 end) as numero_conti_Base,
sum(case when tc.desc_tipo_conto='Conto Business' then 1 else 0 end) as numero_conti_Business,
sum(case when tc.desc_tipo_conto='Conto Privati' then 1 else 0 end) as numero_conti_Privati,
sum(case when tc.desc_tipo_conto='Conto Famiglie' then 1 else 0 end) as numero_conti_Famiglie
from banca.cliente cl
left join banca.conto co
on cl.id_cliente=co.id_cliente
left join banca.tipo_conto tc
on co.id_tipo_conto=tc.id_tipo_conto
group by cl.id_cliente;

/*-----------------------------------------------------------------------------------------------------
BLOCCO 2 - INDICATORI SULLE TRANSAZIONI (TUTTI I CONTI DEL CLIENTE)
Per ciscun cliente, calcolo del totale transazioni in entrata e in uscita, e del totale transato in 
entrata e in uscita arrotondato a 2 cifre decimali (chi non ha effettuato transazioni in generale o di un certo tipo assume valore 0)
-----------------------------------------------------------------------------------------------------*/

create view banca.v_cliente_transazioni as
select cl.id_cliente,
sum(case when tt.segno='-' then 1 else 0 end) as numero_transazioni_uscita,
sum(case when tt.segno='+' then 1 else 0 end) as numero_transazioni_entrata,
ROUND(sum(case when tt.segno='-'then tr.importo else 0 end),2) as importo_transazioni_uscita,
ROUND(sum(case when tt.segno='+'then tr.importo else 0 end),2) as importo_transazioni_entrata
from banca.cliente cl
left join banca.conto co
on cl.id_cliente=co.id_cliente
left join banca.transazioni tr
on co.id_conto=tr.id_conto
left join banca.tipo_transazione tt
on tr.id_tipo_trans=tt.id_tipo_transazione
group by cl.id_cliente
order by 1 asc;

/*-----------------------------------------------------------------------------------------------------
BLOCCO 3 - INDICATORI SULLE TRANSAZIONI, PER TIPOLOGIA DI CONTO
Per ciscun cliente, calcolo del: 
numero di transazioni in uscita e in entrata per ogni tipologia di conto;
importo totale transato in uscita e in entrata per ogni tipologia di conto (arrotondato a 2 cifre decimali)
(chi non ha effettuato transazioni in generale o di un certo tipo assume valore 0).
-----------------------------------------------------------------------------------------------------*/

/*numero di transazioni in uscita per tipologia di conto */
create view banca.v_cliente_transazioni_per_tipo_conto as
select cl.id_cliente,
sum(case when tc.desc_tipo_conto ='Conto Base' and tt.segno='-' then 1 else 0 end) as numero_trans_uscita_conto_base,
sum(case when tc.desc_tipo_conto ='Conto Business' and tt.segno='-' then 1 else 0 end) as numero_trans_uscita_conto_business,
sum(case when tc.desc_tipo_conto ='Conto Privati' and tt.segno='-' then 1 else 0 end) as numero_trans_uscita_conto_privati,
sum(case when tc.desc_tipo_conto ='Conto Famiglie' and tt.segno='-' then 1 else 0 end) as numero_trans_uscita_conto_famiglie,
    
/*numero di transazioni in entrata per tipologia di conto */
sum(case when tc.desc_tipo_conto ='Conto Base' and tt.segno='+' then 1 else 0 end) as numero_trans_entrata_conto_base,
sum(case when tc.desc_tipo_conto ='Conto Business' and tt.segno='+' then 1 else 0 end) as numero_trans_entrata_conto_business,
sum(case when tc.desc_tipo_conto ='Conto Privati' and tt.segno='+' then 1 else 0 end) as numero_trans_entrata_conto_privati,
sum(case when tc.desc_tipo_conto ='Conto Famiglie' and tt.segno='+' then 1 else 0 end) as numero_trans_entrata_conto_famiglie,
    
/*Importo transato in uscita per tiologia di conto */
round(sum(case when tt.segno='-' and tc.desc_tipo_conto ='Conto Base' then tr.importo else 0 end),2) as importo_trans_uscita_Conto_Base,
round(sum(case when tt.segno='-' and tc.desc_tipo_conto ='Conto Business' then tr.importo else 0 end),2) as importo_trans_uscita_Conto_Business,
round(sum(case when tt.segno='-' and tc.desc_tipo_conto ='Conto Privati' then tr.importo else 0 end),2) as importo_trans_uscita_Conto_Privati,
round(sum(case when tt.segno='-' and tc.desc_tipo_conto ='Conto Famiglie' then tr.importo else 0 end),2) as importo_trans_uscita_Conto_Famiglie,

/*Importo transato in entrata per tiologia di conto */
round(sum(case when tt.segno='+' and tc.desc_tipo_conto ='Conto Base' then tr.importo else 0 end),2) as importo_trans_entrata_Conto_Base,
round(sum(case when tt.segno='+' and tc.desc_tipo_conto ='Conto Business' then tr.importo else 0 end),2) as importo_trans_entrata_Conto_Business,
round(sum(case when tt.segno='+' and tc.desc_tipo_conto ='Conto Privati' then tr.importo else 0 end),2) as importo_trans_entrata_Conto_Privati,
round(sum(case when tt.segno='+' and tc.desc_tipo_conto ='Conto Famiglie' then tr.importo else 0 end),2) as importo_trans_entrata_Conto_Famiglie

from banca.cliente cl
left join banca.conto co
on cl.id_cliente=co.id_cliente
left join banca.tipo_conto tc
on co.id_tipo_conto=tc.id_tipo_conto
left join banca.transazioni tr
on co.id_conto=tr.id_conto
left join banca.tipo_transazione tt
on tr.id_tipo_trans=tt.id_tipo_transazione
group by cl.id_cliente
order by 1 asc;

/* --------------------------------------------------------------------------
 BLOCCO 4 - STRUTTURA DELLA TABELLA FINALE
Una riga per cliente. I conteggi sono interi, gli importi hanno 2 decimali.
   -------------------------------------------------------------------------- */
Create table banca.cliente_indicatori (
id_cliente int,
eta int,
numero_conti_totale int,
numero_conti_base int,
numero_conti_business int,
numero_conti_privati int,
numero_conti_famiglie int,
numero_transazioni_uscita int,
numero_transazioni_entrata int,
importo_transazioni_uscita decimal(15,2),
importo_transazioni_entrata decimal(15,2),
numero_trans_uscita_conto_base int,
numero_trans_uscita_conto_business int,
numero_trans_uscita_conto_privati int,
numero_trans_uscita_conto_famiglie int,
numero_trans_entrata_conto_base int,
numero_trans_entrata_conto_business int,
numero_trans_entrata_conto_privati int,
numero_trans_entrata_conto_famiglie int,
importo_trans_uscita_conto_base decimal(15,2),
importo_trans_uscita_conto_business decimal(15,2),
importo_trans_uscita_conto_privati decimal(15,2),
importo_trans_uscita_conto_famiglie decimal(15,2),
importo_trans_entrata_conto_base decimal(15,2),
importo_trans_entrata_conto_business decimal(15,2),
importo_trans_entrata_conto_privati decimal(15,2),
importo_trans_entrata_conto_famiglie decimal(15,2) 
);

/* --------------------------------------------------------------------------
BLOCCO 5 - POPOLAMENTO: UNIONE DEI BLOCCHI
A partire dalla tabella di anagrafica dei cienti, si collegano le tre viste con
LEFT JOIN su id_cliente, in modo da non eliminare alcun cliente. Le viste hanno già
una riga per ogni cliente, ma per maggiore sicurezza ogni colonna proveniente dalle viste
passa da un CASE WHEN che, se il valore è NULL, lo sostituisce con 0: la stessa regola è 
applicata a tutte le colonne, così la tabella contiene solo numeri e mai caselle vuote.
   -------------------------------------------------------------------------- */
insert into banca.cliente_indicatori (
id_cliente,
eta,
numero_conti_totale,
numero_conti_base,
numero_conti_business,
numero_conti_privati,
numero_conti_famiglie,
numero_transazioni_uscita,
numero_transazioni_entrata,
importo_transazioni_uscita,
importo_transazioni_entrata,
numero_trans_uscita_conto_base,
numero_trans_uscita_conto_business,
numero_trans_uscita_conto_privati,
numero_trans_uscita_conto_famiglie,
numero_trans_entrata_conto_base,
numero_trans_entrata_conto_business,
numero_trans_entrata_conto_privati,
numero_trans_entrata_conto_famiglie,
importo_trans_uscita_conto_base,
importo_trans_uscita_conto_business,
importo_trans_uscita_conto_privati,
importo_trans_uscita_conto_famiglie,
importo_trans_entrata_conto_base,
importo_trans_entrata_conto_business,
importo_trans_entrata_conto_privati,
importo_trans_entrata_conto_famiglie
)
select
c.id_cliente,

/* calcolo dell' età (differenza tra anno corrente e anno di nascita) */
year(current_date()) - year(c.data_nascita),

/* indicatori sui conti (blocco 1) */
case when vc.numero_conti_totale is null then 0 else vc.numero_conti_totale end,
case when vc.numero_conti_base is null then 0 else vc.numero_conti_base end,
case when vc.numero_conti_business is null then 0 else vc.numero_conti_business end,
case when vc.numero_conti_privati is null then 0 else vc.numero_conti_privati end,
case when vc.numero_conti_famiglie is null then 0 else vc.numero_conti_famiglie end,

/* indicatori sulle transazioni, tutti i conti (blocco 2) */
case when vt.numero_transazioni_uscita IS NULL THEN 0 ELSE vt.numero_transazioni_uscita end,
case when vt.numero_transazioni_entrata IS NULL THEN 0 ELSE vt.numero_transazioni_entrata end,
case when vt.importo_transazioni_uscita IS NULL THEN 0 ELSE vt.importo_transazioni_uscita end,
case when vt.importo_transazioni_entrata IS NULL THEN 0 ELSE vt.importo_transazioni_entrata end,

/* indicatori sulle transazioni per tipologia di conto (blocco 3) */
case when vp.numero_trans_uscita_conto_base is null then 0 else vp.numero_trans_uscita_conto_base end,
case when vp.numero_trans_uscita_conto_business is null then 0 else vp.numero_trans_uscita_conto_business end,
case when vp.numero_trans_uscita_conto_privati is null then 0 else vp.numero_trans_uscita_conto_privati end,
case when vp.numero_trans_uscita_conto_famiglie is null then 0 else vp.numero_trans_uscita_conto_famiglie end,
case when vp.numero_trans_entrata_conto_base is null then 0 else vp.numero_trans_entrata_conto_base end,
case when vp.numero_trans_entrata_conto_business is null then 0 else vp.numero_trans_entrata_conto_business end,
case when vp.numero_trans_entrata_conto_privati is null then 0 else vp.numero_trans_entrata_conto_privati end,
case when vp.numero_trans_entrata_conto_famiglie is null then 0 else vp.numero_trans_entrata_conto_famiglie end,
case when vp.importo_trans_uscita_conto_base is null then 0 else vp.importo_trans_uscita_conto_base end,
case when vp.importo_trans_uscita_conto_business is null then 0 else vp.importo_trans_uscita_conto_business end,
case when vp.importo_trans_uscita_conto_privati is null then 0 else vp.importo_trans_uscita_conto_privati end,
case when vp.importo_trans_uscita_conto_famiglie is null then 0 else vp.importo_trans_uscita_conto_famiglie end,
case when vp.importo_trans_entrata_conto_base is null then 0 else vp.importo_trans_entrata_conto_base end,
case when vp.importo_trans_entrata_conto_business is null then 0 else vp.importo_trans_entrata_conto_business end,
case when vp.importo_trans_entrata_conto_privati is null then 0 else vp.importo_trans_entrata_conto_privati end,
case when vp.importo_trans_entrata_conto_famiglie is null then 0 else vp.importo_trans_entrata_conto_famiglie end
from banca.cliente c
left join banca.v_cliente_conti vc on vc.id_cliente = c.id_cliente
left join banca.v_cliente_transazioni vt on vt.id_cliente = c.id_cliente
left join banca.v_cliente_transazioni_per_tipo_conto vp on vp.id_cliente = c.id_cliente
order by c.id_cliente asc;

/* --------------------------------------------------------------------------
   CONTROLLO FINALE
   Confronta i totali della tabella con quelli delle tabelle di origine: ogni
   coppia di colonne (_attesi / _in_tabella) deve avere lo stesso valore.
   -------------------------------------------------------------------------- */
select
    (select count(*) FROM banca.cliente) as clienti_attesi,
    count(*) as clienti_in_tabella,
    (select count(*) from conto) as conti_attesi,
    sum(numero_conti_totale) as conti_in_tabella,
    (select count(*) from transazioni) as transazioni_attese,
    sum(numero_transazioni_uscita + numero_transazioni_entrata) as transazioni_in_tabella
FROM cliente_indicatori;
