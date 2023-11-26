# System Memory Map

## 1 Home Node to Memory Channel

### 1.1 Range-based: non-hashed SN target ID

use reg to direct assign a range of memory address to specific memory channel or io device

### 1.2 Range-based: hashed SN target ID

#### 1.2.1 UMA mode

use reg to assign a range of memory address, for 4 home node, 4 memory channel:
1. use PA[7:6] to interleave among memony channels (cache line interleave)
2. for unbalanced memory size among memory channels, use to smallest size channel to interleave, and other memory use direct assign

| PA bit num        | msb | ... | 8   | 7   | 6   | 5 - 0       |
| ----------------- | --- | --- | --- | --- | --- | ----------- |
| Interleaving type |     |     |     | CH  | CH  | line offest |

CH: Channel interleaving

#### 1.2.2 NUMA mode

use reg to assign a range of memory address, for 4 home node, 4 memory channel:
1. use PA[6] to interleave among memony channels (cache line interleave)
2. use PA[msb] to interleave among nodes
3. for unbalanced memory size among memory channels, use to smallest size channel to interleave, and other memory use direct assign

| PA bit num        | msb | ... | 8   | 7   | 6   | 5 - 0       |
| ----------------- | --- | --- | --- | --- | --- | ----------- |
| Interleaving type | ND  |     |     | CH  | CH  | line offest |

ND: Node interleaving, CH: Channel interleaving

## 2 Request Node to Home Node

### 2.1 Non-hashed regions

A given memory partition is assigned to an individual targetID (non-hashed), for:
1. PLIC(highest priority);
2. IO space;
3. Directly assigned memory range

### 2.2 Hashed memory region or non-hashed mode of hashed memory region

#### 2.2.1 NUCA mode

use reg to assign a range of memory address for one core/cluster to its nearest home node, 
it can be configured at reset.
