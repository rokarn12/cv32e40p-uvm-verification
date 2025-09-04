# Makefile for CV32E40P UVM Testbench
# Uses JSON configuration file to determine test settings
# Copyright 2024 ChipAgents

# Default test (must match configuration file)
TEST ?= cv32e40p_basic_test

# Directories
TB_ROOT := $(shell pwd)
SCRIPTS_DIR := $(TB_ROOT)/scripts

# Default target
.PHONY: all
all: basic_test

# Run basic test
.PHONY: basic_test
basic_test:
	@echo "Running basic test using configuration file..."
	$(SCRIPTS_DIR)/run_test.py --test cv32e40p_basic_test

# Run edge case test
.PHONY: edge_test
edge_test:
	@echo "Running edge case test using configuration file..."
	$(SCRIPTS_DIR)/run_test.py --test cv32e40p_edge_test

# Run comprehensive test
.PHONY: comprehensive_test
comprehensive_test:
	@echo "Running comprehensive test using configuration file..."
	$(SCRIPTS_DIR)/run_test.py --test cv32e40p_comprehensive_test

# Run FPU test
.PHONY: fpu_test
fpu_test:
	@echo "Running FPU test using configuration file..."
	$(SCRIPTS_DIR)/run_test.py --test cv32e40p_fpu_test

# Run any test by name
.PHONY: test
test:
	@echo "Running test: $(TEST)"
	$(SCRIPTS_DIR)/run_test.py --test $(TEST)

# List available tests from configuration file
.PHONY: list
list:
	$(SCRIPTS_DIR)/run_test.py --list-tests

# Show configuration for a specific test
.PHONY: show_config
show_config:
	@echo "Configuration for test: $(TEST)"
	@python3 -c "import json; data=json.load(open('config/test_config.json')); print(json.dumps(data['test_configurations']['$(TEST)'], indent=2))"

# Validate configuration file
.PHONY: validate_config
validate_config:
	@echo "Validating configuration file..."
	@python3 -c "import json; json.load(open('config/test_config.json')); print('Configuration file is valid JSON')"

# Clean work directory
.PHONY: clean
clean:
	@echo "Cleaning work directory..."
	rm -rf work/
	rm -f *.log *.vcd

# Help
.PHONY: help
help:
	@echo "CV32E40P UVM Testbench Makefile (Configuration-Driven)"
	@echo ""
	@echo "This testbench uses config/test_config.json to determine test settings."
	@echo ""
	@echo "Targets:"
	@echo "  all               - Run basic test (default)"
	@echo "  basic_test        - Run basic ALU test"
	@echo "  edge_test         - Run edge case test"
	@echo "  comprehensive_test- Run comprehensive test with all features"
	@echo "  fpu_test          - Run test with FPU enabled"
	@echo "  test              - Run test specified by TEST variable"
	@echo "  list              - List available test configurations"
	@echo "  show_config       - Show configuration for TEST"
	@echo "  validate_config   - Validate JSON configuration file"
	@echo "  clean             - Clean work directory"
	@echo "  help              - Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  TEST        - Test name to run (default: cv32e40p_basic_test)"
	@echo ""
	@echo "Examples:"
	@echo "  make basic_test"
	@echo "  make test TEST=cv32e40p_fpu_test"
	@echo "  make show_config TEST=cv32e40p_edge_test"
	@echo "  make list"
	@echo ""
	@echo "Configuration File: config/test_config.json"
	@echo "  - Contains all test parameters, DUT configuration, and build options"
	@echo "  - Modify this file to change test behavior"