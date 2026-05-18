#!/usr/bin/env python3
"""
When a numbered workspace is destroyed (goes empty), move all windows from
higher-numbered workspaces down by one so there are no gaps.
"""
import json
import os
import socket
import subprocess
import time


def hyprctl_json(cmd, *args):
    r = subprocess.run(['hyprctl', cmd, '-j', *args], capture_output=True, text=True)
    return json.loads(r.stdout)


def hyprctl(cmd, *args):
    subprocess.run(['hyprctl', cmd, *args], capture_output=True)


def cascade(destroyed_id: int):
    workspaces = hyprctl_json('workspaces')
    higher = sorted(
        [ws for ws in workspaces if isinstance(ws['id'], int) and ws['id'] > destroyed_id],
        key=lambda ws: ws['id'],
    )
    if not higher:
        return

    clients = hyprctl_json('clients')
    for ws in higher:
        ws_id = ws['id']
        target = ws_id - 1
        windows = [c['address'] for c in clients if c['workspace']['id'] == ws_id]
        for addr in windows:
            hyprctl('dispatch', f'movetoworkspacesilent {target},address:{addr}')


def get_socket_path():
    sig = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', '')
    if not sig:
        runtime = os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')
        hypr_dir = f'{runtime}/hypr'
        try:
            entries = os.listdir(hypr_dir)
            if entries:
                sig = entries[0]
        except OSError:
            pass
    runtime = os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')
    return f'{runtime}/hypr/{sig}/.socket2.sock'


def listen():
    path = get_socket_path()
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(path)

    buf = ''
    while True:
        data = sock.recv(4096).decode('utf-8', errors='ignore')
        if not data:
            break
        buf += data
        while '\n' in buf:
            line, buf = buf.split('\n', 1)
            line = line.strip()
            if '>>' not in line:
                continue
            event, payload = line.split('>>', 1)
            if event == 'destroyworkspacev2':
                ws_id_str = payload.split(',', 1)[0]
                try:
                    ws_id = int(ws_id_str)
                    if ws_id > 0:
                        cascade(ws_id)
                except ValueError:
                    pass


if __name__ == '__main__':
    while True:
        try:
            listen()
        except (ConnectionRefusedError, FileNotFoundError, OSError):
            time.sleep(2)
        except Exception:
            time.sleep(1)
