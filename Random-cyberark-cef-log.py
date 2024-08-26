import random
import time
import socket
from datetime import datetime

def randomize_ip():
    return '.'.join(str(random.randint(1, 255)) for _ in range(4))

def randomize_hostname():
    hosts = ["CORE11P1ARKW007", "CORE12P1ARKW008", "CORE13P1ARKW009", "CORE14P1ARKW010"]
    return random.choice(hosts)

def randomize_username():
    users = ["Batch", "Admin", "Security", "UserA", "UserB"]
    return random.choice(users)

def randomize_file_name():
    files = [
        r"root\policies\policyfile.ini",
        r"root\config\configfile.cfg",
        r"root\logs\logfile.log",
        r"root\data\userfile.txt",
        r"root\backups\backupfile.bak"
    ]
    return random.choice(files)

def randomize_signature_id():
    # Example of possible signature IDs, adjust as needed
    return random.choice(["311", "312", "313", "314", "315"])

def randomize_name():
    # Example of possible event names, adjust as needed
    return random.choice([
        "Monitor DR Replication end",
        "User Access Request",
        "Failed Login Attempt",
        "Password Change",
        "Policy Update"
    ])

def randomize_severity():
    return str(random.randint(1, 10))  # Severity from 1 to 10

def generate_cef_message():
    timestamp = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ")
    device_vendor = "CYBER-ARK"
    device_product = "VAULT"
    device_version = "14.0.0000"
    signature_id = randomize_signature_id()
    name = randomize_name()
    severity = randomize_severity()
    source_host_name = randomize_hostname()
    source_user_name = randomize_username()
    src_ip = randomize_ip()
    file_name = randomize_file_name()
    message = "Event completed successfully"

    extension = (
        f"act={name} "
        f"suser={source_user_name} "
        f"fname={file_name} "
        f"dvc=unknown "
        f"shost={source_host_name} "
        f"sourceTranslatedAddress={src_ip} "
        f"dhost=unknown "
        f"duser=unknown "
        f"externalId=unknown "
        f"app=unknown "
        f"reason=unknown "
        f"spriv=unknown "
        f"dpriv=unknown "
        f"fileType=unknown "
        f"deviceExternalId=unknown "
        f"dproc=unknown "
        f"fileId=unknown "
        f"oldFileId=unknown "
        f"msg={message}"
    )

    cef_message = (
        f"<5> 1 {timestamp} CORE11P1ARKW007 CYBER-ARK VAULT {signature_id}- "
        f"CEF:0|{device_vendor}|{device_product}|{device_version}|{signature_id}|{name}|{severity}|{extension}"
    )

    return cef_message

def send_syslog_message(cef_message, syslog_server, syslog_port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.sendto(cef_message.encode('utf-8'), (syslog_server, syslog_port))

def main():
    syslog_server = "10.0.0.4"  # Replace with your Syslog server IP
    syslog_port = 514  # Replace with your Syslog server port

    while True:
        cef_message = generate_cef_message()
        print(f"Sending: {cef_message}")
        send_syslog_message(cef_message, syslog_server, syslog_port)
        time.sleep(5)  # Adjust the sleep interval as needed

if __name__ == "__main__":
    main()
