#!/usr/bin/env python3
import math
import os
import sys

import cv2
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import mediapipe as mp


def calculate_angle(hip, knee, ankle):
    """Calculate the interior angle at the knee joint in degrees clamped to [0, 180]."""
    hx, hy = (hip.x, hip.y) if hasattr(hip, "x") else (hip[0], hip[1])
    kx, ky = (knee.x, knee.y) if hasattr(knee, "x") else (knee[0], knee[1])
    ax, ay = (ankle.x, ankle.y) if hasattr(ankle, "x") else (ankle[0], ankle[1])

    radians = math.atan2(ay - ky, ax - kx) - math.atan2(hy - ky, hx - kx)
    angle = abs(math.degrees(radians))
    if angle > 180.0:
        angle = 360.0 - angle
    return max(0.0, min(180.0, angle))


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <input_video_path> <output_csv_path>", file=sys.stderr)
        sys.exit(1)

    input_video = sys.argv[1]
    output_csv = sys.argv[2]

    if not os.path.isfile(input_video):
        print(f"Error: Input video '{input_video}' not found.", file=sys.stderr)
        sys.exit(1)

    cap = cv2.VideoCapture(input_video)
    if not cap.isOpened():
        print(f"Error: Unable to open video '{input_video}'.", file=sys.stderr)
        sys.exit(1)

    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose(
        static_image_mode=False,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    )

    left_angles = []
    right_angles = []
    prev_left_angle = 180.0
    prev_right_angle = 180.0

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(rgb_frame)

        left_angle = prev_left_angle
        right_angle = prev_right_angle

        if results.pose_landmarks and results.pose_landmarks.landmark:
            lms = results.pose_landmarks.landmark

            # Left side: Hip (23), Knee (25), Ankle (27)
            if len(lms) > 27 and lms[23] is not None and lms[25] is not None and lms[27] is not None:
                left_angle = calculate_angle(lms[23], lms[25], lms[27])
                prev_left_angle = left_angle

            # Right side: Hip (24), Knee (26), Ankle (28)
            if len(lms) > 28 and lms[24] is not None and lms[26] is not None and lms[28] is not None:
                right_angle = calculate_angle(lms[24], lms[26], lms[28])
                prev_right_angle = right_angle

        left_angles.append(left_angle)
        right_angles.append(right_angle)

    cap.release()
    pose.close()

    # Save left knee angles to CSV (one float per row, 3 decimal places)
    csv_dir = os.path.dirname(os.path.abspath(output_csv))
    if csv_dir:
        os.makedirs(csv_dir, exist_ok=True)

    with open(output_csv, "w", newline="") as f:
        for angle in left_angles:
            f.write(f"{angle:.3f}\n")

    # Generate 2D line plot showing Left vs. Right knee flexion across frames
    os.makedirs("output", exist_ok=True)
    plot_output_path = "output/gait_kinematics_wave.png"

    plt.figure(figsize=(10, 5))
    frames = range(len(left_angles))
    plt.plot(frames, left_angles, label="Left Knee", color="blue", linewidth=1.5)
    plt.plot(frames, right_angles, label="Right Knee", color="red", linewidth=1.5)
    plt.title("Gait Kinematics - Knee Flexion Wave")
    plt.xlabel("Frame")
    plt.ylabel("Knee Angle (degrees)")
    plt.legend()
    plt.grid(True, linestyle="--", alpha=0.6)
    plt.tight_layout()
    plt.savefig(plot_output_path, dpi=150)
    plt.close()

    print(f"Extracted {len(left_angles)} frames.")
    print(f"Saved left knee angles to: {output_csv}")
    print(f"Saved kinematics plot to: {plot_output_path}")


if __name__ == "__main__":
    main()
