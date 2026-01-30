import subprocess
import concurrent.futures
import time

URL = "http://localhost:8080/ords/ordstest/sleep/sleep"
DURATION = 180  # 3 minutes in seconds
CONCURRENCY = 50

def run_curl():
    """Run one curl command and return the output."""
    result = subprocess.run(
        ["curl", "-s", "-w", "%{http_code}\n", "-o", "/dev/null", URL],
        capture_output=True,
        text=True
    )
    return result.stdout.strip()

def main():
    end_time = time.time() + DURATION
    with concurrent.futures.ThreadPoolExecutor(max_workers=CONCURRENCY) as executor:
        while time.time() < end_time:
            futures = [executor.submit(run_curl) for _ in range(CONCURRENCY)]
            for future in concurrent.futures.as_completed(futures):
                # Print or log the HTTP status code
                print(future.result())

if __name__ == "__main__":
    main()