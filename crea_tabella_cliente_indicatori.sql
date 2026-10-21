/* ==========================================================================
   INDICATORI PER CLIENTE - database banca
   --------------------------------------------------------------------------
   Risultato: la tabella cliente_indicatori, con UNA riga per cliente.

   Prerequisito: il database banca deve essere già caricato (tabelle cliente,
   conto, tipo_conto, transazioni, tipo_transazione). Lo script si può
   rieseguire: ogni oggetto viene eliminato e ricreato.

   Come è costruito: invece di un'unica query, il lavoro è diviso in blocchi.
   Ogni blocco calcola un gruppo di indicatori e produce UNA riga per cliente:

       blocco 1  ->  v_cliente_conti                          (quanti conti)
       blocco 2  ->  v_cliente_transazioni                    (quante transazioni, quanto denaro)
       blocco 3  ->  v_cliente_transazioni_per_tipo_conto     (come blocco 2, per tipologia di conto)
       blocco 4  ->  creazione della tabella finale
       blocco 5  ->  unione dei blocchi 1-3 e popolamento della tabella

   Poiché ogni blocco ha una riga per cliente, unirli nel blocco 5 non
   moltiplica le righe: è questo che evita il problema dei conti contati più
   volte (un conto compare una volta per ogni sua transazione).

   Convenzioni usate nei nomi delle colonne:
       numero_...   = conteggio
       importo_...  = somma di denaro
       ..._uscita   = transazioni con segno '-' in tipo_transazione
       ..._entrata  = transazioni con segno '+' in tipo_transazione
       ..._conto_X  = limitato ai conti di tipologia X (base, business, privati, famiglie)
   Nota: nel db gli importi in uscita sono già negativi, quindi
   importo_transazioni_uscita* è un numero negativo. Le somme degli importi
   sono arrotondate a 2 decimali.
   ========================================================================== */

USE banca;


/* --------------------------------------------------------------------------
   PULIZIA: elimina la tabella e le viste di una eventuale esecuzione precedente
   -------------------------------------------------------------------------- */
DROP TABLE IF EXISTS cliente_indicatori;
DROP VIEW  IF EXISTS v_cliente_conti;
DROP VIEW  IF EXISTS v_cliente_transazioni;
DROP VIEW  IF EXISTS v_cliente_transazioni_per_tipo_conto;


/* --------------------------------------------------------------------------
   BLOCCO 1 - INDICATORI SUI CONTI
   Una riga per ogni cliente che possiede almeno un conto.
     numero_conti_totale   = quanti conti possiede il cliente
     numero_conti_<tipo>   = quanti di questi conti sono di quella tipologia
   Qui le transazioni non entrano: contare i conti partendo dalla sola tabella
   conto evita ogni duplicazione, quindi basta un COUNT semplice.
   -------------------------------------------------------------------------- */
CREATE VIEW v_cliente_conti AS
SELECT
    co.id_cliente,
    COUNT(co.id_conto) AS numero_conti_totale,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Base' THEN 1 ELSE 0 END) AS numero_conti_base,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Business' THEN 1 ELSE 0 END) AS numero_conti_business,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Privati' THEN 1 ELSE 0 END) AS numero_conti_privati,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Famiglie' THEN 1 ELSE 0 END) AS numero_conti_famiglie
FROM conto co
LEFT JOIN tipo_conto tc ON tc.id_tipo_conto = co.id_tipo_conto
GROUP BY co.id_cliente;


/* --------------------------------------------------------------------------
   BLOCCO 2 - INDICATORI SULLE TRANSAZIONI (TUTTI I CONTI DEL CLIENTE)
   Una riga per ogni cliente che ha almeno una transazione.
     numero_transazioni_uscita / _entrata    = quante transazioni con segno '-' / '+'
     importo_transazioni_uscita / _entrata   = somma degli importi di quelle transazioni
   Il legame è cliente -> conto -> transazioni; il segno si legge da tipo_transazione.
   -------------------------------------------------------------------------- */
CREATE VIEW v_cliente_transazioni AS
SELECT
    co.id_cliente,
    SUM(CASE WHEN tt.segno = '-' THEN 1 ELSE 0 END)          AS numero_transazioni_uscita,
    SUM(CASE WHEN tt.segno = '+' THEN 1 ELSE 0 END)          AS numero_transazioni_entrata,
    ROUND(SUM(CASE WHEN tt.segno = '-' THEN t.importo ELSE 0 END), 2)  AS importo_transazioni_uscita,
    ROUND(SUM(CASE WHEN tt.segno = '+' THEN t.importo ELSE 0 END), 2)  AS importo_transazioni_entrata
