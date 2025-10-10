# Guia Rápido - 3 UEs com Scheduler Dinâmico (TDD)

## Configuração TDD

**Restrição importante**: O Sync Reference **só pode usar as slots 6, 7, 8 e 9** (configuração TDD).

---

## Solução Implementada

### ✅ Alocação Dinâmica Baseada em TDD

O scheduler agora **decide automaticamente** qual UE processar baseado na slot actual:

```
Sync Reference (src_id=0):
  - Slots 6-7: Transmite para UE1 (uid=1)
  - Slots 8-9: Transmite para UE2 (uid=2)

UE1 (src_id=1):
  - Slots 6-7: Recebe do Sync Ref (NÃO transmite)
  - Outras slots: Sem actividade

UE2 (src_id=2):
  - Slots 8-9: Recebe do Sync Ref (NÃO transmite)
  - Outras slots: Sem actividade
```

**Porquê funciona**:
- ✅ Respeita configuração TDD (slots 6-9 apenas)
- ✅ UE1 e UE2 são **apenas receção** (não transmitem)
- ✅ Scheduler seleciona UE dinamicamente baseado na slot
- ✅ Sem overlap entre UE1 e UE2

---

## Como o Scheduler Decide

### **Lógica de Seleção Dinâmica**

```c
Se slot = 6 ou 7:
    → target_uid = 1 (processa apenas UE1)
    
Se slot = 8 ou 9:
    → target_uid = 2 (processa apenas UE2)
```

**Durante cada slot**:
1. Sync Ref verifica número da slot actual
2. Slot 6-7 → Scheduler processa **apenas UE1** da lista
3. Slot 8-9 → Scheduler processa **apenas UE2** da lista
4. Outras slots → Sem processamento (bloqueado por TDD)

---

## Fluxo de Transmissão

### **Slots 6-7: Sync Ref → UE1**
```
Frame X, Slot 6:
  ├─ Sync Ref entra no PSSCH scheduler
  ├─ target_uid = 1 (baseado na slot 6)
  ├─ Loop pela lista mac->sl_info.list[]
  ├─ Salta UE2 (uid=2) porque target_uid=1
  ├─ Processa UE1 (uid=1)
  └─ Cria PDU: SRC=0, DST=1 → Transmite para UE1
```

### **Slots 8-9: Sync Ref → UE2**
```
Frame X, Slot 8:
  ├─ Sync Ref entra no PSSCH scheduler
  ├─ target_uid = 2 (baseado na slot 8)
  ├─ Loop pela lista mac->sl_info.list[]
  ├─ Salta UE1 (uid=1) porque target_uid=2
  ├─ Processa UE2 (uid=2)
  └─ Cria PDU: SRC=0, DST=2 → Transmite para UE2
```

---

## Restrições de Slot Implementadas

### **Sync Reference (src_id=0)**
```
Slots permitidas: 6, 7, 8, 9 (TDD)
Outras slots: BLOQUEADO
```

### **UE1 (src_id=1)**
```
TX: SEMPRE BLOQUEADO (apenas receção)
RX: Slots 6-7
```

### **UE2 (src_id=2)**
```
TX: SEMPRE BLOQUEADO (apenas receção)
RX: Slots 8-9
```

---

## Como Testar

### 1. Compilar
```bash
cd ~/Music/rebaseTese/openairinterface5g-sl-eurecom2/cmake_targets
./sl_build_OAI.py
```

### 2. Ligar os UEs (por esta ordem!)

**Terminal 1 - Sync Reference:**
```bash
./run_sl_ue.sh --rfsim --syncref
```

**Terminal 2 - UE1:**
```bash
./run_sl_ue.sh --rfsim --ue1
```

**Terminal 3 - UE2:**
```bash
./run_sl_ue.sh --rfsim --ue2
```

### 3. Verificar Logs

