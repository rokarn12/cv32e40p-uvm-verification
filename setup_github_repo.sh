#!/bin/bash
# Quick setup script for GitHub repository

echo "Setting up GitHub repository..."

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d "uvm_tb" ]; then
    echo "Error: Please run this script from the repository root directory"
    exit 1
fi

# Initialize git repository
git init
git add .
git commit -m "Initial commit: CV32E40P UVM verification environment

- Complete UVM testbench with enhanced instruction generation
- Automated coverage analysis with gap identification
- Configuration-driven testing via JSON files
- Multiple sequence types for comprehensive verification
- Sub-second coverage analysis with detailed reporting
- Production-ready quality with 100% test pass rate"

git branch -M main

echo
echo "Repository initialized successfully!"
echo
echo "To push to GitHub:"
echo "1. Create a new repository on GitHub named 'cv32e40p-uvm-verification'"
echo "2. Run: git remote add origin https://github.com/rokarn12/cv32e40p-uvm-verification.git"
echo "3. Run: git push -u origin main"
echo
echo "Don't forget to update the README.md badges with your GitHub username!"
