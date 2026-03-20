  # 🔄 Sistema de Logística Reversa de Peças

![Status](https://img.shields.io/badge/status-em%20desenvolvimento-blue)
![Database](https://img.shields.io/badge/database-PostgreSQL-blue)
![SQL](https://img.shields.io/badge/language-SQL-lightgrey)
![Projeto Acadêmico](https://img.shields.io/badge/projeto-UNIVESP-orange)
![Licença](https://img.shields.io/badge/license-academic-green)

Projeto desenvolvido na disciplina **Projeto Integrador em Computação I (UNIVESP)** com foco na construção de um **banco de dados relacional robusto** para gerenciamento completo de logística reversa de peças.

---

## 🎯 Visão Geral

Sistema projetado para simular um ambiente corporativo real, onde o banco de dados atua como **núcleo inteligente do sistema**, sendo responsável por:

- Controle de devoluções
- Gestão de workflow
- Auditoria completa
- Monitoramento de SLA
- Garantia de integridade dos dados

---

## 🧠 Diferenciais Técnicos

✔ Regras de negócio implementadas diretamente no banco  
✔ Máquina de estados para controle de fluxo  
✔ Auditoria automatizada (before/after)  
✔ Controle de SLA em tempo real  
✔ Estrutura preparada para integração com aplicações  

---

## 🧠 Arquitetura

- Banco relacional PostgreSQL
- Uso de PL/pgSQL para regras de negócio
- Estrutura modular (schema, funções, triggers)

## 🔄 Fluxo do Sistema

REGISTRADA → EM_ANALISE → APROVADA → FINALIZADA

## 📊 Exemplo de Consulta

```sql
SELECT * FROM pecas_devolucao WHERE status_atual = 'EM_ANALISE';

## 🔄 Workflow (Máquina de Estados)

Fluxo controlado diretamente no banco:


REGISTRADA → EM_ANALISE → APROVADA → RESSARCIDA → FINALIZADA
↘ REJEITADA


### Regras:
- Não permite pular etapas
- Histórico automático de alterações
- Validação de transições

---

## 🔐 Segurança

- Validação via domínios (CNPJ, e-mail)
- Constraints de integridade
- Controle de acesso por papéis (RBAC)
- Proteção contra alterações indevidas

---

## 📊 Auditoria

- Registro automático de eventos
- Valores antes/depois
- Usuário responsável
- Data/hora da operação
- Logs imutáveis

---

## ⏱️ SLA

Classificação automática:

- 🟢 Dentro do prazo  
- 🟡 Alerta  
- 🔴 Crítico  

Consulta direta via SQL.

---

## 📈 Funcionalidades

- Gestão de devoluções
- Controle de itens e vendedores
- Histórico de status
- Auditoria completa
- Monitoramento de SLA
- Relatórios gerenciais

---

## 🗂️ Estrutura do Projeto


database/
├── 01_schema/
├── 02_seed/
├── 03_reports/
└── legacy_modelos/

docs/
diagramas/


---

## ⚙️ Tecnologias

- PostgreSQL
- SQL

---

## 🚀 Como Executar

```sql
CREATE DATABASE logistica_reversa;
\c logistica_reversa

\i database/01_schema/schema_consolidado.sql
\i database/02_seed/seed.sql
\i database/03_reports/relatorios.sql
📊 Exemplos
SLA crítico
SELECT * FROM relatorio_sla WHERE status_sla = 'CRITICO';
Histórico
SELECT * FROM historico_status WHERE devolucao_id = 1;
📌 Considerações

Projeto com foco em:

Integridade de dados

Controle de processo

Escalabilidade

Aplicação prática de banco de dados

🚀 Roadmap

 API backend (Node.js ou Java)

 Interface web

 Dashboard

 Integração com ERP

👥 Autores

Samuel — Modelagem inicial
Eliabe Gabriel — Implementação e evolução técnica

🧾 Licença

Uso acadêmico
