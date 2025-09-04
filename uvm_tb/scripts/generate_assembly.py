#!/usr/bin/env python3
"""
CV32E40P Assembly Generation Script
Generates assembly files with target instruction distributions for verification
"""

import argparse
import random
import json
from typing import Dict, List, Tuple
from dataclasses import dataclass
from enum import Enum

class InstructionType(Enum):
    ALU = "alu"
    MUL = "mul"
    DIV = "div"
    LOAD = "load"
    STORE = "store"
    BRANCH = "branch"
    JUMP = "jump"
    CSR = "csr"
    PULP_ALU = "pulp_alu"
    PULP_SIMD = "pulp_simd"
    PULP_HWLOOP = "pulp_hwloop"

@dataclass
class InstructionTemplate:
    mnemonic: str
    operands: str
    cycles: int
    description: str

class CV32E40PAssemblyGenerator:
    def __init__(self):
        self.instruction_templates = self._build_instruction_templates()
        self.registers = [f"x{i}" for i in range(32)]
        self.registers[0] = "zero"  # x0 is always zero
        self.registers[1] = "ra"    # Return address
        self.registers[2] = "sp"    # Stack pointer
        
        # Default instruction distribution (based on typical RISC-V workloads)
        self.default_distribution = {
            InstructionType.ALU: 35,      # Most common
            InstructionType.LOAD: 20,     # Memory operations
            InstructionType.STORE: 15,
            InstructionType.BRANCH: 12,   # Control flow
            InstructionType.MUL: 8,
            InstructionType.JUMP: 5,
            InstructionType.DIV: 2,       # Expensive operations
            InstructionType.CSR: 1,
            InstructionType.PULP_ALU: 2,  # PULP extensions (if enabled)
        }
        
        # Performance-focused distribution (emphasizes high-IPC instructions)
        self.performance_distribution = {
            InstructionType.ALU: 50,
            InstructionType.MUL: 20,
            InstructionType.LOAD: 15,
            InstructionType.STORE: 10,
            InstructionType.BRANCH: 3,
            InstructionType.JUMP: 1,
            InstructionType.DIV: 1,
        }
        
        # Stress test distribution (emphasizes challenging instructions)
        self.stress_distribution = {
            InstructionType.DIV: 25,      # High latency
            InstructionType.BRANCH: 25,   # Pipeline disruption
            InstructionType.LOAD: 20,     # Memory dependencies
            InstructionType.ALU: 15,
            InstructionType.MUL: 10,
            InstructionType.STORE: 5,
        }

    def _build_instruction_templates(self) -> Dict[InstructionType, List[InstructionTemplate]]:
        """Build instruction templates for each category"""
        templates = {
            InstructionType.ALU: [
                InstructionTemplate("add", "{rd}, {rs1}, {rs2}", 1, "Addition"),
                InstructionTemplate("sub", "{rd}, {rs1}, {rs2}", 1, "Subtraction"),
                InstructionTemplate("and", "{rd}, {rs1}, {rs2}", 1, "Bitwise AND"),
                InstructionTemplate("or", "{rd}, {rs1}, {rs2}", 1, "Bitwise OR"),
                InstructionTemplate("xor", "{rd}, {rs1}, {rs2}", 1, "Bitwise XOR"),
                InstructionTemplate("sll", "{rd}, {rs1}, {rs2}", 1, "Shift left logical"),
                InstructionTemplate("srl", "{rd}, {rs1}, {rs2}", 1, "Shift right logical"),
                InstructionTemplate("sra", "{rd}, {rs1}, {rs2}", 1, "Shift right arithmetic"),
                InstructionTemplate("slt", "{rd}, {rs1}, {rs2}", 1, "Set less than"),
                InstructionTemplate("sltu", "{rd}, {rs1}, {rs2}", 1, "Set less than unsigned"),
                InstructionTemplate("addi", "{rd}, {rs1}, {imm12}", 1, "Add immediate"),
                InstructionTemplate("andi", "{rd}, {rs1}, {imm12}", 1, "AND immediate"),
                InstructionTemplate("ori", "{rd}, {rs1}, {imm12}", 1, "OR immediate"),
                InstructionTemplate("xori", "{rd}, {rs1}, {imm12}", 1, "XOR immediate"),
                InstructionTemplate("slli", "{rd}, {rs1}, {shamt}", 1, "Shift left logical immediate"),
                InstructionTemplate("srli", "{rd}, {rs1}, {shamt}", 1, "Shift right logical immediate"),
                InstructionTemplate("srai", "{rd}, {rs1}, {shamt}", 1, "Shift right arithmetic immediate"),
            ],
            
            InstructionType.MUL: [
                InstructionTemplate("mul", "{rd}, {rs1}, {rs2}", 1, "Multiply low"),
                InstructionTemplate("mulh", "{rd}, {rs1}, {rs2}", 5, "Multiply high signed"),
                InstructionTemplate("mulhsu", "{rd}, {rs1}, {rs2}", 5, "Multiply high signed-unsigned"),
                InstructionTemplate("mulhu", "{rd}, {rs1}, {rs2}", 5, "Multiply high unsigned"),
            ],
            
            InstructionType.DIV: [
                InstructionTemplate("div", "{rd}, {rs1}, {rs2}", 35, "Divide signed"),
                InstructionTemplate("divu", "{rd}, {rs1}, {rs2}", 35, "Divide unsigned"),
                InstructionTemplate("rem", "{rd}, {rs1}, {rs2}", 35, "Remainder signed"),
                InstructionTemplate("remu", "{rd}, {rs1}, {rs2}", 35, "Remainder unsigned"),
            ],
            
            InstructionType.LOAD: [
                InstructionTemplate("lw", "{rd}, {offset}({rs1})", 1, "Load word"),
                InstructionTemplate("lh", "{rd}, {offset}({rs1})", 1, "Load halfword"),
                InstructionTemplate("lhu", "{rd}, {offset}({rs1})", 1, "Load halfword unsigned"),
                InstructionTemplate("lb", "{rd}, {offset}({rs1})", 1, "Load byte"),
                InstructionTemplate("lbu", "{rd}, {offset}({rs1})", 1, "Load byte unsigned"),
            ],
            
            InstructionType.STORE: [
                InstructionTemplate("sw", "{rs2}, {offset}({rs1})", 1, "Store word"),
                InstructionTemplate("sh", "{rs2}, {offset}({rs1})", 1, "Store halfword"),
                InstructionTemplate("sb", "{rs2}, {offset}({rs1})", 1, "Store byte"),
            ],
            
            InstructionType.BRANCH: [
                InstructionTemplate("beq", "{rs1}, {rs2}, {label}", 3, "Branch if equal"),
                InstructionTemplate("bne", "{rs1}, {rs2}, {label}", 3, "Branch if not equal"),
                InstructionTemplate("blt", "{rs1}, {rs2}, {label}", 3, "Branch if less than"),
                InstructionTemplate("bge", "{rs1}, {rs2}, {label}", 3, "Branch if greater or equal"),
                InstructionTemplate("bltu", "{rs1}, {rs2}, {label}", 3, "Branch if less than unsigned"),
                InstructionTemplate("bgeu", "{rs1}, {rs2}, {label}", 3, "Branch if greater or equal unsigned"),
            ],
            
            InstructionType.JUMP: [
                InstructionTemplate("jal", "{rd}, {label}", 2, "Jump and link"),
                InstructionTemplate("jalr", "{rd}, {rs1}, {imm12}", 2, "Jump and link register"),
            ],
            
            InstructionType.CSR: [
                InstructionTemplate("csrrw", "{rd}, {csr}, {rs1}", 1, "CSR read-write"),
                InstructionTemplate("csrrs", "{rd}, {csr}, {rs1}", 1, "CSR read-set"),
                InstructionTemplate("csrrc", "{rd}, {csr}, {rs1}", 1, "CSR read-clear"),
                InstructionTemplate("csrrwi", "{rd}, {csr}, {uimm5}", 1, "CSR read-write immediate"),
            ],
            
            InstructionType.PULP_ALU: [
                InstructionTemplate("cv.abs", "{rd}, {rs1}", 1, "Absolute value"),
                InstructionTemplate("cv.min", "{rd}, {rs1}, {rs2}", 1, "Minimum"),
                InstructionTemplate("cv.max", "{rd}, {rs1}, {rs2}", 1, "Maximum"),
                InstructionTemplate("cv.clip", "{rd}, {rs1}, {imm5}", 1, "Clip to range"),
                InstructionTemplate("cv.cnt", "{rd}, {rs1}", 1, "Count leading zeros"),
            ],
            
            InstructionType.PULP_SIMD: [
                InstructionTemplate("cv.add.h", "{rd}, {rs1}, {rs2}", 1, "SIMD add halfwords"),
                InstructionTemplate("cv.sub.h", "{rd}, {rs1}, {rs2}", 1, "SIMD subtract halfwords"),
                InstructionTemplate("cv.add.b", "{rd}, {rs1}, {rs2}", 1, "SIMD add bytes"),
                InstructionTemplate("cv.sub.b", "{rd}, {rs1}, {rs2}", 1, "SIMD subtract bytes"),
            ],
        }
        return templates

    def generate_instruction(self, instr_type: InstructionType, 
                           enable_hazards: bool = False,
                           prev_rd: str = None) -> Tuple[str, Dict]:
        """Generate a single instruction of the specified type"""
        templates = self.instruction_templates[instr_type]
        template = random.choice(templates)
        
        # Generate operands
        operands = {}
        
        # Register selection with hazard consideration
        if enable_hazards and prev_rd and random.random() < 0.3:
            # 30% chance to create a hazard by using previous destination
            operands['rs1'] = prev_rd
        else:
            operands['rs1'] = random.choice(self.registers[1:32])  # Avoid x0 for source
            
        operands['rs2'] = random.choice(self.registers[1:32])
        operands['rd'] = random.choice(self.registers[1:32])
        
        # Generate immediates and offsets
        operands['imm12'] = random.randint(-2048, 2047)
        operands['offset'] = random.randint(-2048, 2047)
        operands['shamt'] = random.randint(0, 31)
        operands['uimm5'] = random.randint(0, 31)
        operands['imm5'] = random.randint(-16, 15)
        
        # CSR addresses
        csr_addrs = ['mstatus', 'mie', 'mtvec', 'mepc', 'mcause', 'mcycle', 'minstret']
        operands['csr'] = random.choice(csr_addrs)
        
        # Labels for branches and jumps
        operands['label'] = f"label_{random.randint(1000, 9999)}"
        
        # Format the instruction
        instruction = f"{template.mnemonic} {template.operands.format(**operands)}"
        
        metadata = {
            'type': instr_type.value,
            'cycles': template.cycles,
            'description': template.description,
            'rd': operands.get('rd'),
            'rs1': operands.get('rs1'),
            'rs2': operands.get('rs2')
        }
        
        return instruction, metadata

    def generate_assembly_program(self, 
                                num_instructions: int,
                                distribution: Dict[InstructionType, int],
                                enable_hazards: bool = False,
                                enable_pulp: bool = False) -> Tuple[str, Dict]:
        """Generate a complete assembly program"""
        
        # Filter out PULP instructions if not enabled
        if not enable_pulp:
            distribution = {k: v for k, v in distribution.items() 
                          if k not in [InstructionType.PULP_ALU, InstructionType.PULP_SIMD, InstructionType.PULP_HWLOOP]}
        
        # Normalize distribution
        total_weight = sum(distribution.values())
        normalized_dist = {k: v/total_weight for k, v in distribution.items()}
        
        # Generate instruction sequence
        instructions = []
        metadata_list = []
        prev_rd = None
        
        # Program header
        program = [
            ".section .text",
            ".global _start",
            "_start:",
            "    # CV32E40P Generated Test Program",
            f"    # Instructions: {num_instructions}",
            f"    # Hazards enabled: {enable_hazards}",
            f"    # PULP enabled: {enable_pulp}",
            ""
        ]
        
        for i in range(num_instructions):
            # Select instruction type based on distribution
            rand_val = random.random()
            cumulative = 0
            selected_type = None
            
            for instr_type, weight in normalized_dist.items():
                cumulative += weight
                if rand_val <= cumulative:
                    selected_type = instr_type
                    break
            
            if selected_type is None:
                selected_type = list(normalized_dist.keys())[0]
            
            # Generate instruction
            instruction, metadata = self.generate_instruction(
                selected_type, enable_hazards, prev_rd)
            
            instructions.append(f"    {instruction}")
            metadata_list.append(metadata)
            prev_rd = metadata.get('rd')
            
            # Add occasional labels for branches
            if random.random() < 0.1:  # 10% chance
                instructions.append(f"label_{random.randint(1000, 9999)}:")
        
        # Program footer
        program.extend(instructions)
        program.extend([
            "",
            "    # End of program",
            "    nop",
            "    j _start  # Loop back for continuous testing",
            ""
        ])
        
        # Calculate statistics
        stats = {
            'total_instructions': num_instructions,
            'instruction_types': {},
            'estimated_cycles': 0,
            'estimated_ipc': 0
        }
        
        for metadata in metadata_list:
            instr_type = metadata['type']
            stats['instruction_types'][instr_type] = stats['instruction_types'].get(instr_type, 0) + 1
            stats['estimated_cycles'] += metadata['cycles']
        
        if stats['estimated_cycles'] > 0:
            stats['estimated_ipc'] = num_instructions / stats['estimated_cycles']
        
        return '\n'.join(program), stats

