# Olist – Analisi E-Commerce (SQL + Power BI)

Progetto di data analysis sviluppato sul dataset pubblico **Olist Brazilian E-Commerce**, disponibile su Kaggle:
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
**Olist** raccoglie circa **100.000 ordini reali** effettuati tra il **2016 e il 2018** su diversi marketplace in Brasile, consentendo l'analisi degli ordini da molteplici prospettive: stato e tempi di consegna, prezzi, pagamenti, costi di spedizione, localizzazione dei clienti e recensioni. 
L’obiettivo è costruire una pipeline analitica in **PostgreSQL** e una dashboard **Power BI** chiara e utilizzabile in contesti aziendali reali.


## Obiettivi
- Modellare i dati esclusivamente con **SQL**: pulizia e aggregazione
- Definire KPI chiari e riutilizzabili nel tempo
- Separare  **logica dati (SQL)** e **presentazione (Power BI)** per ridurre errori e ambiguità
- Creare una dashboard orientata a decisioni di business e al monitoraggio delle performance aziendali


## Tecnologie
- **PostgreSQL 17**
- **Power BI**
- Windows 11


## Struttura del progetto
```
Olist_Project/
├── data_kaggle/   # File CSV originali del dataset (non inclusi nel repository)
├── sql/           # Pipeline SQL completa: trasformazioni, analisi, KPI e controlli qualità
├── powerbi/       # Cartella progetto Power BI (file .pbix disponibile tramite link esterno)
├── docs/
│   ├── Olist_Ecommerce_Analysis.pdf    # Esportazione PDF del report
│   ├── powerbi_model.png               # Screenshot modello dati (Model View)
│   ├── dashboard_executive.png         # Screenshot pagina Executive Overview
│   └── dashboard_ordini_logistica.png  # Screenshot pagina Ordini & Logistica
├── README.md      # Documentazione principale (English)
└── README_IT.md   # Documentazione in italiano

```


## Architettura SQL
Pipeline strutturata e ordinata:
- **Schema e basi** → `00_schema.sql`, `00_grezzi_calcoli.sql`
- **Analisi tematiche** → clienti, ordini, prodotti, recensioni e seller
- **KPI executive** → `06_kpi_master.sql`
- **Controlli qualità** → `07_quality_checks.sql`

Tutti i KPI sono **calcolati e definiti in SQL**.


## Modello dati (Power BI)
![Power BI Data Model](docs/powerbi_model.png)

- **Fact centrale**: ordini e logistica
- **Tabelle satellite**: clienti, pagamenti e recensioni
- **Viste KPI**: pre-aggregate in SQL e **scollegate intenzionalmente** dal modello relazionale

Scelta progettuale per evitare:
- ambiguità di filtro
- duplicazioni logiche
- ricalcoli in DAX


## Dashboard Power BI
Il report include:
- KPI executive
- Performance di ordini e logistica
- Analisi clienti e retention
- Analisi prodotti e categorie
- Qualità delle recensioni
- Struttura e modalità di pagamento

### Executive Overview
![Executive Overview](docs/dashboard_executive.png)

### Ordini e Logistica
![Ordini e Logistica](docs/dashboard_ordini_logistica.png)


Il report Power BI (.pbix) è scaricabile qui:  
[Scarica il file .pbix](https://drive.google.com/file/d/1YlEaOZDN1PlhQirBrGQY6uF79nOnb64R/view?usp=drive_link)

Una versione statica in PDF del report è disponibile nella cartella `docs/`.


## Riproducibilità
1. Creare un database PostgreSQL 17 
2. Importare i file CSV del dataset Olist nella cartella `data_kaggle/`
3. Eseguire gli script SQL in ordine numerico (00 → 07)  
4. Collegare Power BI al database PostgreSQL  
5. Scaricare il file .pbix dal link sopra e aprirlo in Power BI Desktop


## Note
- Il dataset non è incluso nel repository
- Progetto pensato per **portfolio professionale**
