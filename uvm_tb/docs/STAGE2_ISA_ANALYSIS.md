# Stage 2: CV32E40P ISA Analysis & Stimulus Generation

## ISA Architecture Analysis

### Core Characteristics
- **Pipeline**: 4-stage in-order (IF, ID, EX, WB)
- **Base ISA**: RV32I with extensions C, M, Zicsr, Zicntr, Zifencei
- **Optional Extensions**: F (FPU), Zfinx, CORE-V PULP custom extensions
- **Performance**: Single-cycle ALU, 1-5 cycle multiplier, 3-35 cycle divider

### Instruction Categories & IPC Impact

#### 1. **Integer Computational Instructions** (1 cycle)
- **ALU Operations**: ADD, SUB, AND, OR, XOR, shifts (SLL, SRL, SRA)
- **Comparisons**: SLT, SLTU, equality checks
- **IPC Impact**: Ideal 1.0 IPC, no hazards
- **Verification Focus**: Corner cases, overflow, underflow

#### 2. **Multiplication Instructions** (1-5 cycles)
- **Single-cycle**: MUL (32x32→32)
- **Multi-cycle**: MULH, MULHSU, MULHU (32x32→upper 32, 5 cycles)
- **IPC Impact**: MUL maintains 1.0 IPC, MULH* reduces to 0.2 IPC
- **Verification Focus**: Signed/unsigned combinations, edge values

#### 3. **Division Instructions** (3-35 cycles)
- **Variable latency**: Depends on leading zeros in divisor
- **Operations**: DIV, DIVU, REM, REMU
- **IPC Impact**: Severe reduction (0.03-0.33 IPC)
- **Verification Focus**: Division by zero, edge cases, performance variation

#### 4. **Load/Store Instructions** (1-4 cycles)
- **Aligned**: 1 cycle
- **Misaligned**: 2 cycles
- **Event Load (cv.elw)**: 4 cycles
- **IPC Impact**: Memory system dependent
- **Verification Focus**: Alignment, post-increment, register hazards

#### 5. **Control Flow Instructions** (1-4 cycles)
- **Not-taken branches**: 1 cycle
- **Taken branches**: 3-4 cycles (depending on alignment)
- **Jumps**: 2-3 cycles
- **IPC Impact**: Branch prediction critical
- **Verification Focus**: Branch patterns, pipeline flushes

#### 6. **CORE-V PULP Extensions** (1-2 cycles)
- **Post-increment Load/Store**: Enhanced addressing
- **Hardware Loops**: Zero-overhead loops
- **SIMD Operations**: 8-bit and 16-bit parallel operations
- **Bit Manipulation**: Specialized bit operations
- **IPC Impact**: Improved efficiency for DSP workloads

### Register Architecture
- **General Purpose**: x0-x31 (x0 hardwired to 0)
- **Floating Point**: f0-f31 (if FPU enabled)
- **CSRs**: Machine mode, performance counters, debug, PULP extensions

### Critical CSRs for Verification
- **Performance**: `mcycle`, `minstret`, `mhpmcounter*`
- **Control**: `mstatus`, `mie`, `mtvec`
- **PULP HWLoop**: `lpstart0/1`, `lpend0/1`, `lpcount0/1`
- **Debug**: `dpc`, `dcsr`, `dscratch0/1`

### Hazard Analysis
1. **Load-use hazard**: 1 cycle penalty
2. **JALR hazard**: 1 cycle penalty if dependent on preceding instruction
3. **FPU hazards**: 1 to FPU_*_LAT cycles
4. **Forwarding**: ALU→ALU, MUL→ALU, DIV→ALU (0 cycle penalty)

## Stimulus Generation Strategy

### Decision Matrix: Constrained Random vs Directed Testing

| **Instruction Category** | **Method** | **Rationale** |
|-------------------------|------------|---------------|
| **Basic ALU Operations** | **Constrained Random** | Large input space, corner cases emerge naturally |
| **Multiplication** | **Mixed** | Random for coverage, directed for edge cases |
| **Division** | **Directed** | Critical edge cases (div by 0, overflow) |
| **Load/Store** | **Constrained Random** | Address patterns, alignment scenarios |
| **Control Flow** | **Directed** | Specific branch patterns, loop structures |
| **PULP Extensions** | **Mixed** | Random for coverage, directed for features |
| **CSR Operations** | **Directed** | Specific register access patterns |
| **Hazard Testing** | **Directed** | Precise instruction sequences |

### Rationale for Decision Making

#### **Constrained Random Approach**
**When to use:**
- Large input space with uniform distribution needs
- Corner cases emerge naturally from random combinations
- Coverage-driven verification is primary goal
- Regression testing with different seeds

**Examples:**
- ALU operations with random operands
- Load/store with random addresses (within valid ranges)
- Register allocation patterns
- Instruction mix ratios

#### **Directed Testing Approach**
**When to use:**
- Specific architectural features need targeted testing
- Critical edge cases must be guaranteed to occur
- Hazard conditions require precise instruction sequences
- Performance characteristics need measurement

**Examples:**
- Division by zero handling
- Pipeline hazard sequences
- CSR access patterns
- Hardware loop boundary conditions
- Interrupt/exception scenarios

#### **Mixed Approach**
**When to use:**
- Complex features benefit from both approaches
- Random testing for coverage + directed for critical paths
- Validation of both typical and edge case behavior

**Examples:**
- Multiplication: random operands + directed edge values
- PULP extensions: random usage + directed feature tests
- Memory operations: random patterns + directed alignment tests

## Implementation Plan

### Phase 1: Enhanced Sequence Items
- Extend instruction item with PULP extensions
- Add constraint classes for different instruction types
- Implement coverage models for ISA features

### Phase 2: Diverse Sequence Library
- Basic ALU sequence (constrained random)
- Multiplication test sequence (mixed approach)
- Division edge case sequence (directed)
- Load/store pattern sequence (constrained random)
- Control flow sequence (directed)
- PULP extension sequence (mixed)
- Hazard injection sequence (directed)
- Performance characterization sequence (directed)

### Phase 3: Assembly Generation Script
- Target instruction distribution based on typical workloads
- Configurable instruction mix ratios
- Automatic hazard insertion
- Performance benchmark generation

This analysis provides the foundation for creating comprehensive verification sequences that balance coverage, efficiency, and architectural understanding.