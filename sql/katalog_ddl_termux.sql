-- katalog shema za Termux cvorove (PostgreSQL 18.x, aarch64 Android)
-- Bez pgvector -- nije dostupan na Termuxu
-- Primjena: psql -U pgu -d balsam -f katalog_ddl_termux.sql

CREATE SCHEMA IF NOT EXISTS katalog;

CREATE TABLE katalog.cvorovi (
    id SERIAL PRIMARY KEY,
    ime VARCHAR(64) NOT NULL,
    tip VARCHAR(16) NOT NULL CHECK (tip IN ('balsam','termux','oci','gdrive','claude')),
    host VARCHAR(128),
    port INTEGER,
    status VARCHAR(16) DEFAULT 'aktivan' NOT NULL CHECK (status IN ('aktivan','neaktivan','degradiran')),
    biljeska TEXT,
    kreiran TIMESTAMPTZ DEFAULT now() NOT NULL,
    primarni_dns_id INTEGER
);

CREATE TABLE katalog.cvor_hardware (
    id SERIAL PRIMARY KEY,
    cvor_id INTEGER NOT NULL REFERENCES katalog.cvorovi(id),
    os VARCHAR(64),
    arhitektura VARCHAR(16) CHECK (arhitektura IN ('x86_64','arm64','armv7')),
    ram_mb INTEGER, disk_gb INTEGER, model VARCHAR(128), tok_s INTEGER, biljeska TEXT
);

CREATE TABLE katalog.cvor_servisi (
    id SERIAL PRIMARY KEY,
    cvor_id INTEGER NOT NULL REFERENCES katalog.cvorovi(id),
    ime VARCHAR(64) NOT NULL,
    tip VARCHAR(16) NOT NULL CHECK (tip IN ('db','inference','proxy','mcp','monitor','dns','backup','messaging')),
    port INTEGER, verzija VARCHAR(32),
    status VARCHAR(16) DEFAULT 'aktivan' NOT NULL CHECK (status IN ('aktivan','stopped')),
    autostart BOOLEAN DEFAULT true, biljeska TEXT
);

CREATE TABLE katalog.dns_hostnami (
    id SERIAL PRIMARY KEY,
    hostname VARCHAR(128) NOT NULL,
    dynu_domain_id VARCHAR(64),
    trenutna_ip INET,
    ciljni_cvor_id INTEGER REFERENCES katalog.cvorovi(id),
    ttl_sekunde INTEGER DEFAULT 30,
    zadnja_promjena TIMESTAMPTZ,
    aktivan BOOLEAN DEFAULT true, biljeska TEXT
);

ALTER TABLE katalog.cvorovi ADD CONSTRAINT cvorovi_primarni_dns_id_fkey
    FOREIGN KEY (primarni_dns_id) REFERENCES katalog.dns_hostnami(id);

CREATE TABLE katalog.dns_failover_log (
    id SERIAL PRIMARY KEY,
    hostname_id INTEGER NOT NULL REFERENCES katalog.dns_hostnami(id),
    stara_ip INET, nova_ip INET, razlog TEXT,
    ts TIMESTAMPTZ DEFAULT now() NOT NULL, uspjesno BOOLEAN
);

CREATE TABLE katalog.ntfy_kanali (
    id SERIAL PRIMARY KEY,
    naziv VARCHAR(64) NOT NULL, url TEXT, topic VARCHAR(64),
    tip VARCHAR(16) CHECK (tip IN ('interni','eksterni')),
    aktivan BOOLEAN DEFAULT true, biljeska TEXT
);

CREATE TABLE katalog.projekti (
    id SERIAL PRIMARY KEY,
    ime VARCHAR(64) NOT NULL, opis TEXT,
    status VARCHAR(16) DEFAULT 'aktivan' CHECK (status IN ('aktivan','arhiviran','pauziran')),
    primarni_cvor_id INTEGER REFERENCES katalog.cvorovi(id),
    kreiran TIMESTAMPTZ DEFAULT now() NOT NULL, biljeska TEXT
);

