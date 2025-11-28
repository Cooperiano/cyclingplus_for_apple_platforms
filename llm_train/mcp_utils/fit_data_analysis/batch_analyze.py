#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import argparse
import glob
from typing import List, Dict, Any
import pandas as pd

# Import functions from data_operation module
from data_operation import parse_fit_file, analyze_fit_data, plot_fit_data, generate_ai_summary

def batch_analyze_fit_files(directory: str, output_dir: str, no_plots: bool = False, ai_summary: bool = False) -> pd.DataFrame:
    """
    Batch analyze all FIT files in a directory.
    Returns a summary DataFrame with analysis results for all files.
    """
    # Find all .fit files in the directory
    fit_files = glob.glob(os.path.join(directory, '*.fit'))
    
    if not fit_files:
        print(f"No FIT files found in {directory}")
        return pd.DataFrame()
    
    print(f"Found {len(fit_files)} FIT files to analyze")
    
    # Initialize summary data
    summary_data = []
    
    for fit_file in fit_files:
        filename = os.path.basename(fit_file)
        print(f"\nAnalyzing: {filename}")
        
        try:
            # Parse FIT file
            df = parse_fit_file(fit_file)
            print(f"  Data shape: {df.shape}")
            
            # Analyze data
            analysis = analyze_fit_data(df)
            
            # Add filename to analysis
            analysis['filename'] = filename
            analysis['file_path'] = fit_file
            
            # Print key stats
            print(f"  Duration: {analysis.get('duration_minutes', 'N/A'):.1f} min")
            print(f"  Distance: {analysis.get('total_distance_km', 'N/A'):.2f} km")
            print(f"  Avg HR: {analysis.get('avg_heart_rate', 'N/A'):.0f} bpm")
            print(f"  Avg Speed: {analysis.get('avg_speed_kmh', 'N/A'):.1f} km/h")
            
            # Generate plots
            if not no_plots:
                plot_path = plot_fit_data(df, output_dir, os.path.splitext(filename)[0])
                analysis['plot_path'] = plot_path
                print(f"  Plot saved: {plot_path}")
            
            # Generate AI summary
            if ai_summary:
                summary = generate_ai_summary(analysis, filename)
                summary_path = os.path.join(output_dir, f'{os.path.splitext(filename)[0]}_summary.txt')
                with open(summary_path, 'w', encoding='utf-8') as f:
                    f.write(summary)
                analysis['summary_path'] = summary_path
                print(f"  Summary saved: {summary_path}")
            
            # Save raw data
            csv_path = os.path.join(output_dir, f'{os.path.splitext(filename)[0]}_data.csv')
            df.to_csv(csv_path)
            analysis['csv_path'] = csv_path
            
            summary_data.append(analysis)
            
        except Exception as e:
            print(f"  Error analyzing {filename}: {e}")
            # Add error entry
            summary_data.append({
                'filename': filename,
                'file_path': fit_file,
                'error': str(e)
            })
    
    # Create summary DataFrame
    summary_df = pd.DataFrame(summary_data)
    
    # Save overall summary
    summary_csv_path = os.path.join(output_dir, 'batch_summary.csv')
    summary_df.to_csv(summary_csv_path, index=False)
    print(f"\nBatch summary saved to: {summary_csv_path}")
    
    return summary_df

def main():
    parser = argparse.ArgumentParser(description='Batch analyze FIT files in a directory')
    parser.add_argument('directory', help='Directory containing FIT files')
    parser.add_argument('--output-dir', default='batch_analysis_output', help='Output directory for results')
    parser.add_argument('--no-plots', action='store_true', help='Skip generating plots')
    parser.add_argument('--ai-summary', action='store_true', help='Generate AI-powered summaries')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.directory):
        print(f"Error: Directory '{args.directory}' not found.")
        sys.exit(1)
    
    try:
        # Create output directory
        os.makedirs(args.output_dir, exist_ok=True)
        
        # Run batch analysis
        summary_df = batch_analyze_fit_files(args.directory, args.output_dir, args.no_plots, args.ai_summary)
        
        if not summary_df.empty:
            print(f"\nSuccessfully analyzed {len(summary_df)} FIT files")
            print("\nSummary statistics:")
            
            # Calculate overall statistics
            if 'total_distance_km' in summary_df.columns:
                total_distance = summary_df['total_distance_km'].sum()
                print(f"  Total distance: {total_distance:.2f} km")
            
            if 'duration_minutes' in summary_df.columns:
                total_duration = summary_df['duration_minutes'].sum()
                print(f"  Total duration: {total_duration:.1f} minutes")
            
            if 'avg_heart_rate' in summary_df.columns:
                avg_hr = summary_df['avg_heart_rate'].mean()
                print(f"  Average heart rate: {avg_hr:.1f} bpm")
        
    except Exception as e:
        print(f"Error in batch analysis: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
