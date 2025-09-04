#!/usr/bin/env python3
"""
Build and run script for CV32E40P UVM Testbench
Uses JSON configuration file to determine test settings
Copyright 2024 ChipAgents
"""

import os
import sys
import json
import argparse
import subprocess
from pathlib import Path

class CV32E40PTestRunner:
    def __init__(self):
        self.script_dir = Path(__file__).parent
        self.tb_root = self.script_dir.parent
        self.cv32e40p_root = self.tb_root.parent
        self.config_file = self.tb_root / "config" / "test_config.json"
        self.work_dir = self.tb_root / "work"
        self.config_data = None
        
    def load_config(self):
        """Load configuration from JSON file"""
        try:
            with open(self.config_file, 'r') as f:
                self.config_data = json.load(f)
            print(f"Loaded configuration from: {self.config_file}")
            return True
        except FileNotFoundError:
            print(f"Error: Configuration file not found: {self.config_file}")
            return False
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in configuration file: {e}")
            return False
    
    def list_available_tests(self):
        """List all available test configurations"""
        if not self.load_config():
            return False
            
        print("Available test configurations:")
        print("=" * 50)
        for test_name, config in self.config_data["test_configurations"].items():
            print(f"  {test_name}")
            print(f"    Description: {config['description']}")
            print(f"    Test Class:  {config['test_class']}")
            print(f"    Sequence:    {config['sequence']}")
            print(f"    Coverage:    {config['enable_coverage']}")
            print(f"    Waves:       {config['build_options']['enable_waves']}")
            print()
        return True
    
    def get_test_config(self, test_name):
        """Get configuration for a specific test"""
        if not self.load_config():
            return None
            
        if test_name not in self.config_data["test_configurations"]:
            print(f"Error: Test '{test_name}' not found in configuration file")
            print("Available tests:")
            for name in self.config_data["test_configurations"].keys():
                print(f"  - {name}")
            return None
            
        return self.config_data["test_configurations"][test_name]
    
    def setup_environment(self, test_config):
        """Setup the test environment"""
        # Create work directory
        self.work_dir.mkdir(exist_ok=True)
        
        # Create additional directories
        for dir_name in ["logs", "coverage", "waves"]:
            (self.work_dir / dir_name).mkdir(exist_ok=True)
        
        os.chdir(self.work_dir)
        
        # Set environment variables
        os.environ['DESIGN_RTL_DIR'] = str(self.cv32e40p_root / "rtl")
        
        print(f"Work directory: {self.work_dir}")
        
    def get_file_lists(self):
        """Get all required source files"""
        rtl_files = []
        
        # CV32E40P RTL files
        manifest_file = self.cv32e40p_root / "cv32e40p_manifest.flist"
        if manifest_file.exists():
            with open(manifest_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('//') and not line.startswith('+'):
                        # Expand environment variables
                        expanded_line = os.path.expandvars(line)
                        rtl_files.append(expanded_line)
        
        # UVM testbench files
        tb_files = [
            str(self.tb_root / "src" / "cv32e40p_if.sv"),
            str(self.tb_root / "src" / "cv32e40p_pkg.sv"),
            str(self.tb_root / "src" / "tb_top.sv")
        ]
        
        return rtl_files, tb_files
    
    def build_plusargs_from_config(self, test_config):
        """Build simulation plusargs from test configuration"""
        plusargs = []
        
        # Test identification
        plusargs.append(f"+TEST_NAME={test_config.get('test_class', '')}")
        plusargs.append(f"+DESCRIPTION={test_config.get('description', '')}")
        plusargs.append(f"+TEST_CLASS={test_config.get('test_class', '')}")
        plusargs.append(f"+SEQUENCE={test_config.get('sequence', '')}")
        plusargs.append(f"+VERBOSITY={test_config.get('verbosity', 'UVM_LOW')}")
        
        # Boolean flags
        if test_config.get('enable_coverage', False):
            plusargs.append("+ENABLE_COVERAGE")
        if test_config.get('enable_assertions', False):
            plusargs.append("+ENABLE_ASSERTIONS")
        if test_config.get('enable_scoreboard', False):
            plusargs.append("+ENABLE_SCOREBOARD")
        if test_config.get('enable_logging', False):
            plusargs.append("+ENABLE_LOGGING")
        if test_config.get('build_options', {}).get('enable_waves', False):
            plusargs.append("+ENABLE_WAVES")
        if test_config.get('build_options', {}).get('enable_debug', False):
            plusargs.append("+ENABLE_DEBUG")
        
        # DUT configuration
        dut_config = test_config.get('dut_config', {})
        for key, value in dut_config.items():
            plusargs.append(f"+{key}={value}")
        
        # Simulation parameters
        plusargs.append(f"+MAX_CYCLES={test_config.get('max_cycles', 1000)}")
        plusargs.append(f"+TIMEOUT_CYCLES={test_config.get('timeout_cycles', 5000)}")
        plusargs.append(f"+NUM_RANDOM_INSTRUCTIONS={test_config.get('num_random_instructions', 10)}")
        
        # ALU configuration
        alu_config = test_config.get('alu_config', {})
        if alu_config.get('focus_alu_testing', False):
            plusargs.append("+FOCUS_ALU_TESTING")
        if alu_config.get('enable_vector_ops', False):
            plusargs.append("+ENABLE_VECTOR_OPS")
        if alu_config.get('enable_div_ops', False):
            plusargs.append("+ENABLE_DIV_OPS")
        if alu_config.get('enable_bit_manip', False):
            plusargs.append("+ENABLE_BIT_MANIP")
        
        # Build options
        build_options = test_config.get('build_options', {})
        plusargs.append(f"+OPTIMIZATION_LEVEL={build_options.get('optimization_level', 'none')}")
        
        return plusargs
    
    def compile_vcs(self, test_name, test_config):
        """Compile with VCS using configuration"""
        print(f"Compiling with VCS for test: {test_name}")
        print(f"Description: {test_config['description']}")
        
        rtl_files, tb_files = self.get_file_lists()
        
        # Get default compile options
        default_config = self.config_data.get("default_config", {})
        compile_options = default_config.get("compile_options", [])
        
        # VCS compile command with UVM support
        uvm_home = "/home/ubuntu/tools/synopsys/tools/verdi/W-2024.09-SP1/etc/uvm-1.2"
        vcs_cmd = ["vcs"] + compile_options + [
            "-ntb_opts", "uvm-1.2",
            f"+incdir+{self.cv32e40p_root}/rtl/include",
            f"+incdir+{self.cv32e40p_root}/bhv/include",
            f"+incdir+{self.tb_root}/config",
            f"+incdir+{self.tb_root}/sequences",
            f"+incdir+{self.tb_root}/agents",
            f"+incdir+{self.tb_root}/env",
            f"+incdir+{self.tb_root}/tests",
            f"+incdir+{self.tb_root}/coverage",
        ]
        
        # Add coverage options
        if test_config.get('enable_coverage', False):
            vcs_cmd.extend([
                "-cm", "line+cond+fsm+branch+tgl",
                "-cm_name", f"{test_name}_coverage",
                "-cm_dir", "./coverage"
            ])
        
        # Add wave dumping
        if test_config.get('build_options', {}).get('enable_waves', False):
            vcs_cmd.append("+define+DUMP_WAVES")
        
        # Add DUT parameter overrides
        dut_config = test_config.get('dut_config', {})
        for param, value in dut_config.items():
            vcs_cmd.append(f"-pvalue+tb_top.dut_if.dut.{param}={value}")
        
        # Add all source files
        vcs_cmd.extend(rtl_files)
        vcs_cmd.extend(tb_files)
        
        # Output executable name
        vcs_cmd.extend(["-o", f"{test_name}_simv"])
        
        print("VCS Command:", " ".join(vcs_cmd))
        
        try:
            result = subprocess.run(vcs_cmd, check=True, capture_output=True, text=True)
            print("Compilation successful!")
            return True
        except subprocess.CalledProcessError as e:
            print(f"Compilation failed: {e}")
            print("STDOUT:", e.stdout)
            print("STDERR:", e.stderr)
            return False
    
    def run_simulation(self, test_name, test_config):
        """Run the simulation using configuration"""
        print(f"Running simulation: {test_name}")
        
        # Build plusargs from configuration
        plusargs = self.build_plusargs_from_config(test_config)
        
        # Get default simulation options
        default_config = self.config_data.get("default_config", {})
        sim_options = default_config.get("simulation_options", [])
        
        sim_cmd = [f"./{test_name}_simv"] + sim_options + [
            f"+UVM_TESTNAME={test_config['test_class']}",
            f"+UVM_VERBOSITY={test_config.get('verbosity', 'UVM_LOW')}",
            "-l", f"./logs/{test_name}.log"
        ] + plusargs
        
        # Add coverage options
        if test_config.get('enable_coverage', False):
            sim_cmd.extend([
                "-cm", "line+cond+fsm+branch+tgl",
                "-cm_name", f"{test_name}_coverage",
                "-cm_dir", "./coverage"
            ])
        
        print("Simulation Command:", " ".join(sim_cmd))
        
        try:
            result = subprocess.run(sim_cmd, check=True, capture_output=True, text=True)
            print("Simulation completed successfully!")
            print("STDOUT:", result.stdout)
            return True
        except subprocess.CalledProcessError as e:
            print(f"Simulation failed: {e}")
            print("STDOUT:", e.stdout)
            print("STDERR:", e.stderr)
            return False
    
    def run_test(self, test_name):
        """Complete test flow: load config, compile and run"""
        # Get test configuration
        test_config = self.get_test_config(test_name)
        if not test_config:
            return False
        
        # Setup environment
        self.setup_environment(test_config)
        
        print(f"Starting test flow for: {test_name}")
        print(f"Configuration: {test_config['description']}")
        
        # Compile
        if not self.compile_vcs(test_name, test_config):
            return False
        
        # Run
        if not self.run_simulation(test_name, test_config):
            return False
        
        print(f"Test {test_name} completed successfully!")
        return True

def main():
    parser = argparse.ArgumentParser(description="CV32E40P UVM Test Runner")
    parser.add_argument("--test", default="cv32e40p_basic_test", 
                       help="Test name to run (from configuration file)")
    parser.add_argument("--list-tests", action="store_true",
                       help="List available test configurations")
    parser.add_argument("--config", 
                       help="Override default configuration file path")
    
    args = parser.parse_args()
    
    runner = CV32E40PTestRunner()
    
    # Override config file if specified
    if args.config:
        runner.config_file = Path(args.config)
    
    if args.list_tests:
        return 0 if runner.list_available_tests() else 1
    
    success = runner.run_test(args.test)
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())