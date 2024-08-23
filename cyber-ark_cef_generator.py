import random
import time
import socket
from datetime import datetime

def randomize_ip():
    return '.'.join(str(random.randint(1, 255)) for _ in range(4))

def randomize_hostname():
    hosts = ["Core01p1ark007", "Core02p1ark008", "Core03p1ark009", "Core04p1ark010"]
    return random.choice(hosts)

def randomize_username():
    users = ["PasswordManager", "AdminUser", "SecurityUser", "BackupManager", "UserA", "UserB"]
    return random.choice(users)

def randomize_device_event_class():
    event_classes = ["50", "51", "52", "53", "54"]
    return random.choice(event_classes)

def randomize_activity():
    activities = ["Retrieve File", "Update Policy", "Delete File", "Access Directory", "Modify Configuration"]
    return random.choice(activities)

def randomize_log_severity():
    return str(random.randint(1, 10))  # Log severity from 1 to 10

def randomize_device_action():
    actions = ["Retrieve File", "Update File", "Delete File", "Access File", "Create File"]
    return random.choice(actions)

def randomize_destination_user_privileges():
    privileges = ["PasswordManagerShared", "AdminShared", "ReadOnly", "FullAccess", "LimitedAccess"]
    return random.choice(privileges)

def randomize_file_name():
    files = [
        r"root\policies\policyfile.ini",
        r"root\config\configfile.cfg",
        r"root\logs\logfile.log",
        r"root\data\userfile.txt",
        r"root\backups\backupfile.bak"
    ]
    return random.choice(files)

def generate_cef_message():
    device_vendor = "Cyber-Ark"
    device_product = "PTA"
    device_version = "12.6.0010"
    signature_id = randomize_device_event_class()
    name = randomize_activity()
    severity = randomize_log_severity()
    source_host_name = randomize_hostname()
    source_user_name = randomize_username()
    src_ip = randomize_ip()
    device_action = randomize_device_action()
    destination_user_privileges = randomize_destination_user_privileges()
    file_name = randomize_file_name()
    message = "#015"

    extension = (
        f"src={src_ip} "
        f"suser={source_user_name} "
        f"shost={source_host_name} "
        f"act={device_action} "
        f"dpriv={destination_user_privileges} "
        f"fname={file_name} "
        f"msg={message}"
    )

    cef_message = (
        f"CEF:0|{device_vendor}|{device_product}|{device_version}|{signature_id}|{name}|{severity}|{extension}"
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
