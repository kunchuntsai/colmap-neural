#!/bin/bash
# scripts/benchmark.py

import os
import sys
import argparse
import time
import csv
from pathlib import Path
import subprocess
import json

def main():
    parser = argparse.ArgumentParser(description='Benchmark COLMAP Neural Enhancement')
    parser.add_argument('--dataset', required=True, help='Path to benchmark dataset')
    parser.add_argument('--output', required=True, help='Path to output directory')
    parser.add_argument('--feature-extractors', nargs='+', default=['superpoint', 'netvlad', 'sift'], 
                        help='Feature extractors to benchmark')
    parser.add_argument('--matchers', nargs='+', default=['superglue', 'nearest_neighbor'], 
                        help='Feature matchers to benchmark')
    parser.add_argument('--mvs', nargs='+', default=['mvsnet', 'patch_match'], 
                        help='MVS methods to benchmark')
    parser.add_argument('--cpu-only', action='store_true', help='Use CPU only')
    args = parser.parse_args()
    
    # Get the project root directory
    script_dir = Path(__file__).parent.absolute()
    project_root = script_dir.parent
    build_dir = project_root / "build"
    app_path = build_dir / "colmap-neural-app" / "colmap-neural"
    
    # Create output directory
    output_dir = Path(args.output)
    output_dir.mkdir(exist_ok=True, parents=True)
    
    # Create results CSV file
    results_file = output_dir / "benchmark_results.csv"
    with open(results_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow([
            'Feature Extractor', 'Matcher', 'MVS', 'GPU/CPU',
            'Feature Extraction Time (s)', 'Matching Time (s)', 'MVS Time (s)', 
            'Total Time (s)', 'Memory Usage (MB)', 'Reconstruction Quality'
        ])
    
    # Run benchmarks for all combinations
    for extractor in args.feature_extractors:
        for matcher in args.matchers:
            for mvs_method in args.mvs:
                # Skip incompatible combinations
                if extractor == 'sift' and matcher == 'superglue':
                    print(f"Skipping incompatible combination: {extractor} + {matcher}")
                    continue
                
                # Create benchmark workspace
                workspace = output_dir / f"{extractor}_{matcher}_{mvs_method}"
                workspace.mkdir(exist_ok=True)
                
                # Configure command
                cmd = [
                    str(app_path),
                    f"--workspace={workspace}",
                    f"--images={args.dataset}",
                    f"--feature-extractor={extractor}",
                    f"--matcher={matcher}",
                    f"--mvs={mvs_method}",
                    "--benchmark=true",
                    f"--benchmark_dataset={args.dataset}"
                ]
                
                if args.cpu_only:
                    cmd.append("--cpu")
                
                # Run benchmark
                print(f"Running benchmark: {extractor} + {matcher} + {mvs_method}")
                try:
                    start_time = time.time()
                    process = subprocess.run(cmd, capture_output=True, text=True, check=True)
                    end_time = time.time()
                    
                    # Parse benchmark results from output
                    benchmark_file = workspace / "benchmark_results.json"
                    if benchmark_file.exists():
                        with open(benchmark_file, 'r') as f:
                            results = json.load(f)
                            
                        # Add to CSV
                        with open(results_file, 'a', newline='') as csvfile:
                            writer = csv.writer(csvfile)
                            writer.writerow([
                                extractor, matcher, mvs_method, 
                                "CPU" if args.cpu_only else "GPU",
                                results.get("feature_extraction_time", 0),
                                results.get("matching_time", 0),
                                results.get("mvs_time", 0),
                                results.get("total_time", 0),
                                results.get("memory_usage", 0),
                                results.get("reconstruction_quality", 0)
                            ])
                    else:
                        print(f"  ⚠️ No benchmark results file found at {benchmark_file}")
                        
                except subprocess.CalledProcessError as e:
                    print(f"  ❌ Benchmark failed: {e}")
                    print(f"  Error output: {e.stderr}")
    
    print(f"✅ Benchmarks completed. Results saved to {results_file}")

if __name__ == "__main__":
    main()