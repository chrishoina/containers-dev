# Run this with: python3 random_requests.py

import requests
import random
import threading
import time
import signal
import sys

endpoints = [
    "http://localhost:8080/ords/ordstest/performance/owa_cgi",
    "http://localhost:8080/ords/ordstest/performance/sleep",
    "http://localhost:8080/ords/ordstest/table_a/",
    "http://localhost:8080/ords/ordstest/table_b/",
    "http://localhost:8080/ords/ordstest/table_a/1",
    "http://localhost:8080/ords/ordstest/table_b/1",
    "http://localhost:8080/ords/ordstest/table_a/2",
    "http://localhost:8080/ords/ordstest/table_b/2"
]

def graceful_exit(signum, frame):
    """Function called when the Bash script sends a kill signal."""
    print("\n[Control] Shutdown signal received from Bash. Stopping threads...")
    # Since threads are 'daemon=True', they will exit automatically when main exits
    sys.exit(0)

def send_random_request():
    thread_name = threading.current_thread().name
    url = random.choice(endpoints)
    try:
        response = requests.get(url)
        print(f"[{thread_name}] Requested: {url} | Status Code: {response.status_code}")
    except requests.RequestException as e:
        print(f"[{thread_name}] Error requesting {url}: {e}")

def worker():
    while True:
        send_random_request()
        time.sleep(1)

if __name__ == "__main__":
    # Register the signal handler for SIGTERM (sent by 'kill' command)
    # and SIGINT (sent by Ctrl+C)
    signal.signal(signal.SIGTERM, graceful_exit)
    signal.signal(signal.SIGINT, graceful_exit)

    num_threads = 30
    threads = []
    print(f"[Control] Starting {num_threads} threads. Waiting for signal to stop...")
    
    for i in range(num_threads):
        t = threading.Thread(target=worker, name=f"Requester-{i+1}", daemon=True)
        threads.append(t)
        t.start()

    # Instead of 'while True', we use signal.pause() on Unix systems
    # to wait for the signal without consuming CPU.
    try:
        while True:
            time.sleep(1)
    except SystemExit:
        pass