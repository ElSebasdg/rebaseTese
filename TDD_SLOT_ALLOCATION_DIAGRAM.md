# TDD Slot Allocation - Visual Diagram

## Frame Structure (20 slots per frame)

```
Slot:  0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19
      ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
TDD:  │  │  │  │  │  │  │TX│TX│TX│TX│  │  │  │  │  │  │  │  │  │  │
      └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
                        └──────┘
                     TDD TX slots
                     (Sync Ref only)
```

---

## Sync Reference Transmission Pattern

```
┌─────────────────────────────────────────────────────────────┐
│         SYNC REFERENCE (src_id=0) - TDD Pattern             │
└─────────────────────────────────────────────────────────────┘

Slot 6-7: TRANSMIT TO UE1
┌────────┐
│ Slot 6 │ → Sync Ref processes UE1 (uid=1)
├────────┤    ├─ target_uid = 1
│        │    ├─ Skips UE2 in loop
│  TX    │    └─ Creates PDU: SRC=0, DST=1
│ to UE1 │
├────────┤
│ Slot 7 │ → Same process (target_uid = 1)
└────────┘

Slot 8-9: TRANSMIT TO UE2
┌────────┐
│ Slot 8 │ → Sync Ref processes UE2 (uid=2)
├────────┤    ├─ target_uid = 2
│        │    ├─ Skips UE1 in loop
│  TX    │    └─ Creates PDU: SRC=0, DST=2
│ to UE2 │
├────────┤
│ Slot 9 │ → Same process (target_uid = 2)
└────────┘
```

---

## UE1 Reception Pattern

```
┌─────────────────────────────────────────────────────────────┐
│              UE1 (src_id=1, uid=1) - RX Only                │
└─────────────────────────────────────────────────────────────┘

Slot 6-7: RECEIVE FROM SYNC REF
┌────────┐
│ Slot 6 │ → UE1 listens for PSCCH/PSSCH
├────────┤    ├─ Expects SRC=0, DST=1
│        │    ├─ TX: BLOCKED (no transmit capability)
│   RX   │    └─ Processes received PDU
│        │
├────────┤
│ Slot 7 │ → Same (receives from Sync Ref)
└────────┘

Other slots: NO ACTIVITY
┌────────┐
│Slot 0-5│ → Idle (no TX/RX)
│ 8-19   │
└────────┘
```

---

## UE2 Reception Pattern

```
┌─────────────────────────────────────────────────────────────┐
│              UE2 (src_id=2, uid=2) - RX Only                │
└─────────────────────────────────────────────────────────────┘

Slot 8-9: RECEIVE FROM SYNC REF
┌────────┐
│ Slot 8 │ → UE2 listens for PSCCH/PSSCH
├────────┤    ├─ Expects SRC=0, DST=2
│        │    ├─ TX: BLOCKED (no transmit capability)
│   RX   │    └─ Processes received PDU
│        │
├────────┤
│ Slot 9 │ → Same (receives from Sync Ref)
└────────┘

Other slots: NO ACTIVITY
┌────────┐
│Slot 0-7│ → Idle (no TX/RX)
│ 10-19  │
└────────┘
```

---

## Complete Communication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Frame X Timeline                         │
└─────────────────────────────────────────────────────────────┘

Time →
Slot:    0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19

Sync Ref:                  ●──●  ●──●
                          TX1   TX2
                          
UE1:                      ○──○
                          RX    (from Sync Ref)
                          
UE2:                            ○──○
                                RX    (from Sync Ref)

Legend:
  ●  = Sync Ref transmits
  ○  = UE receives
  ── = Duration (2 slots)
  TX1 = Transmit to UE1 (slots 6-7)
  TX2 = Transmit to UE2 (slots 8-9)
```

---

## Scheduler Decision Logic Flow

```
┌─────────────────────────────────────────────────────────────┐
│           Sync Ref PSSCH Scheduler Entry Point              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                  ┌─────────────────┐
                  │ Check slot type │
                  │ (TX only)       │
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ slot == 6 or 7? │
                  └────────┬────────┘
                     YES ┌─┴─┐ NO
                         │   │
                    ┌────▼   ▼─────────┐
                    │                  │
          ┌─────────▼─────────┐  ┌────▼──────────┐
          │  target_uid = 1   │  │ slot == 8 or 9?│
          │  (Process UE1)    │  └────┬──────────┘
          └─────────┬─────────┘  YES ┌┴┐ NO
                    │                │ │
                    │     ┌──────────▼ ▼────────┐
                    │     │                     │
                    │   ┌─▼───────────┐  ┌──────▼──────┐
                    │   │target_uid=2 │  │Block TX     │
                    │   │(Process UE2)│  │(not TDD slot)│
                    │   └──────┬──────┘  └─────────────┘
                    │          │
                    └──────┬───┘
                           │
                           ▼
              ┌────────────────────────┐
              │ Loop: mac->sl_info.list│
              └────────┬───────────────┘
                       │
                       ▼
              ┌────────────────────────┐
              │ if (UE->uid != target) │
              │    → skip (continue)   │
              └────────┬───────────────┘
                       │ Match!
                       ▼
              ┌────────────────────────┐
              │ Process selected UE    │
              │ Create PDU & transmit  │
              └────────────────────────┘
