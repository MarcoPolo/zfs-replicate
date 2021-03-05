# -*- coding: utf-8 -*-
"""SSH Command Generator."""
from .cipher import Cipher


def command(ssh_path: str, cipher: Cipher, user: str, key_file: str, port: int, host: str) -> str:
    """Generate ssh commandline invocation."""
    ssh = "/usr/bin/env - ssh"
    if ssh_path:
        ssh = ssh_path

    options = []

    if cipher == Cipher.FAST:
        options.append("-c arcfour256,arcfour128,blowfish-cbc,aes128-ctr,aes192-ctr,aes256-ctr")
    elif cipher == Cipher.DISABLED:
        options.extend(["-o noneenabled=yes", "-o noneswitch=yes"])

    options.extend([f"-i {key_file}", "-o BatchMode=yes", "-o StrictHostKeyChecking=yes", "-o ConnectTimeout=7"])

    if user:
        options.append(f"-l {user}")

    options.extend([f"-p {port}", host])

    return ssh + " " + " ".join(options)
