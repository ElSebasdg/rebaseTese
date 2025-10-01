#!/usr/bin/env python3

import subprocess
import os
import sys

def print_help():
    help_text = """
Usage: ./sl_build_OAI.py [OPTIONS]

Options:
  --telnet   Build with telnet support (adds: --build-lib telnetsrv)
  --usrp     Build with USRP hardware support (adds: -w USRP)
  --c        Clean build (runs ./build_oai -c)
  --help     Show this help message and exit

Examples:
  ./sl_build_OAI.py               # Default build
  ./sl_build_OAI.py --telnet      # Build with telnet
  ./sl_build_OAI.py --usrp        # Build for USRP
  ./sl_build_OAI.py --c           # Clean build
  ./sl_build_OAI.py --telnet --usrp  # Build with telnet and USRP
"""
    print(help_text)

def find_build_script():
    paths = [
        os.path.join(os.getcwd(), "build_oai"),
        "/SebasTeseWork/openairinterface5g-sl-release-1.0/cmake_targets/build_oai"
    ]
    for path in paths:
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path
    return None

def build_oai(enable_telnet=False, enable_usrp=False):
    build_script = find_build_script()

    if not build_script:
        print("Error: 'build_oai' not found in expected paths.")
        sys.exit(1)

    cmd = ["sudo", build_script, "--ninja", "--nrUE", "-C"]

    if enable_telnet:
        cmd += ["--build-lib", "telnetsrv"]

    if enable_usrp:
        cmd += ["-w", "USRP"]

    print("Running command:", " ".join(cmd))
    subprocess.run(cmd, check=True)

def clean_build():
    build_script = find_build_script()

    if not build_script:
        print("Error: 'build_oai' not found in expected paths.")
        sys.exit(1)

    cmd = ["sudo", build_script, "-c"]

    print("Running command:", " ".join(cmd))
    subprocess.run(cmd, check=True)

def main():
    args = sys.argv[1:]

    if "--help" in args:
        print_help()
        sys.exit(0)

    clean = "--c" in args
    enable_telnet = "--telnet" in args
    enable_usrp = "--usrp" in args

    unknown_args = [arg for arg in args if arg not in ("--help", "--telnet", "--usrp", "--c")]
    if unknown_args:
        print(f"Error: Unknown argument(s): {' '.join(unknown_args)}\n")
        print_help()
        sys.exit(1)

    if clean:
        clean_build()
    else:
        build_oai(enable_telnet=enable_telnet, enable_usrp=enable_usrp)

if __name__ == "__main__":
    main()
