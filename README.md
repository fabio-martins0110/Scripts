# ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗███████╗
# ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝██╔════╝
# ███████╗██║     ██████╔╝██║██████╔╝   ██║   ███████╗
# ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   ╚════██║
# ███████║╚██████╗██║  ██║██║██║        ██║   ███████║
# ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   ╚══════╝

> Repositório de Scripts de Automação PowerShell  
> Ambiente Windows | Administração | Limpeza | Atualizações

---

# 🖥️ SOBRE

Coleção de scripts PowerShell para automação de tarefas administrativas no Windows.

O objetivo deste repositório é centralizar scripts simples, rápidos e reutilizáveis para manutenção e otimização do sistema operacional.

---

# 📂 ESTRUTURA

```bash
📦 automation-scripts
 ┣ 📜 limpaTeams.ps1
 ┣ 📜 LimpaTemp.ps1
 ┣ 📜 AtualizaWin.ps1
 ┗ 📄 README.md
```

---

# ⚙️ SCRIPTS DISPONÍVEIS

## 🧹 limpaTeams.ps1

Remove cache e contas salvas do Microsoft Teams.

### Recursos

- Limpeza de cache
- Remoção de arquivos temporários
- Reinicialização limpa do Teams

---

## 🗑️ LimpaTemp.ps1

Remove arquivos temporários do Windows e libera espaço em disco.

### Recursos

- Limpeza de `%TEMP%`
- Limpeza de cache do sistema
- Exclusão automática de arquivos desnecessários

---

## 🔄 AtualizaWin.ps1

Executa atualização automática do Windows.

### Recursos

- Busca por updates
- Download automático
- Instalação de atualizações

---

# 🚀 COMO EXECUTAR

## 1️⃣ Liberar execução de scripts

Abra o PowerShell como Administrador:

```powershell
Set-ExecutionPolicy Unrestricted
```

## 2️⃣ Executar script

```powershell
.\NomeDoScript.ps1
```

---

# 🛠️ REQUISITOS

- Windows 10 / 11
- PowerShell 5.1+
- Permissão de Administrador

---

# 📌 OBJETIVO DO PROJETO

- Automatizar tarefas repetitivas
- Facilitar manutenção do Windows
- Melhorar produtividade
- Centralizar scripts úteis

---

# 💻 EXEMPLO VISUAL

```powershell
PS C:\automation-scripts> .\LimpaTemp.ps1

Iniciando limpeza...
Arquivos temporários removidos com sucesso.
```

---

# 🧠 FUTURAS IMPLEMENTAÇÕES

- Limpeza de cache de navegadores
- Instalação de Impressoras

---

# 👨‍💻 AUTOR

Desenvolvido para automação e administração Windows — Fabio Casa

---
SYSTEM STATUS: ONLINE  
AUTOMATION READY
