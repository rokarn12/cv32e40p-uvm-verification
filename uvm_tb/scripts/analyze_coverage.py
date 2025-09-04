#!/usr/bin/env python3
"""
CV32E40P Coverage Analysis Script
Analyzes functional coverage results from UVM testbench runs
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple
import matplotlib.pyplot as plt
import numpy as np

class CoverageAnalyzer:
    def __init__(self):
        self.coverage_data = {}
        self.test_results = {}
        
    def parse_uvm_log(self, log_file: str) -> Dict:
        """Parse UVM log file to extract coverage information"""
        coverage_info = {
            'instruction_type': {},
            'alu_operations': {},
            'register_usage': {},
            'immediate_values': {},
            'branch_conditions': {},
            'memory_access': {},
            'corner_cases': {},
            'hazard_scenarios': {},
            'performance_scenarios': {},
            'overall_coverage': 0.0,
            'total_instructions': 0
        }
        
        try:
            with open(log_file, 'r') as f:
                content = f.read()
                
            # Extract coverage percentages
            coverage_patterns = {
                'instruction_type': r'instruction_type Coverage: ([\d.]+)%',
                'alu_operations': r'alu_operations Coverage: ([\d.]+)%',
                'register_usage': r'register_usage Coverage: ([\d.]+)%',
                'immediate_values': r'immediate_values Coverage: ([\d.]+)%',
                'branch_conditions': r'branch_conditions Coverage: ([\d.]+)%',
                'memory_access': r'memory_access Coverage: ([\d.]+)%',
                'corner_cases': r'corner_cases Coverage: ([\d.]+)%',
                'hazard_scenarios': r'hazard_scenarios Coverage: ([\d.]+)%',
                'performance_scenarios': r'performance_scenarios Coverage: ([\d.]+)%',
            }
            
            for category, pattern in coverage_patterns.items():
                match = re.search(pattern, content)
                if match:
                    coverage_info[category] = float(match.group(1))
                    
            # Extract overall coverage
            overall_match = re.search(r'Overall Functional Coverage: ([\d.]+)%', content)
            if overall_match:
                coverage_info['overall_coverage'] = float(overall_match.group(1))
                
            # Extract instruction count
            instr_match = re.search(r'Total Instructions Processed: (\d+)', content)
            if instr_match:
                coverage_info['total_instructions'] = int(instr_match.group(1))
                
        except FileNotFoundError:
            print(f"Warning: Log file {log_file} not found")
            
        return coverage_info
    
    def analyze_test_coverage(self, test_name: str, log_file: str) -> Dict:
        """Analyze coverage for a specific test"""
        print(f"Analyzing coverage for test: {test_name}")
        
        coverage_data = self.parse_uvm_log(log_file)
        self.coverage_data[test_name] = coverage_data
        
        return coverage_data
    
    def compare_test_coverage(self, test_results: Dict[str, Dict]) -> Dict:
        """Compare coverage across multiple tests"""
        comparison = {
            'categories': [],
            'tests': list(test_results.keys()),
            'coverage_matrix': []
        }
        
        # Get all coverage categories
        if test_results:
            first_test = list(test_results.values())[0]
            comparison['categories'] = [cat for cat in first_test.keys() 
                                     if cat not in ['overall_coverage', 'total_instructions']]
        
        # Build coverage matrix
        for category in comparison['categories']:
            row = []
            for test_name in comparison['tests']:
                coverage = test_results[test_name].get(category, 0.0)
                row.append(coverage)
            comparison['coverage_matrix'].append(row)
            
        return comparison
    
    def identify_coverage_gaps(self, coverage_data: Dict) -> List[Tuple[str, float]]:
        """Identify areas with low coverage"""
        gaps = []
        threshold = 80.0  # Coverage threshold
        
        for category, coverage in coverage_data.items():
            if isinstance(coverage, (int, float)) and category != 'total_instructions':
                if coverage < threshold:
                    gaps.append((category, coverage))
                    
        # Sort by coverage percentage (lowest first)
        gaps.sort(key=lambda x: x[1])
        return gaps
    
    def generate_coverage_report(self, output_file: str = None):
        """Generate comprehensive coverage report"""
        if not self.coverage_data:
            print("No coverage data available")
            return
            
        report_lines = []
        report_lines.append("=" * 80)
        report_lines.append("CV32E40P FUNCTIONAL COVERAGE ANALYSIS REPORT")
        report_lines.append("=" * 80)
        report_lines.append("")
        
        # Overall summary
        report_lines.append("OVERALL SUMMARY")
        report_lines.append("-" * 40)
        
        total_instructions = 0
        avg_coverage = 0.0
        
        for test_name, data in self.coverage_data.items():
            total_instructions += data.get('total_instructions', 0)
            avg_coverage += data.get('overall_coverage', 0.0)
            
        if self.coverage_data:
            avg_coverage /= len(self.coverage_data)
            
        report_lines.append(f"Total Tests Analyzed: {len(self.coverage_data)}")
        report_lines.append(f"Total Instructions Processed: {total_instructions}")
        report_lines.append(f"Average Overall Coverage: {avg_coverage:.2f}%")
        report_lines.append("")
        
        # Per-test analysis
        report_lines.append("PER-TEST COVERAGE ANALYSIS")
        report_lines.append("-" * 40)
        
        for test_name, data in self.coverage_data.items():
            report_lines.append(f"\nTest: {test_name}")
            report_lines.append(f"  Instructions: {data.get('total_instructions', 0)}")
            report_lines.append(f"  Overall Coverage: {data.get('overall_coverage', 0.0):.2f}%")
            
            # Category breakdown
            categories = [cat for cat in data.keys() 
                         if cat not in ['overall_coverage', 'total_instructions']]
            
            for category in sorted(categories):
                coverage = data.get(category, 0.0)
                if isinstance(coverage, (int, float)):
                    status = "✓" if coverage >= 80.0 else "⚠" if coverage >= 50.0 else "✗"
                    report_lines.append(f"    {category:20s}: {coverage:6.2f}% {status}")
        
        # Coverage gaps analysis
        report_lines.append("\nCOVERAGE GAPS ANALYSIS")
        report_lines.append("-" * 40)
        
        all_gaps = {}
        for test_name, data in self.coverage_data.items():
            gaps = self.identify_coverage_gaps(data)
            for category, coverage in gaps:
                if category not in all_gaps:
                    all_gaps[category] = []
                all_gaps[category].append((test_name, coverage))
        
        if all_gaps:
            report_lines.append("Categories with coverage < 80%:")
            for category, test_coverages in all_gaps.items():
                avg_gap_coverage = sum(cov for _, cov in test_coverages) / len(test_coverages)
                report_lines.append(f"  {category:20s}: {avg_gap_coverage:6.2f}% (avg across {len(test_coverages)} tests)")
        else:
            report_lines.append("No significant coverage gaps found!")
            
        # Recommendations
        report_lines.append("\nRECOMMENDATIONS")
        report_lines.append("-" * 40)
        
        if all_gaps:
            report_lines.append("To improve coverage:")
            for category, _ in sorted(all_gaps.items(), key=lambda x: sum(cov for _, cov in x[1])/len(x[1])):
                if 'instruction_type' in category:
                    report_lines.append(f"  • Add more {category.replace('_', ' ')} stimulus")
                elif 'register' in category:
                    report_lines.append(f"  • Improve register allocation diversity")
                elif 'hazard' in category:
                    report_lines.append(f"  • Increase hazard injection scenarios")
                elif 'corner' in category:
                    report_lines.append(f"  • Add more corner case testing")
                else:
                    report_lines.append(f"  • Focus on {category.replace('_', ' ')} scenarios")
        else:
            report_lines.append("Coverage goals met! Consider:")
            report_lines.append("  • Adding more complex scenarios")
            report_lines.append("  • Increasing instruction diversity")
            report_lines.append("  • Testing edge cases more thoroughly")
            
        report_lines.append("")
        report_lines.append("=" * 80)
        
        # Output report
        report_text = "\n".join(report_lines)
        
        if output_file:
            with open(output_file, 'w') as f:
                f.write(report_text)
            print(f"Coverage report written to {output_file}")
        else:
            print(report_text)
            
        return report_text
    
    def plot_coverage_comparison(self, output_file: str = "coverage_comparison.png"):
        """Generate coverage comparison plots"""
        if not self.coverage_data:
            print("No coverage data available for plotting")
            return
            
        try:
            # Prepare data for plotting
            tests = list(self.coverage_data.keys())
            categories = []
            coverage_matrix = []
            
            # Get categories from first test
            if tests:
                first_test_data = self.coverage_data[tests[0]]
                categories = [cat for cat in first_test_data.keys() 
                             if cat not in ['overall_coverage', 'total_instructions']]
                
                # Build coverage matrix
                for category in categories:
                    row = []
                    for test in tests:
                        coverage = self.coverage_data[test].get(category, 0.0)
                        if isinstance(coverage, (int, float)):
                            row.append(coverage)
                        else:
                            row.append(0.0)
                    coverage_matrix.append(row)
            
            # Create plots
            fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))
            
            # Plot 1: Coverage heatmap
            if coverage_matrix:
                im = ax1.imshow(coverage_matrix, cmap='RdYlGn', aspect='auto', vmin=0, vmax=100)
                ax1.set_xticks(range(len(tests)))
                ax1.set_xticklabels(tests, rotation=45, ha='right')
                ax1.set_yticks(range(len(categories)))
                ax1.set_yticklabels([cat.replace('_', ' ').title() for cat in categories])
                ax1.set_title('Coverage Heatmap by Test and Category')
                
                # Add text annotations
                for i in range(len(categories)):
                    for j in range(len(tests)):
                        text = ax1.text(j, i, f'{coverage_matrix[i][j]:.1f}%',
                                       ha="center", va="center", color="black", fontsize=8)
                
                plt.colorbar(im, ax=ax1, label='Coverage %')
            
            # Plot 2: Overall coverage comparison
            overall_coverages = [self.coverage_data[test].get('overall_coverage', 0.0) for test in tests]
            bars = ax2.bar(tests, overall_coverages, color=['green' if cov >= 80 else 'orange' if cov >= 50 else 'red' for cov in overall_coverages])
            ax2.set_ylabel('Overall Coverage %')
            ax2.set_title('Overall Coverage by Test')
            ax2.set_ylim(0, 100)
            
            # Add value labels on bars
            for bar, coverage in zip(bars, overall_coverages):
                height = bar.get_height()
                ax2.text(bar.get_x() + bar.get_width()/2., height + 1,
                        f'{coverage:.1f}%', ha='center', va='bottom')
            
            plt.tight_layout()
            plt.savefig(output_file, dpi=300, bbox_inches='tight')
            print(f"Coverage plots saved to {output_file}")
            
        except ImportError:
            print("Matplotlib not available - skipping plot generation")
        except Exception as e:
            print(f"Error generating plots: {e}")

def main():
    parser = argparse.ArgumentParser(description='Analyze CV32E40P functional coverage')
    parser.add_argument('--log-dir', '-d', default='logs', help='Directory containing log files')
    parser.add_argument('--output', '-o', help='Output report file')
    parser.add_argument('--plot', '-p', help='Output plot file')
    parser.add_argument('--tests', '-t', nargs='+', help='Specific tests to analyze')
    
    args = parser.parse_args()
    
    analyzer = CoverageAnalyzer()
    
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
            analyzer.analyze_test_coverage(test_name, str(log_file))
        else:
            print(f"Warning: Log file for {test_name} not found")
    
    # Generate report
    if analyzer.coverage_data:
        analyzer.generate_coverage_report(args.output)
        
        if args.plot:
            analyzer.plot_coverage_comparison(args.plot)
    else:
        print("No coverage data found to analyze")
        return 1
    
    return 0

if __name__ == '__main__':
    sys.exit(main())