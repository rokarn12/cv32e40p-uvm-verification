# Project Structure

```
cv32e40p-uvm-verification/
├── .github/workflows/          # GitHub Actions CI/CD
├── rtl/                        # Essential RTL components
│   ├── include/               # RTL packages and includes
│   ├── cv32e40p_top.sv       # Top-level module
│   └── cv32e40p_core.sv      # Core processor module
├── uvm_tb/                    # UVM Verification Environment
│   ├── agents/               # UVM agents (driver, monitor)
│   ├── config/               # JSON configuration files
│   ├── coverage/             # Coverage models and analysis
│   ├── env/                  # UVM environment
│   ├── scripts/              # Python test and analysis scripts
│   ├── sequences/            # UVM sequences and instruction items
│   ├── src/                  # RTL interfaces
│   ├── tests/                # UVM test classes
│   └── interview-notes/      # Interview preparation materials
├── README.md                 # Main documentation
├── LICENSE                   # MIT License
├── .gitignore               # Git ignore rules
└── STRUCTURE.md             # This file
```

## Key Components

### UVM Testbench (`uvm_tb/`)
- **Enhanced Instruction Item**: 14 instruction categories with intelligent constraints
- **Three Sequence Types**: ALU random, division directed, hazard injection
- **Coverage Model**: Simple but effective with manual sampling
- **Python Analysis**: Automated coverage analysis and reporting

### Scripts (`uvm_tb/scripts/`)
- `run_test.py`: Main test execution script
- `analyze_stimulus_coverage.py`: Coverage analysis engine
- `generate_assembly.py`: Assembly generation utilities

### Configuration (`uvm_tb/config/`)
- `test_config.json`: JSON-driven test configuration
- `cv32e40p_config.sv`: SystemVerilog configuration class

### Interview Materials (`uvm_tb/interview-notes/`)
- `QUICK_REFERENCE.md`: 10-minute project overview
- `IMPLEMENTATION_GUIDE.md`: Technical implementation details