CREATE TABLE katalog.prompti (
    id SERIAL PRIMARY KEY,
    ime VARCHAR(64) UNIQUE NOT NULL, tekst TEXT,
    tip VARCHAR(16) CHECK (tip IN ('status','analiza','sync','backup','dns','init')),
    aktivan BOOLEAN DEFAULT true, verzija INTEGER DEFAULT 1, biljeska TEXT
);

CREATE TABLE katalog.raspored (
    id SERIAL PRIMARY KEY,
    projekt_id INTEGER NOT NULL REFERENCES katalog.projekti(id),
    prompt_id INTEGER NOT NULL REFERENCES katalog.prompti(id),
    cvor_id INTEGER NOT NULL REFERENCES katalog.cvorovi(id),
    ntfy_kanal_id INTEGER REFERENCES katalog.ntfy_kanali(id),
    frekvencija VARCHAR(32), aktivan BOOLEAN DEFAULT true,
    zadnji_run TIMESTAMPTZ, biljeska TEXT
);

CREATE TABLE katalog.izvrsavanja (
    id SERIAL PRIMARY KEY,
    raspored_id INTEGER REFERENCES katalog.raspored(id),
    prompt_id INTEGER REFERENCES katalog.prompti(id),
    start_ts TIMESTAMPTZ DEFAULT now(), kraj_ts TIMESTAMPTZ,
    status VARCHAR(16) CHECK (status IN ('ok','greska','timeout')),
    rezultat TEXT, params JSONB,
    izvor VARCHAR(16) DEFAULT 'cron' CHECK (izvor IN ('cron','clint','manual'))
);

CREATE TABLE katalog.dokumenti (
    id SERIAL PRIMARY KEY,
    projekt_id INTEGER REFERENCES katalog.projekti(id),
    naziv VARCHAR(128) NOT NULL, doc_type VARCHAR(32),
    sazetak TEXT, url TEXT,
    kreiran TIMESTAMPTZ DEFAULT now() NOT NULL, biljeska TEXT
);

CREATE TABLE katalog.repozitoriji (
    id SERIAL PRIMARY KEY,
    projekt_id INTEGER REFERENCES katalog.projekti(id),
    ime VARCHAR(64) NOT NULL, url TEXT, opis TEXT, biljeska TEXT
);

CREATE TABLE katalog.gdrive_backup (
    id SERIAL PRIMARY KEY,
    servis_id INTEGER NOT NULL REFERENCES katalog.cvor_servisi(id),
    folder_id VARCHAR(128), zadnji_run TIMESTAMPTZ,
    velicina_mb INTEGER, status VARCHAR(32), biljeska TEXT
);

CREATE TABLE katalog.db_backup (
    id SERIAL PRIMARY KEY,
    servis_id INTEGER NOT NULL REFERENCES katalog.cvor_servisi(id),
    tip VARCHAR(16) CHECK (tip IN ('full','incremental','dump')),
    destinacija VARCHAR(16) CHECK (destinacija IN ('gdrive','local','remote')),
    zadnji_run TIMESTAMPTZ, velicina_mb INTEGER, status VARCHAR(32)
);

CREATE TABLE katalog.ntfy_log (
    id SERIAL PRIMARY KEY,
    kanal_id INTEGER REFERENCES katalog.ntfy_kanali(id),
    projekt_id INTEGER REFERENCES katalog.projekti(id),
    poruka TEXT, ts TIMESTAMPTZ DEFAULT now() NOT NULL, status VARCHAR(16)
);

CREATE TABLE katalog.claude_platforma (
    id SERIAL PRIMARY KEY,
    cvor_id INTEGER REFERENCES katalog.cvorovi(id),
    verzija VARCHAR(64), plan VARCHAR(16),
    projekt_context VARCHAR(128), mcp_toolovi TEXT[],
    artifacts BOOLEAN, web_search BOOLEAN, memory_edits BOOLEAN,
    zabiljezeno TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE USER fla WITH PASSWORD 'Fla2026.kata';
GRANT USAGE ON SCHEMA katalog TO fla;
GRANT ALL ON ALL TABLES IN SCHEMA katalog TO fla;
GRANT ALL ON ALL SEQUENCES IN SCHEMA katalog TO fla;
