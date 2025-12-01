import os
import time

# Reads the GREETING variable injected from Kubernetes YAML
GREETING_MESSAGE = os.environ.get("GREETING", "Agent is running...")
REPLICA_ID = os.environ.get("HOSTNAME", "UNKNOWN_AGENT")

def run_agent():
    """Simulates the agent's main loop."""
    print(f"--- Starting Agent: {REPLICA_ID} ---")

    while True:
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
        print(f"[{timestamp}] {GREETING_MESSAGE} | Status: OK")
        time.sleep(5)

if __name__ == "__main__":
    try:
        run_agent()
    except KeyboardInterrupt:
        print("\nAgent stopped gracefully.")