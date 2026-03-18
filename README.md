# Sistema de Logística Reversa de Peças

Projeto desenvolvido na disciplina **Projeto Integrador em Computação I**, com foco na modelagem e implementação de um banco de dados relacional em PostgreSQL para controle de devoluções de peças.

---

## 🎯 Objetivo

Estruturar e automatizar o processo de logística reversa, permitindo:

* controle completo das devoluções
* rastreabilidade de todas as etapas
* auditoria de alterações
* controle de prazos (SLA)
* geração de relatórios gerenciais

---

## ⚙️ Tecnologias Utilizadas

* PostgreSQL
* SQL / PLpgSQL
* pgAdmin
* Modelagem Entidade-Relacionamento (ER)

---

## 🧠 Evolução do Projeto

O projeto iniciou como um modelo acadêmico simples e foi evoluído para uma estrutura próxima de sistemas corporativos, incorporando:

* controle de workflow via banco
* histórico imutável de status
* auditoria de alterações
* regras de negócio via triggers
* controle de SLA
* estrutura preparada para integração com XML

---

## 📁 Estrutura do Projeto

```text
database/
├── 01_schema/
│   └── schema_consolidado_final.sql
├── 02_seed/
│   └── seed.sql
├── 03_legacy_test_data/
│   ├── dados_teste_legacy.sql
│   └── inserts_teste_legacy.sql
├── 04_reports/
│   └── relatorios.sql
└── legacy_modelos/

docs/
├── 00_estrutura_recomendada.docx
├── 01_descricao_projeto.docx
├── 02_quinzenas.docx
└── 03_fluxo_processo_atual.docx

diagramas/
└── diagrama_atual.png
```

---

## 🗄️ Modelagem do Banco

O banco foi estruturado em módulos:

### 🔹 Núcleo do processo

* devolucoes
* devolucao_itens
* historico_status
* status_transicoes

### 🔹 Cadastros

* usuarios
* papeis
* unidades_empresa
* usuarios_unidade
* itens
* notas_fiscais
* motivos

### 🔹 Controle e governança

* sla_config
* evento_log
* logs_alteracao
* evidencias
* xml_importacao

---

## 🔄 Workflow do Processo

```text
ABERTO → EM_ANALISE → AGUARDANDO_ENVIO → ENVIADO_FABRICA → ENCERRADO
```

* Transições controladas por `status_transicoes`
* Histórico registrado em `historico_status`
* Validações realizadas por triggers

---

## ⏱️ SLA

O sistema implementa controle de prazo com base em:

* motivo da devolução
* status atual
* regras definidas em `sla_config`

---

## 📊 Relatórios

Arquivo:

```text
database/04_reports/relatorios.sql
```

Principais análises:

* devoluções por status
* devoluções por motivo
* devoluções por responsável
* devoluções por unidade
* análise de SLA
* painel consolidado

View principal:

```text
vw_painel_devolucoes
```

---

## ▶️ Como Executar

1. Criar banco no PostgreSQL

2. Executar o schema:

```sql
\i database/01_schema/schema_consolidado_final.sql
```

3. Executar o seed:

```sql
\i database/02_seed/seed.sql
```

4. Executar os relatórios:

```sql
\i database/04_reports/relatorios.sql
```

---

## 📌 Diferenciais do Projeto

* Estrutura próxima de ambiente real corporativo
* Separação por camadas (schema, seed, relatórios)
* Controle de integridade via banco
* Auditoria e rastreabilidade completas
* Organização profissional de diretórios

---

## 🧪 Status

✔ Modelagem concluída
✔ Banco implementado
✔ Workflow funcional
✔ SLA implementado
✔ Relatórios prontos
✔ Documentação completa

---
