import subprocess
from fastmcp import FastMCP

mcp = FastMCP("termux-remote")

def run_cmd(cmd: str) -> str:
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout if result.stdout else result.stderr

@mcp.tool()
def run_command(cmd: str) -> str:
    """Izvrši bash komandu na Termux okruženju."""
    return run_cmd(cmd)

@mcp.tool()
def device_status() -> str:
    """Vrati status uređaja: disk, memorija, CPU."""
    disk = run_cmd("df -h")
    mem  = run_cmd("free -h 2>/dev/null || cat /proc/meminfo | head -5")
    cpu  = run_cmd("cat /proc/cpuinfo | grep 'model name' | head -2")
    return f"=== Disk ===\n{disk}\n=== Memorija ===\n{mem}\n=== CPU ===\n{cpu}"

if __name__ == "__main__":
    mcp.run(transport="http", host="127.0.0.1", port=8001)
