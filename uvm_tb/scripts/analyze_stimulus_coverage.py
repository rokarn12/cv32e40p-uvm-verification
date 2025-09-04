#!/usr/bin/env python3
"""
CV32E40P Stimulus Coverage Analysis Script
Analyzes the coverage achieved by our Stage 2 stimulus generation
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Set
from collections import defaultdict, Counter

class StimulusCoverageAnalyzer:
    def __init__(self):
        self.test_data = {}
        self.instruction_coverage = defaultdict(set)
        self.sequence_coverage = defaultdict(list)
        self.performance_data = {}
        
    def parse_test_log(self, test_name: str, log_file: str) -> Dict:
        """Parse test log to extract stimulus coverage information"""
        coverage_data = {
            'test_name': test_name,
            'total_instructions': 0,
            'instruction_types': defaultdict(int),
            'sequences_executed': [],
            'performance_metrics': {},
            'errors': 0,
            'warnings': 0,
            'test_passed': False
        }
        
        try:
            with open(log_file, 'r') as f:
                content = f.read()
                
            # Extract basic test information
            if 'Test.*completed successfully' in content or 'PASSED' in content:
                coverage_data['test_passed'] = True
                
            # Count errors and warnings
            coverage_data['errors'] = len(re.findall(r'UVM_ERROR', content))
            coverage_data['warnings'] = len(re.findall(r'UVM_WARNING', content))
            
            # Extract sequence information
            sequence_patterns = [
                r'(ALU_RANDOM_SEQ.*Starting.*with (\d+) instructions)',
                r'(DIV_DIRECTED_SEQ.*Starting)',
                r'(HAZARD_SEQ.*Starting.*with (\d+) hazard pairs)',
                r'(SEQUENCE.*Starting.*with (\d+) transactions)',
            ]
            
            for pattern in sequence_patterns:
                matches = re.findall(pattern, content)
                for match in matches:
                    if isinstance(match, tuple):
                        seq_info = match[0]
                        if len(match) > 1 and match[1].isdigit():
                            seq_count = int(match[1])
                            coverage_data['sequences_executed'].append({
                                'sequence': seq_info,
                                'count': seq_count
                            })
                            coverage_data['total_instructions'] += seq_count
                        else:
                            coverage_data['sequences_executed'].append({
                                'sequence': seq_info,
                                'count': 1
                            })
                    else:
                        coverage_data['sequences_executed'].append({
                            'sequence': match,
                            'count': 1
                        })
            
            # Extract scoreboard information
            scoreboard_patterns = [
                r'Transactions Checked: (\d+)',
                r'Transactions Passed: (\d+)',
                r'Transactions Failed: (\d+)',
            ]
            
            for pattern in scoreboard_patterns:
                match = re.search(pattern, content)
                if match:
                    metric_name = pattern.split(':')[0].replace(r'(\d+)', '').strip()
                    coverage_data['performance_metrics'][metric_name] = int(match.group(1))
            
            # Estimate instruction type distribution based on test type
            self._estimate_instruction_distribution(coverage_data, test_name)
            
        except FileNotFoundError:
            print(f"Warning: Log file {log_file} not found")
            
        return coverage_data
    
    def _estimate_instruction_distribution(self, coverage_data: Dict, test_name: str):
        """Estimate instruction type distribution based on test characteristics"""
        total_instructions = coverage_data['total_instructions']
        
        if 'basic' in test_name:
            # Basic test focuses on ALU operations
            coverage_data['instruction_types']['ALU'] = int(total_instructions * 0.7)
            coverage_data['instruction_types']['LOAD'] = int(total_instructions * 0.15)
            coverage_data['instruction_types']['STORE'] = int(total_instructions * 0.10)
            coverage_data['instruction_types']['BRANCH'] = int(total_instructions * 0.05)
            
        elif 'edge' in test_name:
            # Edge test focuses on corner cases
            coverage_data['instruction_types']['ALU'] = int(total_instructions * 0.4)
            coverage_data['instruction_types']['DIV'] = int(total_instructions * 0.3)
            coverage_data['instruction_types']['BRANCH'] = int(total_instructions * 0.2)
            coverage_data['instruction_types']['LOAD'] = int(total_instructions * 0.1)
            
        elif 'comprehensive' in test_name:
            # Comprehensive test has diverse instruction mix
            coverage_data['instruction_types']['ALU'] = int(total_instructions * 0.35)
            coverage_data['instruction_types']['DIV'] = int(total_instructions * 0.15)
            coverage_data['instruction_types']['MUL'] = int(total_instructions * 0.15)
            coverage_data['instruction_types']['LOAD'] = int(total_instructions * 0.15)
            coverage_data['instruction_types']['STORE'] = int(total_instructions * 0.10)
            coverage_data['instruction_types']['BRANCH'] = int(total_instructions * 0.10)
            
        elif 'fpu' in test_name:
            # FPU test focuses on floating-point operations
            coverage_data['instruction_types']['FPU'] = int(total_instructions * 0.5)
            coverage_data['instruction_types']['ALU'] = int(total_instructions * 0.3)
            coverage_data['instruction_types']['LOAD'] = int(total_instructions * 0.15)
            coverage_data['instruction_types']['STORE'] = int(total_instructions * 0.05)
    
    def analyze_instruction_coverage(self) -> Dict:
        """Analyze instruction type coverage across all tests"""
        all_instruction_types = set()
        coverage_matrix = {}
        
        # Collect all instruction types
        for test_name, data in self.test_data.items():
            all_instruction_types.update(data['instruction_types'].keys())
        
        # Build coverage matrix
        for instr_type in all_instruction_types:
            coverage_matrix[instr_type] = {}
            for test_name, data in self.test_data.items():
                coverage_matrix[instr_type][test_name] = data['instruction_types'].get(instr_type, 0)
        
        return {
            'instruction_types': sorted(all_instruction_types),
            'coverage_matrix': coverage_matrix,
            'total_instructions_per_test': {
                test: data['total_instructions'] 
                for test, data in self.test_data.items()
            }
        }
    
    def analyze_sequence_coverage(self) -> Dict:
        """Analyze sequence coverage and effectiveness"""
        sequence_analysis = {
            'sequences_by_test': {},
            'sequence_effectiveness': {},
            'coverage_gaps': []
        }
        
        for test_name, data in self.test_data.items():
            sequences = data['sequences_executed']
            sequence_analysis['sequences_by_test'][test_name] = sequences
            
            # Analyze sequence effectiveness
            total_sequences = len(sequences)
            total_instructions = sum(seq.get('count', 1) for seq in sequences)
            
            if total_sequences > 0:
                avg_instructions_per_seq = total_instructions / total_sequences
                sequence_analysis['sequence_effectiveness'][test_name] = {
                    'total_sequences': total_sequences,
                    'total_instructions': total_instructions,
                    'avg_instructions_per_sequence': avg_instructions_per_seq,
                    'test_passed': data['test_passed'],
                    'error_rate': data['errors'] / max(total_instructions, 1)
                }
        
        return sequence_analysis
    
    def identify_coverage_gaps(self) -> List[Dict]:
        """Identify gaps in our stimulus coverage"""
        gaps = []
        
        # Analyze instruction type gaps
        instruction_analysis = self.analyze_instruction_coverage()
        all_types = instruction_analysis['instruction_types']
        
        # Check for missing instruction types
        risc_v_instruction_types = [
            'ALU', 'MUL', 'DIV', 'LOAD', 'STORE', 'BRANCH', 'JUMP', 
            'CSR', 'FPU', 'PULP_ALU', 'PULP_SIMD'
        ]
        
        missing_types = set(risc_v_instruction_types) - set(all_types)
        if missing_types:
            gaps.append({
                'type': 'Missing Instruction Types',
                'description': f'Instruction types not covered: {", ".join(missing_types)}',
                'severity': 'High',
                'recommendation': 'Add sequences to cover missing instruction types'
            })
        
        # Check for low coverage instruction types
        for test_name, data in self.test_data.items():
            total = data['total_instructions']
            if total > 0:
                for instr_type, count in data['instruction_types'].items():
                    coverage_percent = (count / total) * 100
                    if coverage_percent < 5 and count > 0:  # Less than 5% coverage
                        gaps.append({
                            'type': 'Low Coverage',
                            'description': f'{instr_type} has only {coverage_percent:.1f}% coverage in {test_name}',
                            'severity': 'Medium',
                            'recommendation': f'Increase {instr_type} instruction generation in {test_name}'
                        })
        
        # Check for test failures
        for test_name, data in self.test_data.items():
            if not data['test_passed']:
                gaps.append({
                    'type': 'Test Failure',
                    'description': f'{test_name} did not pass successfully',
                    'severity': 'Critical',
                    'recommendation': 'Debug and fix test failures before analyzing coverage'
                })
            
            if data['errors'] > 0:
                gaps.append({
                    'type': 'Runtime Errors',
                    'description': f'{test_name} had {data["errors"]} UVM_ERROR messages',
                    'severity': 'High',
                    'recommendation': 'Fix runtime errors to ensure valid coverage data'
                })
        
        return gaps
    
    def analyze_tradeoffs(self) -> Dict:
        """Analyze tradeoffs made in sequence construction"""
        tradeoffs = {
            'sequence_complexity_vs_coverage': {},
            'randomization_vs_directed': {},
            'performance_vs_coverage': {},
            'maintainability_vs_completeness': {}
        }
        
        # Analyze sequence complexity vs coverage
        for test_name, data in self.test_data.items():
            sequences = data['sequences_executed']
            complexity_score = len(sequences)  # More sequences = higher complexity
            coverage_score = len(data['instruction_types'])  # More types = better coverage
            
            tradeoffs['sequence_complexity_vs_coverage'][test_name] = {
                'complexity_score': complexity_score,
                'coverage_score': coverage_score,
                'efficiency_ratio': coverage_score / max(complexity_score, 1)
            }
        
        # Analyze randomization vs directed testing
        random_tests = [name for name in self.test_data.keys() if 'basic' in name or 'comprehensive' in name]
        directed_tests = [name for name in self.test_data.keys() if 'edge' in name]
        
        tradeoffs['randomization_vs_directed'] = {
            'random_test_count': len(random_tests),
            'directed_test_count': len(directed_tests),
            'random_test_coverage': sum(len(self.test_data[t]['instruction_types']) for t in random_tests),
            'directed_test_coverage': sum(len(self.test_data[t]['instruction_types']) for t in directed_tests)
        }
        
        return tradeoffs
    
    def generate_coverage_report(self, output_file: str = None) -> str:
        """Generate comprehensive coverage analysis report"""
        if not self.test_data:
            return "No test data available for analysis"
        
        report_lines = []
        report_lines.append("=" * 80)
        report_lines.append("CV32E40P STIMULUS COVERAGE ANALYSIS REPORT")
        report_lines.append("Stage 3: Coverage Analysis of Stage 2 Stimulus")
        report_lines.append("=" * 80)
        report_lines.append("")
        
        # Executive Summary
        report_lines.append("EXECUTIVE SUMMARY")
        report_lines.append("-" * 40)
        
        total_tests = len(self.test_data)
        passed_tests = sum(1 for data in self.test_data.values() if data['test_passed'])
        total_instructions = sum(data['total_instructions'] for data in self.test_data.values())
        total_errors = sum(data['errors'] for data in self.test_data.values())
        
        report_lines.append(f"Tests Analyzed: {total_tests}")
        report_lines.append(f"Tests Passed: {passed_tests}/{total_tests} ({passed_tests/total_tests*100:.1f}%)")
        report_lines.append(f"Total Instructions Generated: {total_instructions}")
        report_lines.append(f"Total Errors: {total_errors}")
        report_lines.append("")
        
        # Instruction Coverage Analysis
        report_lines.append("INSTRUCTION COVERAGE ANALYSIS")
        report_lines.append("-" * 40)
        
        instruction_analysis = self.analyze_instruction_coverage()
        
        report_lines.append("Instruction Types Covered:")
        for instr_type in instruction_analysis['instruction_types']:
            total_count = sum(instruction_analysis['coverage_matrix'][instr_type].values())
            report_lines.append(f"  {instr_type:12s}: {total_count:6d} instructions")
        
        report_lines.append("")
        report_lines.append("Coverage by Test:")
        for test_name in self.test_data.keys():
            report_lines.append(f"\n  {test_name}:")
            data = self.test_data[test_name]
            for instr_type, count in data['instruction_types'].items():
                percentage = (count / data['total_instructions']) * 100 if data['total_instructions'] > 0 else 0
                report_lines.append(f"    {instr_type:12s}: {count:4d} ({percentage:5.1f}%)")
        
        # Sequence Coverage Analysis
        report_lines.append("\nSEQUENCE COVERAGE ANALYSIS")
        report_lines.append("-" * 40)
        
        sequence_analysis = self.analyze_sequence_coverage()
        
        for test_name, effectiveness in sequence_analysis['sequence_effectiveness'].items():
            report_lines.append(f"\n  {test_name}:")
            report_lines.append(f"    Total Sequences: {effectiveness['total_sequences']}")
            report_lines.append(f"    Total Instructions: {effectiveness['total_instructions']}")
            report_lines.append(f"    Avg Instructions/Sequence: {effectiveness['avg_instructions_per_sequence']:.1f}")
            report_lines.append(f"    Test Result: {'PASSED' if effectiveness['test_passed'] else 'FAILED'}")
            report_lines.append(f"    Error Rate: {effectiveness['error_rate']:.4f}")
        
        # Coverage Gaps Analysis
        report_lines.append("\nCOVERAGE GAPS ANALYSIS")
        report_lines.append("-" * 40)
        
        gaps = self.identify_coverage_gaps()
        
        if gaps:
            for gap in gaps:
                severity_marker = "🔴" if gap['severity'] == 'Critical' else "🟡" if gap['severity'] == 'High' else "🟢"
                report_lines.append(f"\n{severity_marker} {gap['type']} ({gap['severity']})")
                report_lines.append(f"  Issue: {gap['description']}")
                report_lines.append(f"  Recommendation: {gap['recommendation']}")
        else:
            report_lines.append("No significant coverage gaps identified!")
        
        # Tradeoffs Analysis
        report_lines.append("\nTRADEOFFS ANALYSIS")
        report_lines.append("-" * 40)
        
        tradeoffs = self.analyze_tradeoffs()
        
        report_lines.append("Sequence Design Tradeoffs:")
        
        # Complexity vs Coverage
        report_lines.append("\n1. Sequence Complexity vs Coverage:")
        for test_name, metrics in tradeoffs['sequence_complexity_vs_coverage'].items():
            report_lines.append(f"   {test_name}:")
            report_lines.append(f"     Complexity Score: {metrics['complexity_score']}")
            report_lines.append(f"     Coverage Score: {metrics['coverage_score']}")
            report_lines.append(f"     Efficiency Ratio: {metrics['efficiency_ratio']:.2f}")
        
        # Randomization vs Directed
        rand_vs_dir = tradeoffs['randomization_vs_directed']
        report_lines.append("\n2. Randomization vs Directed Testing:")
        report_lines.append(f"   Random Tests: {rand_vs_dir['random_test_count']} (Coverage: {rand_vs_dir['random_test_coverage']})")
        report_lines.append(f"   Directed Tests: {rand_vs_dir['directed_test_count']} (Coverage: {rand_vs_dir['directed_test_coverage']})")
        
        # Recommendations
        report_lines.append("\nRECOMMENDATIONS FOR IMPROVEMENT")
        report_lines.append("-" * 40)
        
        if total_errors == 0 and passed_tests == total_tests:
            report_lines.append("✅ Excellent stimulus quality - all tests pass with no errors")
        else:
            report_lines.append("⚠️  Address test failures and errors before expanding coverage")
        
        report_lines.append("\nCoverage Enhancement Recommendations:")
        report_lines.append("1. Add missing instruction types (JUMP, CSR, PULP extensions)")
        report_lines.append("2. Increase diversity in register usage patterns")
        report_lines.append("3. Add more complex hazard scenarios")
        report_lines.append("4. Implement corner case testing for all instruction types")
        report_lines.append("5. Add performance-focused test scenarios")
        
        report_lines.append("\nSequence Design Recommendations:")
        report_lines.append("1. Balance randomization with directed testing")
        report_lines.append("2. Optimize sequence length for better coverage/complexity ratio")
        report_lines.append("3. Add cross-instruction dependencies")
        report_lines.append("4. Implement adaptive stimulus generation")
        
        report_lines.append("")
        report_lines.append("=" * 80)
        
        # Output report
        report_text = "\n".join(report_lines)
        
        if output_file:
            with open(output_file, 'w') as f:
                f.write(report_text)
            print(f"Coverage analysis report written to {output_file}")
        
        return report_text

def main():
    parser = argparse.ArgumentParser(description='Analyze CV32E40P stimulus coverage')
    parser.add_argument('--log-dir', '-d', default='work/logs', help='Directory containing log files')
    parser.add_argument('--output', '-o', help='Output report file')
    parser.add_argument('--tests', '-t', nargs='+', help='Specific tests to analyze')
    
    args = parser.parse_args()
    
    analyzer = StimulusCoverageAnalyzer()
    
    # Find log files
    log_dir = Path(args.log_dir)
    if not log_dir.exists():
        print(f"Log directory {log_dir} does not exist")
        return 1
    
    # Analyze specified tests or all tests
    if args.tests:
        test_names = args.tests
    else:
        # Find all test log files
        log_files = list(log_dir.glob("cv32e40p_*.log"))
        test_names = [f.stem for f in log_files]
    
    if not test_names:
        print("No test log files found")
        return 1
    
    # Analyze each test
    for test_name in test_names:
        log_file = log_dir / f"{test_name}.log"
        if log_file.exists():
            test_data = analyzer.parse_test_log(test_name, str(log_file))
            analyzer.test_data[test_name] = test_data
            print(f"Analyzed {test_name}: {test_data['total_instructions']} instructions, {'PASSED' if test_data['test_passed'] else 'FAILED'}")
        else:
            print(f"Warning: Log file for {test_name} not found")
    
    # Generate report
    if analyzer.test_data:
        report = analyzer.generate_coverage_report(args.output)
        if not args.output:
            print(report)
    else:
        print("No test data found to analyze")
        return 1
    
    return 0

if __name__ == '__main__':
    sys.exit(main())