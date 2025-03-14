#!/usr/bin/env python3
"""
Download script for pre-trained neural network models used in COLMAP Neural.
"""

import os
import sys
import argparse
import urllib.request
import hashlib
import zipfile
import tarfile
import shutil
from pathlib import Path
from tqdm import tqdm

# Model information: url, filename, md5sum, extract_dir
MODELS = {
    "superpoint": {
        "url": "https://github.com/magicleap/SuperPointPretrainedNetwork/raw/master/superpoint_v1.pth",
        "filename": "superpoint_v1.pth",
        "md5sum": "f5b1b1994f1135c5690392a2a1a0db8c",
        "extract_dir": None  # No extraction needed for .pth files
    },
    "superglue": {
        "url": "https://github.com/magicleap/SuperGluePretrainedNetwork/raw/master/models/weights/superglue_outdoor.pth",
        "filename": "superglue_outdoor.pth",
        "md5sum": "9cf3f63d3e273755a82d9f881a80c5ee",
        "extract_dir": None  # No extraction needed for .pth files
    },
    "netvlad": {
        "url": "https://github.com/QVPR/Patch-NetVLAD/releases/download/v1.0/patchnetvlad-model.zip",
        "filename": "patchnetvlad-model.zip",
        "md5sum": "e4e9b9a6c2a764744a72f71f9b62a988",
        "extract_dir": "netvlad"  # Extract to this subdirectory
    },
    "mvsnet": {
        "url": "https://github.com/YoYo000/MVSNet/raw/master/model/model_mvs.ckpt",
        "filename": "model_mvs.ckpt",
        "md5sum": "a1195c7e5feffcfa0ecb1ae2f250e384",
        "extract_dir": None  # No extraction needed for .ckpt files
    }
}

class DownloadProgressBar(tqdm):
    def update_to(self, b=1, bsize=1, tsize=None):
        if tsize is not None:
            self.total = tsize
        self.update(b * bsize - self.n)

def calculate_md5(filename):
    """Calculate MD5 hash of file."""
    hash_md5 = hashlib.md5()
    with open(filename, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def download_file(url, output_path):
    """Download file with progress bar."""
    with DownloadProgressBar(unit='B', unit_scale=True, miniters=1, desc=url.split('/')[-1]) as t:
        urllib.request.urlretrieve(url, output_path, reporthook=t.update_to)

def extract_archive(filename, extract_dir):
    """Extract zip or tar.gz archive."""
    if filename.endswith('.zip'):
        with zipfile.ZipFile(filename, 'r') as zip_ref:
            zip_ref.extractall(extract_dir)
    elif filename.endswith('.tar.gz') or filename.endswith('.tgz'):
        with tarfile.open(filename, 'r:gz') as tar_ref:
            tar_ref.extractall(extract_dir)
    else:
        print(f"Unsupported archive format: {filename}")
        return False
    return True

def main():
    # Parse arguments
    parser = argparse.ArgumentParser(description="Download pre-trained neural network models for COLMAP Neural")
    parser.add_argument("--models_dir", type=str, default="models", help="Directory to store downloaded models")
    parser.add_argument("--force", action="store_true", help="Force download even if files exist")
    parser.add_argument("--skip_verification", action="store_true", help="Skip MD5 verification")
    parser.add_argument("--specific_models", nargs='+', choices=MODELS.keys(), help="Download only specific models")
    args = parser.parse_args()

    # Create models directory if it doesn't exist
    models_dir = Path(args.models_dir)
    models_dir.mkdir(parents=True, exist_ok=True)

    # Determine which models to download
    models_to_download = args.specific_models if args.specific_models else MODELS.keys()

    # Download and verify each model
    for model_name in models_to_download:
        model = MODELS[model_name]
        
        # Create subdirectory if needed
        model_dir = models_dir / model_name
        model_dir.mkdir(exist_ok=True)
        
        output_path = model_dir / model["filename"]
        
        # Check if file already exists and is valid
        if output_path.exists() and not args.force:
            if args.skip_verification:
                print(f"File {output_path} already exists, skipping download.")
                continue
            
            # Verify MD5
            print(f"Verifying {output_path}...")
            if calculate_md5(output_path) == model["md5sum"]:
                print(f"File {output_path} is valid, skipping download.")
                
                # Extract if needed and not already extracted
                if model["extract_dir"] and not (model_dir / model["extract_dir"]).exists():
                    print(f"Extracting {output_path}...")
                    extract_dir = model_dir / model["extract_dir"]
                    extract_dir.mkdir(exist_ok=True)
                    extract_archive(output_path, extract_dir)
                continue
            else:
                print(f"File {output_path} is invalid, re-downloading.")
        
        # Download file
        print(f"Downloading {model['url']} to {output_path}...")
        try:
            download_file(model["url"], output_path)
        except Exception as e:
            print(f"Error downloading {model['url']}: {e}")
            continue
        
        # Verify download
        if not args.skip_verification:
            print(f"Verifying {output_path}...")
            calculated_md5 = calculate_md5(output_path)
            if calculated_md5 != model["md5sum"]:
                print(f"WARNING: MD5 verification failed for {output_path}.")
                print(f"Expected: {model['md5sum']}")
                print(f"Got:      {calculated_md5}")
                continue
        
        # Extract if needed
        if model["extract_dir"]:
            print(f"Extracting {output_path}...")
            extract_dir = model_dir / model["extract_dir"]
            extract_dir.mkdir(exist_ok=True)
            if not extract_archive(output_path, extract_dir):
                print(f"Failed to extract {output_path}")
                continue
    
    print("Download complete!")
    print(f"Models are available in {models_dir.absolute()}")

if __name__ == "__main__":
    main()