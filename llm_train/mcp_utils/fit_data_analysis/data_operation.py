#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import argparse
from typing import List, Dict, Any, Optional
import pandas as pd
import matplotlib.pyplot as plt
from fitparse import FitFile
import numpy as np

def parse_fit_file(file_path: str) -> pd.DataFrame:
    """
    Parse a FIT file and return a DataFrame with activity data.
    """
    fitfile = FitFile(file_path)
    
    # Extract records
    records = []
    for record in fitfile.get_messages('record'):
        record_data = {}
        for data in record:
            record_data[data.name] = data.value
        records.append(record_data)
    
    if not records:
        raise ValueError("No record data found in FIT file")
    
    df = pd.DataFrame(records)
    
    # Convert timestamps if present
    if 'timestamp' in df.columns:
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        df.set_index('timestamp', inplace=True)
    
    return df

def analyze_fit_data(df: pd.DataFrame) -> Dict[str, Any]:
    """
    Perform basic analysis on FIT data.
    """
    analysis = {}
    
    # Basic stats
    if 'heart_rate' in df.columns:
        analysis['avg_heart_rate'] = df['heart_rate'].mean()
        analysis['max_heart_rate'] = df['heart_rate'].max()
        analysis['min_heart_rate'] = df['heart_rate'].min()
    
    if 'speed' in df.columns:
        # Speed is usually in m/s, convert to km/h
        df['speed_kmh'] = df['speed'] * 3.6
        analysis['avg_speed_kmh'] = df['speed_kmh'].mean()
        analysis['max_speed_kmh'] = df['speed_kmh'].max()
    
    if 'distance' in df.columns:
        analysis['total_distance_m'] = df['distance'].max() if df['distance'].notna().any() else 0
        analysis['total_distance_km'] = analysis['total_distance_m'] / 1000
    
    if 'power' in df.columns:
        analysis['avg_power'] = df['power'].mean()
        analysis['max_power'] = df['power'].max()
    
    if 'cadence' in df.columns:
        analysis['avg_cadence'] = df['cadence'].mean()
    
    # Duration
    if isinstance(df.index, pd.DatetimeIndex):
        analysis['duration_seconds'] = (df.index[-1] - df.index[0]).total_seconds()
        analysis['duration_minutes'] = analysis['duration_seconds'] / 60
    
    return analysis

def plot_fit_data(df: pd.DataFrame, output_dir: str, filename: str):
    """
    Generate plots for FIT data.
    """
    os.makedirs(output_dir, exist_ok=True)
    
    fig, axes = plt.subplots(2, 2, figsize=(12, 8))
    fig.suptitle(f'FIT Data Analysis: {filename}')
    
    # Heart Rate
    if 'heart_rate' in df.columns:
        df['heart_rate'].plot(ax=axes[0,0], title='Heart Rate (bpm)', color='red')
    
    # Speed
    if 'speed_kmh' in df.columns:
        df['speed_kmh'].plot(ax=axes[0,1], title='Speed (km/h)', color='blue')
    
    # Power
    if 'power' in df.columns:
        df['power'].plot(ax=axes[1,0], title='Power (W)', color='green')
    
    # Distance
    if 'distance' in df.columns:
        df['distance'].plot(ax=axes[1,1], title='Distance (m)', color='orange')
    
    plt.tight_layout()
    plot_path = os.path.join(output_dir, f'{filename}_analysis.png')
    plt.savefig(plot_path)
    plt.close()
    return plot_path

def generate_ai_summary(analysis: Dict[str, Any], filename: str) -> str:
    """
    Generate an AI-powered summary of the analysis.
    Note: This is a placeholder. In a real implementation, you'd integrate with an AI API.
    """
    summary = f"""
FIT File Analysis Summary for {filename}
========================================

Activity Statistics:
- Duration: {analysis.get('duration_minutes', 'N/A'):.1f} minutes
- Total Distance: {analysis.get('total_distance_km', 'N/A'):.2f} km
- Average Heart Rate: {analysis.get('avg_heart_rate', 'N/A'):.0f} bpm
- Max Heart Rate: {analysis.get('max_heart_rate', 'N/A'):.0f} bpm
- Average Speed: {analysis.get('avg_speed_kmh', 'N/A'):.1f} km/h
- Max Speed: {analysis.get('max_speed_kmh', 'N/A'):.1f} km/h
- Average Power: {analysis.get('avg_power', 'N/A'):.0f} W
- Max Power: {analysis.get('max_power', 'N/A'):.0f} W
- Average Cadence: {analysis.get('avg_cadence', 'N/A'):.0f} rpm

This appears to be a {'cycling' if analysis.get('avg_cadence') else 'running/cardio'} activity.
The heart rate suggests {'high intensity' if analysis.get('avg_heart_rate', 0) > 150 else 'moderate intensity'} effort.
"""
    return summary

def main():
    parser = argparse.ArgumentParser(description='Analyze FIT files from fitness activities')
    parser.add_argument('fit_file', help='Path to the FIT file')
    parser.add_argument('--output-dir', default='analysis_output', help='Output directory for plots and reports')
    parser.add_argument('--no-plots', action='store_true', help='Skip generating plots')
    parser.add_argument('--ai-summary', action='store_true', help='Generate AI-powered summary')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.fit_file):
        print(f"Error: FIT file '{args.fit_file}' not found.")
        sys.exit(1)
    
    try:
        # Parse FIT file
        print(f"Parsing FIT file: {args.fit_file}")
        df = parse_fit_file(args.fit_file)
        print(f"Data shape: {df.shape}")
        print(f"Columns: {list(df.columns)}")
        
        # Analyze data
        analysis = analyze_fit_data(df)
        print("\nAnalysis Results:")
        for key, value in analysis.items():
            print(f"  {key}: {value}")
        
        # Generate plots
        if not args.no_plots:
            plot_path = plot_fit_data(df, args.output_dir, os.path.splitext(os.path.basename(args.fit_file))[0])
            print(f"\nPlot saved to: {plot_path}")
        
        # Generate AI summary
        if args.ai_summary:
            summary = generate_ai_summary(analysis, os.path.basename(args.fit_file))
            summary_path = os.path.join(args.output_dir, 'ai_summary.txt')
            with open(summary_path, 'w') as f:
                f.write(summary)
            print(f"\nAI Summary saved to: {summary_path}")
            print("\n" + summary)
        
        # Save raw data
        csv_path = os.path.join(args.output_dir, os.path.splitext(os.path.basename(args.fit_file))[0] + '_data.csv')
        df.to_csv(csv_path)
        print(f"Raw data saved to: {csv_path}")
        
    except Exception as e:
        print(f"Error analyzing FIT file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
