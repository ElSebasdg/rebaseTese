#!/usr/bin/env python3

import subprocess
import os
import sys

def print_help():
    help_text = """
Usage: ./sl_build_OAI.py [--telnet] [--c] [--help]

Options:
  --telnet   Build with telnet support (optional)
  --c        Clean build (runs ./build_oai -c)
  --help     Show this help message and exit
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

def build_oai(enable_telnet=False):
    build_script = find_build_script()

    if not build_script:
        print("Error: 'build_oai' not found in expected paths.")
        sys.exit(1)

    cmd = ["sudo", build_script, "--ninja", "--nrUE", "-C"]

    if enable_telnet:
        cmd += ["--build-lib", "telnetsrv"]

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

    if len(args) > 1:
        print("Error: Only one optional argument '--telnet', '--c', or '--help' is allowed.\n")
        print_help()
        sys.exit(1)

    if len(args) == 1:
        if args[0] == "--help":
            print_help()
            sys.exit(0)
        elif args[0] == "--telnet":
            build_oai(enable_telnet=True)
        elif args[0] == "--c":
            clean_build()
        else:
            print(f"Error: Unknown argument '{args[0]}'.\n")
            print_help()
            sys.exit(1)
    else:
        # no arguments
        build_oai(enable_telnet=False)

if __name__ == "__main__":
    main()