FROM conto co
JOIN transazioni t        ON t.id_conto = co.id_conto
JOIN tipo_transazione tt  ON tt.id_tipo_transazione = t.id_tipo_trans
GROUP BY co.id_cliente;


/* --------------------------------------------------------------------------
   BLOCCO 3 - INDICATORI SULLE TRANSAZIONI, PER TIPOLOGIA DI CONTO
   Una riga per ogni cliente che ha almeno una transazione.
   Stesse quattro misure del blocco 2 (numero e importo, in uscita e in entrata),
   ma ripetute per ciascuna delle 4 tipologie di conto: 16 colonne, una per ogni
   combinazione misura x tipologia. Ogni colonna conta solo le transazioni dei
   conti di quella tipologia (la tipologia si legge da tipo_conto).
   -------------------------------------------------------------------------- */
CREATE VIEW v_cliente_transazioni_per_tipo_conto AS
SELECT
    co.id_cliente,
    /* numero di transazioni in uscita (segno '-') sui conti di quella tipologia */
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Base' AND tt.segno = '-' THEN 1 ELSE 0 END) AS numero_transazioni_uscita_conto_base,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Business' AND tt.segno = '-' THEN 1 ELSE 0 END) AS numero_transazioni_uscita_conto_business,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Privati' AND tt.segno = '-' THEN 1 ELSE 0 END) AS numero_transazioni_uscita_conto_privati,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Famiglie' AND tt.segno = '-' THEN 1 ELSE 0 END) AS numero_transazioni_uscita_conto_famiglie,
    /* numero di transazioni in entrata (segno '+') sui conti di quella tipologia */
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Base' AND tt.segno = '+' THEN 1 ELSE 0 END) AS numero_transazioni_entrata_conto_base,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Business' AND tt.segno = '+' THEN 1 ELSE 0 END) AS numero_transazioni_entrata_conto_business,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Privati' AND tt.segno = '+' THEN 1 ELSE 0 END) AS numero_transazioni_entrata_conto_privati,
    SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Famiglie' AND tt.segno = '+' THEN 1 ELSE 0 END) AS numero_transazioni_entrata_conto_famiglie,
    /* somma degli importi in uscita sui conti di quella tipologia (negativi) */
    ROUND(SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Base' AND tt.segno = '-' THEN t.importo ELSE 0 END), 2) AS importo_transazioni_uscita_conto_base,
    ROUND(SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Business' AND tt.segno = '-' THEN t.importo ELSE 0 END), 2) AS importo_transazioni_uscita_conto_business,
    ROUND(SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Privati' AND tt.segno = '-' THEN t.importo ELSE 0 END), 2) AS importo_transazioni_uscita_conto_privati,
    ROUND(SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Famiglie' AND tt.segno = '-' THEN t.importo ELSE 0 END), 2) AS importo_transazioni_uscita_conto_famiglie,
    /* somma degli importi in entrata sui conti di quella tipologia (positivi) */
    ROUND(SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Base' AND tt.segno = '+' THEN t.importo ELSE 0 END), 2) AS importo_transazioni_entrata_conto_base,
    ROUND(SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Business' AND tt.segno = '+' THEN t.importo ELSE 0 END), 2) AS importo_transazioni_entrata_conto_business,
    ROUND(SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Privati' AND tt.segno = '+' THEN t.importo ELSE 0 END), 2) AS importo_transazioni_entrata_conto_privati,
    ROUND(SUM(CASE WHEN tc.desc_tipo_conto = 'Conto Famiglie' AND tt.segno = '+' THEN t.importo ELSE 0 END), 2) AS importo_transazioni_entrata_conto_famiglie
FROM conto co
JOIN tipo_conto tc        ON tc.id_tipo_conto = co.id_tipo_conto
JOIN transazioni t        ON t.id_conto = co.id_conto
JOIN tipo_transazione tt  ON tt.id_tipo_transazione = t.id_tipo_trans
GROUP BY co.id_cliente;


/* --------------------------------------------------------------------------
   BLOCCO 4 - STRUTTURA DELLA TABELLA FINALE
   Una riga per cliente, chiave primaria id_cliente. I conteggi sono interi, gli
   importi hanno 2 decimali. Le colonne non ammettono NULL: dove un cliente non
   ha dati (per esempio nessun conto) il valore è 0.
   -------------------------------------------------------------------------- */
CREATE TABLE cliente_indicatori (
    id_cliente INT NOT NULL,
    nome VARCHAR(100),
    cognome VARCHAR(100),
    data_nascita DATE,
    eta INT,
    numero_conti_totale INT NOT NULL,
    numero_conti_base INT NOT NULL,
    numero_conti_business INT NOT NULL,
    numero_conti_privati INT NOT NULL,
    numero_conti_famiglie INT NOT NULL,
    numero_transazioni_uscita INT NOT NULL,
    numero_transazioni_entrata INT NOT NULL,
    importo_transazioni_uscita DECIMAL(15,2) NOT NULL,
    importo_transazioni_entrata DECIMAL(15,2) NOT NULL,
    numero_transazioni_uscita_conto_base INT NOT NULL,
    numero_transazioni_uscita_conto_business INT NOT NULL,
    numero_transazioni_uscita_conto_privati INT NOT NULL,
    numero_transazioni_uscita_conto_famiglie INT NOT NULL,
    numero_transazioni_entrata_conto_base INT NOT NULL,
    numero_transazioni_entrata_conto_business INT NOT NULL,
    numero_transazioni_entrata_conto_privati INT NOT NULL,
    numero_transazioni_entrata_conto_famiglie INT NOT NULL,
    importo_transazioni_uscita_conto_base DECIMAL(15,2) NOT NULL,
    importo_transazioni_uscita_conto_business DECIMAL(15,2) NOT NULL,
    importo_transazioni_uscita_conto_privati DECIMAL(15,2) NOT NULL,
    importo_transazioni_uscita_conto_famiglie DECIMAL(15,2) NOT NULL,
    importo_transazioni_entrata_conto_base DECIMAL(15,2) NOT NULL,
    importo_transazioni_entrata_conto_business DECIMAL(15,2) NOT NULL,
    importo_transazioni_entrata_conto_privati DECIMAL(15,2) NOT NULL,
    importo_transazioni_entrata_conto_famiglie DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (id_cliente)
);


/* --------------------------------------------------------------------------
   BLOCCO 5 - POPOLAMENTO: UNIONE DEI BLOCCHI
   Si parte da TUTTI i clienti (tabella cliente) e si collegano le tre viste con
   LEFT JOIN su id_cliente. Il LEFT JOIN mantiene anche i clienti senza conti o
   senza transazioni; per loro le viste non hanno riga, quindi i valori sono NULL.
   Ogni colonna proveniente dalle viste passa da un CASE WHEN che, se il valore
   è NULL, lo sostituisce con 0 (CASE WHEN x IS NULL THEN 0 ELSE x END): la stessa
   regola è applicata a tutte le colonne, così la tabella contiene solo numeri.
   -------------------------------------------------------------------------- */
INSERT INTO cliente_indicatori (
    id_cliente,
    nome,
    cognome,
    data_nascita,
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
    numero_transazioni_uscita_conto_base,
    numero_transazioni_uscita_conto_business,
    numero_transazioni_uscita_conto_privati,
    numero_transazioni_uscita_conto_famiglie,
    numero_transazioni_entrata_conto_base,
    numero_transazioni_entrata_conto_business,
    numero_transazioni_entrata_conto_privati,
    numero_transazioni_entrata_conto_famiglie,
    importo_transazioni_uscita_conto_base,
    importo_transazioni_uscita_conto_business,
    importo_transazioni_uscita_conto_privati,
    importo_transazioni_uscita_conto_famiglie,
    importo_transazioni_entrata_conto_base,
    importo_transazioni_entrata_conto_business,
    importo_transazioni_entrata_conto_privati,
    importo_transazioni_entrata_conto_famiglie
)
SELECT
    /* anagrafica e età (differenza tra anno corrente e anno di nascita) */
    c.id_cliente,
    c.nome,
    c.cognome,
    c.data_nascita,
    YEAR(CURRENT_DATE()) - YEAR(c.data_nascita),
    /* indicatori sui conti (blocco 1) */
    CASE WHEN vc.numero_conti_totale IS NULL THEN 0 ELSE vc.numero_conti_totale END,
    CASE WHEN vc.numero_conti_base IS NULL THEN 0 ELSE vc.numero_conti_base END,
    CASE WHEN vc.numero_conti_business IS NULL THEN 0 ELSE vc.numero_conti_business END,
    CASE WHEN vc.numero_conti_privati IS NULL THEN 0 ELSE vc.numero_conti_privati END,
    CASE WHEN vc.numero_conti_famiglie IS NULL THEN 0 ELSE vc.numero_conti_famiglie END,
    /* indicatori sulle transazioni, tutti i conti (blocco 2) */
    CASE WHEN vt.numero_transazioni_uscita IS NULL THEN 0 ELSE vt.numero_transazioni_uscita END,
    CASE WHEN vt.numero_transazioni_entrata IS NULL THEN 0 ELSE vt.numero_transazioni_entrata END,
    CASE WHEN vt.importo_transazioni_uscita IS NULL THEN 0 ELSE vt.importo_transazioni_uscita END,
    CASE WHEN vt.importo_transazioni_entrata IS NULL THEN 0 ELSE vt.importo_transazioni_entrata END,
    /* indicatori sulle transazioni per tipologia di conto (blocco 3) */
    CASE WHEN vp.numero_transazioni_uscita_conto_base IS NULL THEN 0 ELSE vp.numero_transazioni_uscita_conto_base END,
    CASE WHEN vp.numero_transazioni_uscita_conto_business IS NULL THEN 0 ELSE vp.numero_transazioni_uscita_conto_business END,
    CASE WHEN vp.numero_transazioni_uscita_conto_privati IS NULL THEN 0 ELSE vp.numero_transazioni_uscita_conto_privati END,
    CASE WHEN vp.numero_transazioni_uscita_conto_famiglie IS NULL THEN 0 ELSE vp.numero_transazioni_uscita_conto_famiglie END,
    CASE WHEN vp.numero_transazioni_entrata_conto_base IS NULL THEN 0 ELSE vp.numero_transazioni_entrata_conto_base END,
    CASE WHEN vp.numero_transazioni_entrata_conto_business IS NULL THEN 0 ELSE vp.numero_transazioni_entrata_conto_business END,
    CASE WHEN vp.numero_transazioni_entrata_conto_privati IS NULL THEN 0 ELSE vp.numero_transazioni_entrata_conto_privati END,
    CASE WHEN vp.numero_transazioni_entrata_conto_famiglie IS NULL THEN 0 ELSE vp.numero_transazioni_entrata_conto_famiglie END,
    CASE WHEN vp.importo_transazioni_uscita_conto_base IS NULL THEN 0 ELSE vp.importo_transazioni_uscita_conto_base END,
    CASE WHEN vp.importo_transazioni_uscita_conto_business IS NULL THEN 0 ELSE vp.importo_transazioni_uscita_conto_business END,
    CASE WHEN vp.importo_transazioni_uscita_conto_privati IS NULL THEN 0 ELSE vp.importo_transazioni_uscita_conto_privati END,
    CASE WHEN vp.importo_transazioni_uscita_conto_famiglie IS NULL THEN 0 ELSE vp.importo_transazioni_uscita_conto_famiglie END,
    CASE WHEN vp.importo_transazioni_entrata_conto_base IS NULL THEN 0 ELSE vp.importo_transazioni_entrata_conto_base END,
    CASE WHEN vp.importo_transazioni_entrata_conto_business IS NULL THEN 0 ELSE vp.importo_transazioni_entrata_conto_business END,
    CASE WHEN vp.importo_transazioni_entrata_conto_privati IS NULL THEN 0 ELSE vp.importo_transazioni_entrata_conto_privati END,
    CASE WHEN vp.importo_transazioni_entrata_conto_famiglie IS NULL THEN 0 ELSE vp.importo_transazioni_entrata_conto_famiglie END
FROM cliente c
LEFT JOIN v_cliente_conti                        vc ON vc.id_cliente = c.id_cliente
LEFT JOIN v_cliente_transazioni                  vt ON vt.id_cliente = c.id_cliente
LEFT JOIN v_cliente_transazioni_per_tipo_conto   vp ON vp.id_cliente = c.id_cliente
ORDER BY c.id_cliente;


/* --------------------------------------------------------------------------
   CONTROLLO FINALE
   Confronta i totali della tabella con quelli delle tabelle di origine: ogni
   coppia di colonne (_attesi / _in_tabella) deve avere lo stesso valore.
   -------------------------------------------------------------------------- */
SELECT
    (SELECT COUNT(*) FROM cliente)                                   AS clienti_attesi,
    COUNT(*)                                                         AS clienti_in_tabella,
    (SELECT COUNT(*) FROM conto)                                     AS conti_attesi,
    SUM(numero_conti_totale)                                         AS conti_in_tabella,
    (SELECT COUNT(*) FROM transazioni)                               AS transazioni_attese,
    SUM(numero_transazioni_uscita + numero_transazioni_entrata)      AS transazioni_in_tabella
FROM cliente_indicatori;
