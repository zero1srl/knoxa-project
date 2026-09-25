# knoxa-project — contenitore dei sottoprogetti

Non è un monorepo: ogni cartella qui dentro è un **repository git separato** con
il proprio remote. Questo repo traccia solo gli script di backup/restore e le
config di editor; i sottoprogetti sono nel `.gitignore`.

Per lavorare da una nuova macchina: clona ogni repo nella stessa cartella.

## 1. Clone

```bash
git clone https://github.com/zero1srl/knoxa-project.git   # questo contenitore
cd knoxa-project
git clone https://github.com/zero1srl/knoxa.git           # motore (engine-api, compose, docs)
git clone https://github.com/zero1srl/knoxa-ui.git        # web app
git clone https://github.com/zero1srl/knoxa-bidq.git      # verticale gare
git clone https://github.com/zero1srl/knoxa-ui-admin.git  # pannello admin
git clone https://github.com/zero1srl/llm-gateway.git     # gateway LLM (ex LLM_Router)
git clone https://github.com/zero1srl/zero1code.git       # estensione VS Code
```

## 2. Segreti: cifrati nel repo, in chiaro solo nel working tree

**Prerequisito (fuori banda)**: la chiave condivisa `~/.knoxa-git-secret.key`.
Non è e non sarà mai nel repo — se manca, chiedila all'utente (password manager /
chiavetta) e copiala in `$HOME`. Serve `gpg` installato.

Su ogni repo il filtro git `gpgcrypt` decifra in automatico i file elencati in
`.gitattributes`. **Il filtro è config locale per macchina**: dopo un clone fresco
i file segreti sono su disco come blob cifrati (illeggibili) finché non esegui lo
script di setup **una volta per repo**.

| Repo | File cifrati | Comando di setup (da eseguire dopo il clone) |
|---|---|---|
| `knoxa` | `.env.local`, `.env.bkp` | `sh scripts/setup-git-secrets.sh ~/.knoxa-git-secret.key` |
| `knoxa-ui` | `.env.local`, `infra/supabase/.env`, `infra/app/.env` | `sh scripts/setup-git-crypt-gpg.sh` |
| `knoxa-bidq` | `.env.local`, `infra/supabase/.env`, `infra/app/.env` | `sh scripts/setup-git-crypt-gpg.sh` |
| `knoxa-ui-admin` | `.env.local`, `infra/app/.env` | `sh scripts/setup-git-crypt-gpg.sh` |
| `knoxa-llm-gateway` | `.env` | `sh scripts/setup-git-crypt-gpg.sh` |
| `zero1code` | nessuno | — |

**Verifica obbligatoria**, per ogni repo con segreti:

```bash
head -3 knoxa/.env.local     # deve mostrare testo leggibile, NON binario/�
```

### File NON tracciati da ricreare a mano (in `knoxa`)

- `.env`: `cp .env.local .env`
- `compose/.env`: `sh scripts/setup-compose-env.sh` (crea anche network e volumi)
- `.env.deploy`: `cp .env.deploy.example .env.deploy` (tag immagini per rollback,
  specifico per macchina)

### Regole operative — NON NEGOZIABILE

- **Mai `git add` di un file cifrato senza il filtro configurato**: git salverebbe
  il blob cifrato ri-cifrato (o il testo cifrato) al posto del segreto, e la
  history va riscritta per recuperarlo. Se `head` mostra binario, fermati e
  configura il filtro.
- **Mai `git checkout --` / `git restore` su `.env*`** con modifiche non
  committate: le perdi, perché il working tree viene ricostruito dal blob.
- I repo sono **privati**: i segreti sono versionati di proposito. Se un repo
  diventa pubblico, i `.env` vanno rimossi dalla history.
- Dettaglio sulla cifratura in `knoxa-ui/.gitattributes` e
  `knoxa/docs/configurazioni/setup-da-zero.md`.