```

---

## Slot Restriction Summary Table

| UE              | src_id | uid | TX Slots | RX Slots | Role          |
|-----------------|--------|-----|----------|----------|---------------|
| Sync Reference  | 0      | 0   | 6-9      | -        | Transmitter   |
| UE1             | 1      | 1   | BLOCKED  | 6-7      | Receiver only |
| UE2             | 2      | 2   | BLOCKED  | 8-9      | Receiver only |

---

## PDU Header Mapping

### Slot 6 or 7 (Sync Ref → UE1)
```
┌─────────────────────────────────────┐
│  NR_SLSCH_MAC_SUBHEADER_FIXED       │
├─────────────────────────────────────┤
│  V   = 0                            │
│  R   = 0                            │
│  SRC = 0  (Sync Ref)               │
│  DST = 1  (UE1)                    │ ← Dynamic based on target_uid
└─────────────────────────────────────┘
```

### Slot 8 or 9 (Sync Ref → UE2)
```
┌─────────────────────────────────────┐
│  NR_SLSCH_MAC_SUBHEADER_FIXED       │
├─────────────────────────────────────┤
│  V   = 0                            │
│  R   = 0                            │
│  SRC = 0  (Sync Ref)               │
│  DST = 2  (UE2)                    │ ← Dynamic based on target_uid
└─────────────────────────────────────┘
```

---

## Key Design Principles

### 1. **TDD Compliance**
- Only slots 6-9 are valid TX slots for Sync Ref
- Enforced at TX scheduler entry point

### 2. **Dynamic Target Selection**
- Scheduler sets `target_uid` based on current slot
- Filters UE list to process only matching uid

### 3. **Receive-Only UEs**
- UE1 and UE2 cannot transmit (TX always blocked)
- They only listen in their designated RX slots

### 4. **No Direct UE-to-UE Communication**
- UE1 ↔ UE2: Not possible (both are RX-only)
- Star topology: Sync Ref at center

---

## Timing Diagram (Detailed)

```
┌─────────────────────────────────────────────────────────────┐
│                  Frame N (20 slots)                         │
└─────────────────────────────────────────────────────────────┘

Slot 6:
  T=0ms     : Sync Ref enters scheduler
  T=0.5ms   : target_uid set to 1
  T=1ms     : Loop processes UE1, skips UE2
  T=2ms     : PDU created (SRC=0, DST=1)
  T=3ms     : PSCCH/PSSCH transmitted
  T=3.5ms   : UE1 starts receiving
  T=4ms     : UE1 decodes PSCCH
  T=5ms     : UE1 decodes PSSCH data

Slot 7:
  [Repeat of Slot 6 pattern for UE1]

Slot 8:
  T=0ms     : Sync Ref enters scheduler
  T=0.5ms   : target_uid set to 2
  T=1ms     : Loop processes UE2, skips UE1
  T=2ms     : PDU created (SRC=0, DST=2)
  T=3ms     : PSCCH/PSSCH transmitted
  T=3.5ms   : UE2 starts receiving
  T=4ms     : UE2 decodes PSCCH
  T=5ms     : UE2 decodes PSSCH data

Slot 9:
  [Repeat of Slot 8 pattern for UE2]
```

---

## Code Implementation Highlights

### Location 1: TX Slot Restrictions (Line ~3471)
```c
if (mac->src_id == 0 && get_nrUE_params()->sync_ref) {
    if (slot != 6 && slot != 7 && slot != 8 && slot != 9) {
        return is_resource_allocated; // Block TX
    }
}
```

### Location 2: Dynamic Target Selection (Line ~3536)
```c
int target_uid = -1;
if (slot == 6 || slot == 7) {
    target_uid = 1; // UE1
} else if (slot == 8 || slot == 9) {
    target_uid = 2; // UE2
}
```

### Location 3: UE Filtering in Loop (Line ~3554)
```c
if (target_uid != -1 && UE->uid != target_uid) {
    continue; // Skip this UE
}
```

---

## Network Topology

```
           ┌──────────────────┐
           │  Sync Reference  │
           │   (src_id=0)     │
           │   TX: slots 6-9  │
           └────────┬─────────┘
                    │
          ┌─────────┴─────────┐
          │                   │
     Slots 6-7            Slots 8-9
          │                   │
          ▼                   ▼
    ┌──────────┐        ┌──────────┐
    │   UE1    │        │   UE2    │
    │ (uid=1)  │        │ (uid=2)  │
    │ RX only  │        │ RX only  │
    └──────────┘        └──────────┘
         ❌ ──────────────── ❌
      No direct communication
```

---

## Summary

**TDD Constraint**: Sync Ref can only TX in slots 6-9  
**Solution**: Dynamic scheduler with slot-based target selection  
**Result**: Sync Ref communicates with UE1 (6-7) and UE2 (8-9) separately  

**Date**: October 10, 2025