**Sync Reference deve mostrar:**
```
[TDD_SLOT] ✅ SYNC_REF src_id=0 allowed to TX in slot 6
[TDD_SCHEDULER] 🎯 Slot 6: Sync Ref will TX to UE1 (uid=1) only

[TDD_SLOT] ✅ SYNC_REF src_id=0 allowed to TX in slot 8
[TDD_SCHEDULER] 🎯 Slot 8: Sync Ref will TX to UE2 (uid=2) only
```

**UE1 e UE2 devem mostrar:**
```
[TDD_SLOT] ⛔ UE1 src_id=1 blocked from TX
[TDD_SLOT] ⛔ UE2 src_id=2 blocked from TX
```

### 4. Testar Pings

Do Sync Ref para UE1:
```bash
ping 10.0.2.2
```

Do Sync Ref para UE2:
```bash
ping 10.0.3.2
```

**Nota**: UE1 e UE2 **não podem comunicar diretamente** entre si (são apenas receção).

---

## O Que Mudou no Código

### **Ficheiro**: `nr_ue_scheduler.c`

### **Mudança 1**: Restrições de Slot TDD (linhas ~3471-3500)
- Sync Ref: Apenas slots 6-9
- UE1: Bloqueado de TX (apenas RX)
- UE2: Bloqueado de TX (apenas RX)

### **Mudança 2**: Seleção Dinâmica de UE (linhas ~3534-3560)
- Slot 6-7 → target_uid = 1 (processa UE1)
- Slot 8-9 → target_uid = 2 (processa UE2)
- Loop filtra UEs baseado em target_uid

---

## Resposta à Tua Pergunta

### "O scheduler está pronto para 3 UEs com esta separação?"

**SIM** ✅ - Com scheduler dinâmico baseado em TDD:

1. **Decisão automática** baseada na slot actual
2. **Conformidade com TDD** (apenas slots 6-9)
3. **Filtragem adequada** (salta UEs não-alvo)
4. **UEs apenas receção** (UE1/UE2 não transmitem)

---

## Porquê Esta Solução Resolve o Problema

### **Antes (Slots 16-19)**
- ❌ Slots fora do range TDD
- ❌ Sync Ref não podia transmitir
- ❌ Scheduler processava todos os UEs
- ❌ Sem targeting dinâmico

### **Depois (Scheduler Dinâmico TDD)**
- ✅ Slots 6-9 conforme TDD
- ✅ Sync Ref transmite quando permitido
- ✅ Scheduler seleciona UE por slot
- ✅ Sem contenção entre UE1 e UE2

---

## Árvore de Decisão do Scheduler

```
Slot Actual = 6?
    ├─ SIM → target_uid = 1
    │         └─ Processa UE1, salta UE2
    └─ NÃO
        └─ Slot Actual = 7?
            ├─ SIM → target_uid = 1
            └─ NÃO
                └─ Slot Actual = 8?
                    ├─ SIM → target_uid = 2
                    │         └─ Processa UE2, salta UE1
                    └─ NÃO
                        └─ Slot Actual = 9?
                            ├─ SIM → target_uid = 2
                            └─ NÃO → Bloqueia TX (TDD)
```

---

## Comportamento Esperado

✅ **Slot 6**: Sync Ref → UE1  
✅ **Slot 7**: Sync Ref → UE1  
✅ **Slot 8**: Sync Ref → UE2  
✅ **Slot 9**: Sync Ref → UE2  
✅ Sync Ref consegue pingar UE1 e UE2  
✅ Sem perda de pacotes  
✅ Sem contenção no scheduler  

---

## Resumo Ultra-Rápido

**Problema**: Slots 16-19 fora do range TDD  
**Solução**: Scheduler dinâmico com slots 6-9 TDD  
**Mecanismo**: target_uid baseado na slot filtra lista de UEs  

**Como funciona**:
- Slot 6-7 → Sync Ref transmite para UE1
- Slot 8-9 → Sync Ref transmite para UE2
- O scheduler **decide automaticamente** baseado na slot

**Ficheiros alterados**: `nr_ue_scheduler.c` (linhas 3471-3560)
