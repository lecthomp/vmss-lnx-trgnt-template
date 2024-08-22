import random
import time
import socket
from datetime import datetime

def randomize_ip():
    return '.'.join(str(random.randint(1, 255)) for _ in range(4))

def randomize_username(domain):
    users = ["mike2", "john3", "jane4", "alice5", "bob6","perry7"]
    return f"{random.choice(users)}@{domain}"

def randomize_domain():
    domains = ["prod1.domain.com", "dev1.domain.com", "test1.domain.com"]
    return random.choice(domains)

def generate_cef_message():
    timestamp = int(datetime.now().timestamp() * 1000)
    suser = randomize_username("prod1.domain.com")
    shost = randomize_domain()
    src = randomize_ip()
    duser = randomize_username("dev1.domain.com")
    dhost = randomize_domain()
    dst = randomize_ip()
    event_id = f"{random.randint(10000000, 99999999):x}ec3500ed864c461e"

    cef_message = (
        f"CEF:0|CyberArk|PTA|14.2|1|Suspected credentials theft|8|"
        f"suser={suser} shost={shost} src={src} "
        f"duser={duser} dhost={dhost} dst={dst} "
        f"cs1Label=ExtraData cs1=None "
        f"cs2Label=EventID cs2={event_id} "
        f"deviceCustomDate1Label=detectionDate deviceCustomDate1={timestamp} "
        f"cs3Label=PTAlink cs3=https://{src}/incidents/{event_id} "
        f"cs4Label=ExternalLink cs4=None"
    )
    return cef_message

def send_syslog_message(cef_message, syslog_server, syslog_port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.sendto(cef_message.encode('utf-8'), (syslog_server, syslog_port))

def main():
    syslog_server = "10.0.0.4"
    syslog_port = 514

    while True:
        cef_message = generate_cef_message()
        print(f"Sending: {cef_message}")
        send_syslog_message(cef_message, syslog_server, syslog_port)
        time.sleep(5)

if __name__ == "__main__":
    main()
