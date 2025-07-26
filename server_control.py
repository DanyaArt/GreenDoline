#!/usr/bin/env python3
"""
Веб-интерфейс управления домашним сервером
Запуск: python3 server_control.py
"""

from flask import Flask, render_template, request, jsonify, redirect, url_for
import subprocess
import psutil
import os
import json
from datetime import datetime

app = Flask(__name__)

def run_command(command):
    """Выполнение команды и возврат результата"""
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=10)
        return result.stdout, result.stderr, result.returncode
    except subprocess.TimeoutExpired:
        return "", "Команда превысила время выполнения", 1
    except Exception as e:
        return "", str(e), 1

def get_system_info():
    """Получение информации о системе"""
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        # Получение температуры CPU (если доступно)
        try:
            temp_output = subprocess.run(['sensors'], capture_output=True, text=True)
            temp_lines = temp_output.stdout.split('\n')
            cpu_temp = "N/A"
            for line in temp_lines:
                if 'Core 0' in line or 'Package id 0' in line:
                    temp_parts = line.split()
                    for part in temp_parts:
                        if '°C' in part:
                            cpu_temp = part
                            break
        except:
            cpu_temp = "N/A"
        
        return {
            'cpu_percent': cpu_percent,
            'memory_percent': memory.percent,
            'memory_used': f"{memory.used // (1024**3):.1f}GB",
            'memory_total': f"{memory.total // (1024**3):.1f}GB",
            'disk_percent': disk.percent,
            'disk_used': f"{disk.used // (1024**3):.1f}GB",
            'disk_total': f"{disk.total // (1024**3):.1f}GB",
            'cpu_temp': cpu_temp
        }
    except Exception as e:
        return {'error': str(e)}

def get_service_status():
    """Получение статуса сервисов"""
    services = {}
    
    # Проверка Nginx
    stdout, stderr, code = run_command('systemctl is-active nginx')
    services['nginx'] = stdout.strip() if code == 0 else 'inactive'
    
    # Проверка Supervisor процессов
    stdout, stderr, code = run_command('supervisorctl status')
    if code == 0:
        for line in stdout.split('\n'):
            if line.strip():
                parts = line.split()
                if len(parts) >= 2:
                    service_name = parts[0]
                    status = parts[1]
                    services[service_name] = status
    else:
        services['webapp'] = 'unknown'
        services['telegram_bot'] = 'unknown'
    
    return services

@app.route('/')
def index():
    """Главная страница управления сервером"""
    system_info = get_system_info()
    services = get_service_status()
    
    # Получение внешнего IP
    stdout, stderr, code = run_command('curl -s ifconfig.me')
    external_ip = stdout.strip() if code == 0 else 'Недоступен'
    
    # Получение локального IP
    stdout, stderr, code = run_command("hostname -I | awk '{print $1}'")
    local_ip = stdout.strip() if code == 0 else 'Недоступен'
    
    return render_template('server_control.html', 
                         system_info=system_info,
                         services=services,
                         external_ip=external_ip,
                         local_ip=local_ip)

@app.route('/api/start_server')
def api_start_server():
    """API для запуска сервера"""
    stdout, stderr, code = run_command('~/start_server.sh')
    return jsonify({
        'success': code == 0,
        'output': stdout,
        'error': stderr
    })

@app.route('/api/stop_server')
def api_stop_server():
    """API для остановки сервера"""
    stdout, stderr, code = run_command('~/stop_server.sh')
    return jsonify({
        'success': code == 0,
        'output': stdout,
        'error': stderr
    })

@app.route('/api/restart_server')
def api_restart_server():
    """API для перезапуска сервера"""
    stdout, stderr, code = run_command('~/restart_server.sh')
    return jsonify({
        'success': code == 0,
        'output': stdout,
        'error': stderr
    })

@app.route('/api/status')
def api_status():
    """API для получения статуса"""
    system_info = get_system_info()
    services = get_service_status()
    return jsonify({
        'system': system_info,
        'services': services
    })

@app.route('/api/backup')
def api_backup():
    """API для создания резервной копии"""
    stdout, stderr, code = run_command('~/backup.sh')
    return jsonify({
        'success': code == 0,
        'output': stdout,
        'error': stderr
    })

@app.route('/api/power_save')
def api_power_save():
    """API для включения режима экономии энергии"""
    stdout, stderr, code = run_command('~/power_save.sh')
    return jsonify({
        'success': code == 0,
        'output': stdout,
        'error': stderr
    })

@app.route('/logs')
def logs():
    """Страница с логами"""
    log_files = {
        'webapp': '/var/log/webapp.out.log',
        'telegram_bot': '/var/log/telegram_bot.out.log',
        'nginx_error': '/var/log/nginx/error.log',
        'nginx_access': '/var/log/nginx/access.log'
    }
    
    logs_data = {}
    for name, path in log_files.items():
        try:
            with open(path, 'r', encoding='utf-8') as f:
                # Последние 50 строк
                lines = f.readlines()
                logs_data[name] = ''.join(lines[-50:])
        except Exception as e:
            logs_data[name] = f"Ошибка чтения лога: {str(e)}"
    
    return render_template('logs.html', logs=logs_data)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False) 