def main():
    parser = argparse.ArgumentParser(description='Generate CV32E40P assembly test programs')
    parser.add_argument('--output', '-o', default='test_program.s', 
                       help='Output assembly file')
    parser.add_argument('--instructions', '-n', type=int, default=100,
                       help='Number of instructions to generate')
    parser.add_argument('--distribution', '-d', 
                       choices=['default', 'performance', 'stress'], 
                       default='default',
                       help='Instruction distribution profile')
    parser.add_argument('--hazards', action='store_true',
                       help='Enable hazard injection')
    parser.add_argument('--pulp', action='store_true',
                       help='Enable PULP extensions')
    parser.add_argument('--stats', action='store_true',
                       help='Output statistics to JSON file')
    parser.add_argument('--seed', type=int,
                       help='Random seed for reproducible generation')
    
    args = parser.parse_args()
    
    if args.seed:
        random.seed(args.seed)
    
    generator = CV32E40PAssemblyGenerator()
    
    # Select distribution
    if args.distribution == 'performance':
        distribution = generator.performance_distribution
    elif args.distribution == 'stress':
        distribution = generator.stress_distribution
    else:
        distribution = generator.default_distribution
    
    # Generate program
    program, stats = generator.generate_assembly_program(
        args.instructions, distribution, args.hazards, args.pulp)
    
    # Write assembly file
    with open(args.output, 'w') as f:
        f.write(program)
    
    print(f"Generated {args.instructions} instructions in {args.output}")
    print(f"Estimated IPC: {stats['estimated_ipc']:.2f}")
    print(f"Estimated cycles: {stats['estimated_cycles']}")
    
    # Output statistics if requested
    if args.stats:
        stats_file = args.output.replace('.s', '_stats.json')
        with open(stats_file, 'w') as f:
            json.dump(stats, f, indent=2)
        print(f"Statistics written to {stats_file}")

if __name__ == '__main__':
    main()