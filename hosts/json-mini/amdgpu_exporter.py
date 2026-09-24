#!/usr/bin/env python3
"""Minimal AMD GPU Prometheus exporter."""
import glob
import http.server
import os

PORT = int(os.environ.get("PORT", "9101"))
# Prefix for /sys when running in a container with the host root mounted.
HOST_ROOT = os.environ.get("HOST_ROOT", "")

def find_gpu_path():
    """Auto-detect AMD GPU device path."""
    for card in sorted(glob.glob(f"{HOST_ROOT}/sys/class/drm/card*/device/gpu_busy_percent")):
        return os.path.dirname(card)
    return None

def find_hwmon(gpu_path):
    """Find the hwmon directory under the GPU device."""
    hwmons = glob.glob(f"{gpu_path}/hwmon/hwmon*")
    return hwmons[0] if hwmons else None

def read_file(path):
    try:
        with open(path) as f:
            return f.read().strip()
    except (FileNotFoundError, PermissionError):
        return None

class MetricsHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        lines = []
        gpu_path = find_gpu_path()
        if gpu_path is None:
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"# No AMD GPU found\n")
            return

        hwmon = find_hwmon(gpu_path)

        val = read_file(f"{gpu_path}/gpu_busy_percent")
        if val is not None:
            lines.append("# HELP amdgpu_busy_percent GPU utilization percentage")
            lines.append("# TYPE amdgpu_busy_percent gauge")
            lines.append(f"amdgpu_busy_percent {val}")

        val = read_file(f"{gpu_path}/mem_info_vram_used")
        if val is not None:
            lines.append("# HELP amdgpu_vram_used_bytes VRAM used in bytes")
            lines.append("# TYPE amdgpu_vram_used_bytes gauge")
            lines.append(f"amdgpu_vram_used_bytes {val}")

        val = read_file(f"{gpu_path}/mem_info_vram_total")
        if val is not None:
            lines.append("# HELP amdgpu_vram_total_bytes VRAM total in bytes")
            lines.append("# TYPE amdgpu_vram_total_bytes gauge")
            lines.append(f"amdgpu_vram_total_bytes {val}")

        if hwmon:
            val = read_file(f"{hwmon}/power1_average")
            if val is not None:
                watts = int(val) / 1_000_000
                lines.append("# HELP amdgpu_power_watts GPU power draw in watts")
                lines.append("# TYPE amdgpu_power_watts gauge")
                lines.append(f"amdgpu_power_watts {watts:.3f}")

            val = read_file(f"{hwmon}/freq1_input")
            if val is not None:
                mhz = int(val) / 1_000_000
                lines.append("# HELP amdgpu_clock_mhz GPU clock speed in MHz")
                lines.append("# TYPE amdgpu_clock_mhz gauge")
                lines.append(f"amdgpu_clock_mhz {mhz:.0f}")

        body = "\n".join(lines) + "\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(body.encode())

    def log_message(self, format, *args):
        pass  # suppress logs

if __name__ == "__main__":
    server = http.server.HTTPServer(("", PORT), MetricsHandler)
    gpu = find_gpu_path()
    print(f"AMD GPU exporter listening on :{PORT}, GPU: {gpu}")
    server.serve_forever()
