#!/bin/sh
set -eu

# ANSI color codes for presentation terminal display
CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"
BOLD="\033[1m"
RESET="\033[0m"

print_stage() {
    stage_id="$1"
    stage_title="$2"
    color="$3"
    printf "\n%b======================================================================%b\n" "$CYAN" "$RESET"
    printf "%b[%s]%b %b%s%b\n" "$color" "$stage_id" "$RESET" "$BOLD" "$stage_title" "$RESET"
    printf "%b======================================================================%b\n\n" "$CYAN" "$RESET"
}

MOCK_MODE=false
SUSPECT_VIDEO=""
REF_VIDEO=""
THRESHOLD=""

# Parse arguments
if [ "${1:-}" = "--mock" ] || [ "${2:-}" = "--mock" ]; then
    MOCK_MODE=true
    if [ "${2:-}" != "--mock" ] && [ -n "${2:-}" ]; then
        THRESHOLD="$2"
    fi
elif [ $# -ge 2 ]; then
    SUSPECT_VIDEO="$1"
    REF_VIDEO="$2"
    THRESHOLD="${3:-}"
elif [ $# -eq 0 ]; then
    if [ -f "data/suspect.mp4" ] && [ -f "data/reference.mp4" ]; then
        SUSPECT_VIDEO="data/suspect.mp4"
        REF_VIDEO="data/reference.mp4"
    else
        printf "Notice: No video arguments provided and default files (data/suspect.mp4, data/reference.mp4) not found.\n"
        printf "Run with %b--mock%b to demonstrate with synthetic 60-frame sinusoidal signals:\n" "$YELLOW" "$RESET"
        printf "  %s --mock\n" "$0"
        printf "Or provide video paths:\n"
        printf "  %s <suspect_video> <reference_video> [threshold]\n" "$0"
        exit 1
    fi
else
    printf "Usage: %s [<suspect_video> <reference_video> [threshold] | --mock [threshold]]\n" "$0" >&2
    exit 1
fi

mkdir -p data output bin

# -----------------------------------------------------------------------------
# STAGE 1: Chain-of-Custody Ingestion & Hashing
# -----------------------------------------------------------------------------
print_stage "STAGE 1" "Forensic Evidence Intake & Chain-of-Custody Hashing" "$GREEN"

if [ "$MOCK_MODE" = true ]; then
    SUSPECT_VIDEO="data/suspect_mock.mp4"
    REF_VIDEO="data/reference_mock.mp4"
    if [ ! -f "$SUSPECT_VIDEO" ]; then
        printf "MOCK_GAIT_EVIDENCE_STREAM_SUSPECT_%s\n" "$(date -u +%s)" > "$SUSPECT_VIDEO"
    fi
    if [ ! -f "$REF_VIDEO" ]; then
        printf "MOCK_GAIT_EVIDENCE_STREAM_REFERENCE_%s\n" "$(date -u +%s)" > "$REF_VIDEO"
    fi
    printf "[INFO] Running in mock demo mode using synthetic evidence files.\n\n"
fi

printf "%s\n" "--> Ingesting suspect evidence: $SUSPECT_VIDEO"
./src/ingest.sh "$SUSPECT_VIDEO"

printf "\n%s\n" "--> Ingesting reference evidence: $REF_VIDEO"
./src/ingest.sh "$REF_VIDEO"

# -----------------------------------------------------------------------------
# STAGE 2: Kinematic Feature Extraction & Signal Processing
# -----------------------------------------------------------------------------
print_stage "STAGE 2" "Biometric Kinematics Extraction & Signal Processing" "$YELLOW"

SUSPECT_CSV="output/suspect_angles.csv"
REF_CSV="output/reference_angles.csv"

if [ "$MOCK_MODE" = true ]; then
    printf "[INFO] Generating 60-frame sinusoidal knee angle signals with phase/amplitude shift...\n"
    python3 -c "
import math
import os

os.makedirs('output', exist_ok=True)
n = 60

# Suspect: 60-frame gait cycle oscillation (130-180 degrees)
suspect = [155.0 + 25.0 * math.cos(2 * math.pi * i / 30.0) for i in range(n)]

# Reference: slight phase shift (+0.15 rad) and minor amplitude variation
reference = [153.0 + 24.0 * math.cos(2 * math.pi * i / 30.0 + 0.15) for i in range(n)]

with open('$SUSPECT_CSV', 'w') as f:
    for a in suspect:
        f.write(f'{a:.3f}\n')

with open('$REF_CSV', 'w') as f:
    for a in reference:
        f.write(f'{a:.3f}\n')

# Optional plot generation if matplotlib is installed
try:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.figure(figsize=(10, 5))
    plt.plot(range(n), suspect, label='Suspect Left Knee', color='blue', linewidth=1.5)
    plt.plot(range(n), reference, label='Reference Left Knee', color='orange', linewidth=1.5, linestyle='--')
    plt.title('Gait Kinematics - Left Knee Flexion Wave (Mock Demo)')
    plt.xlabel('Frame')
    plt.ylabel('Knee Angle (degrees)')
    plt.legend()
    plt.grid(True, linestyle='--', alpha=0.6)
    plt.tight_layout()
    plt.savefig('output/gait_kinematics_wave.png', dpi=150)
    plt.close()
    print('--> Saved kinematics wave plot to: output/gait_kinematics_wave.png')
except Exception:
    pass

print('--> Generated 60 frames -> $SUSPECT_CSV')
print('--> Generated 60 frames -> $REF_CSV')
"
else
    printf "%s\n" "--> Extracting kinematics from suspect video: $SUSPECT_VIDEO"
    python3 src/extract_gait.py "$SUSPECT_VIDEO" "$SUSPECT_CSV"

    printf "\n%s\n" "--> Extracting kinematics from reference video: $REF_VIDEO"
    python3 src/extract_gait.py "$REF_VIDEO" "$REF_CSV"
fi

# -----------------------------------------------------------------------------
# STAGE 3: Dynamic Time Warping (DTW) Forensic Verification
# -----------------------------------------------------------------------------
print_stage "STAGE 3" "Dynamic Time Warping (DTW) Forensic Verification" "$MAGENTA"

printf "%s\n" "--> Compiling GaitVerifier.java bytecode into bin/..."
javac -d bin src/GaitVerifier.java

printf "%s\n\n" "--> Executing DTW verification on extracted kinematic arrays..."
if [ -n "$THRESHOLD" ]; then
    java -cp bin GaitVerifier "$SUSPECT_CSV" "$REF_CSV" "$THRESHOLD"
else
    java -cp bin GaitVerifier "$SUSPECT_CSV" "$REF_CSV"
fi
