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

Este projeto passou por uma evolução significativa ao longo do desenvolvimento, saindo de um modelo conceitual bem estruturado para uma base mais próxima de sistemas utilizados em ambiente corporativo.

### 🔹 Base Inicial (Samuel)

A estrutura inicial do banco foi desenvolvida pelo Samuel, com excelente qualidade conceitual.  
O modelo já contemplava de forma organizada:

- definição das principais entidades do sistema
- estrutura inicial das devoluções
- organização consistente dos dados

Essa base foi essencial para a evolução do projeto e permitiu avançar para um nível mais técnico e aplicado.

---

### 🔹 Evolução e Refinamento (Eliabe)

A partir dessa base sólida, o modelo foi evoluído com foco em aproximar o banco de um cenário real de empresa, com melhorias estruturais, de segurança e de regras de negócio.
🔹 Melhorias Implementadas

Workflow de processo: controle de status com regras de transição (máquina de estados), evitando saltos indevidos no fluxo.

Rastreabilidade: histórico completo de status com data e usuário.

Auditoria: logs automáticos com registro de alterações (antes/depois), garantindo integridade dos dados.

Validação de dados: uso de domínios para garantir formato correto (ex: CNPJ e e-mail).

Segurança: controle de acesso por papéis e bloqueio após tentativas inválidas.

SLA no banco: identificação automática de prazos (normal, alerta, atraso) diretamente nas consultas.

Organização: separação por camadas (schema, seed, relatórios, documentação) e melhoria da estrutura geral.

---

## 📁 Estrutura do Projeto

```text
database/
├── 01_schema/
│   └── schema_consolidado.sql
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
\i database/01_schema/schema_consolidado.sql
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
