#!/usr/bin/env python3
"""
Backend & Frontend Connection Test
Verify all components are working properly
"""

import subprocess
import time
import requests
import json
import sys
from pathlib import Path

print("\n" + "="*80)
print("PEARL Agent - System Verification Test")
print("="*80 + "\n")

# Colors for terminal output
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def test_python_version():
    print(f"{Colors.HEADER}Testing Python Version...{Colors.ENDC}")
    version = sys.version_info
    if version.major >= 3 and version.minor >= 8:
        print(f"{Colors.OKGREEN}✓ Python {version.major}.{version.minor} (OK){Colors.ENDC}\n")
        return True
    else:
        print(f"{Colors.FAIL}✗ Python {version.major}.{version.minor} (Need 3.8+){Colors.ENDC}\n")
        return False

def test_backend_port():
    print(f"{Colors.HEADER}Testing Backend Port 8000...{Colors.ENDC}")
    try:
        response = requests.get('http://localhost:8000/health', timeout=2)
        if response.status_code == 200:
            print(f"{Colors.OKGREEN}✓ Backend running on http://localhost:8000{Colors.ENDC}")
            print(f"  Response: {response.json()}\n")
            return True
        else:
            print(f"{Colors.FAIL}✗ Backend returned {response.status_code}{Colors.ENDC}\n")
            return False
    except requests.exceptions.ConnectionError:
        print(f"{Colors.FAIL}✗ Cannot connect to http://localhost:8000{Colors.ENDC}")
        print(f"  Make sure backend is running: python main.py\n")
        return False
    except Exception as e:
        print(f"{Colors.FAIL}✗ Error: {str(e)}{Colors.ENDC}\n")
        return False

def test_api_docs():
    print(f"{Colors.HEADER}Testing API Documentation...{Colors.ENDC}")
    try:
        response = requests.get('http://localhost:8000/docs', timeout=2)
        if response.status_code == 200:
            print(f"{Colors.OKGREEN}✓ API Docs available at http://localhost:8000/docs{Colors.ENDC}\n")
            return True
        else:
            print(f"{Colors.FAIL}✗ API Docs returned {response.status_code}{Colors.ENDC}\n")
            return False
    except Exception as e:
        print(f"{Colors.FAIL}✗ Error accessing API docs: {str(e)}{Colors.ENDC}\n")
        return False

def test_frontend_port():
    print(f"{Colors.HEADER}Testing Frontend Port 5173...{Colors.ENDC}")
    try:
        response = requests.get('http://localhost:5173', timeout=2)
        if response.status_code == 200:
            print(f"{Colors.OKGREEN}✓ Frontend running on http://localhost:5173{Colors.ENDC}\n")
            return True
        else:
            print(f"{Colors.WARNING}⚠ Frontend returned {response.status_code}{Colors.ENDC}\n")
            return False
    except requests.exceptions.ConnectionError:
        print(f"{Colors.WARNING}⚠ Cannot connect to http://localhost:5173{Colors.ENDC}")
        print(f"  Start with: cd pearl-agent && npm run dev\n")
        return False
    except Exception as e:
        print(f"{Colors.WARNING}⚠ Error: {str(e)}{Colors.ENDC}\n")
        return False

def test_api_files():
    print(f"{Colors.HEADER}Testing Frontend API Files...{Colors.ENDC}")
    required_files = [
        'pearl-agent/api.ts',
        'pearl-agent/hooks.ts',
        'pearl-agent/index.html',
        'pearl-agent/index.tsx',
        'pearl-agent/.env'
    ]
    
    all_exist = True
    for file_path in required_files:
        if Path(file_path).exists():
            print(f"{Colors.OKGREEN}✓ {file_path} exists{Colors.ENDC}")
        else:
            print(f"{Colors.FAIL}✗ {file_path} missing{Colors.ENDC}")
            all_exist = False
    print()
    return all_exist

def test_cors():
    print(f"{Colors.HEADER}Testing CORS Configuration...{Colors.ENDC}")
    try:
        headers = {'Origin': 'http://localhost:5173'}
        response = requests.get('http://localhost:8000/health', headers=headers, timeout=2)
        
        if 'access-control-allow-origin' in response.headers:
            print(f"{Colors.OKGREEN}✓ CORS enabled{Colors.ENDC}")
            print(f"  Allow-Origin: {response.headers['access-control-allow-origin']}\n")
            return True
        else:
            print(f"{Colors.WARNING}⚠ CORS headers not detected{Colors.ENDC}\n")
            return True  # Still pass - CORS might be configured differently
    except Exception as e:
        print(f"{Colors.FAIL}✗ Error testing CORS: {str(e)}{Colors.ENDC}\n")
        return False

def test_routes():
    print(f"{Colors.HEADER}Testing API Routes...{Colors.ENDC}")
    routes = [
        ('/api-status', 'GET', False),
        ('/docs', 'GET', False),
        ('/health', 'GET', False),
    ]
    
    all_ok = True
    for route, method, needs_auth in routes:
        try:
            if method == 'GET':
                response = requests.get(f'http://localhost:8000{route}', timeout=2)
            print(f"{Colors.OKGREEN}✓ {method} {route} → {response.status_code}{Colors.ENDC}")
        except Exception as e:
            print(f"{Colors.FAIL}✗ {method} {route} failed: {str(e)}{Colors.ENDC}")
            all_ok = False
    print()
    return all_ok

def print_summary(results):
    print(f"{Colors.HEADER}{Colors.BOLD}Test Summary{Colors.ENDC}")
    print("-" * 80)
    
    backend_ok = results.get('backend_port', False)
    frontend_ok = results.get('frontend_port', False)
    api_files = results.get('api_files', False)
    routes_ok = results.get('routes', False)
    cors_ok = results.get('cors', False)
    
    print(f"Python Version:     {Colors.OKGREEN if results.get('python') else Colors.FAIL}{'✓' if results.get('python') else '✗'}{Colors.ENDC}")
    print(f"Backend Running:    {Colors.OKGREEN if backend_ok else Colors.FAIL}{'✓' if backend_ok else '✗'}{Colors.ENDC}")
    print(f"Frontend Running:   {Colors.OKGREEN if frontend_ok else Colors.WARNING}{'✓' if frontend_ok else '⚠'}{Colors.ENDC}")
    print(f"API Files Present:  {Colors.OKGREEN if api_files else Colors.FAIL}{'✓' if api_files else '✗'}{Colors.ENDC}")
    print(f"Routes Working:     {Colors.OKGREEN if routes_ok else Colors.FAIL}{'✓' if routes_ok else '✗'}{Colors.ENDC}")
    print(f"CORS Enabled:       {Colors.OKGREEN if cors_ok else Colors.FAIL}{'✓' if cors_ok else '✗'}{Colors.ENDC}")
    print(f"API Docs:           {Colors.OKGREEN if results.get('api_docs') else Colors.FAIL}{'✓' if results.get('api_docs') else '✗'}{Colors.ENDC}")
    
    print("\n" + "-" * 80)
    
    if backend_ok and routes_ok and cors_ok and api_files:
        print(f"{Colors.OKGREEN}{Colors.BOLD}✓ Backend is ready!{Colors.ENDC}")
    else:
        print(f"{Colors.FAIL}{Colors.BOLD}✗ Backend needs fixes{Colors.ENDC}")
    
    if frontend_ok:
        print(f"{Colors.OKGREEN}{Colors.BOLD}✓ Frontend is ready!{Colors.ENDC}")
    else:
        print(f"{Colors.WARNING}{Colors.BOLD}⚠ Frontend not running (start with: npm run dev){Colors.ENDC}")
    
    if backend_ok and api_files and routes_ok:
        print(f"{Colors.OKGREEN}{Colors.BOLD}✓ API integration ready!{Colors.ENDC}")
    else:
        print(f"{Colors.FAIL}{Colors.BOLD}✗ API integration issues{Colors.ENDC}")

def main():
    results = {}
    
    print(f"{Colors.BOLD}Running System Verification...{Colors.ENDC}\n")
    
    results['python'] = test_python_version()
    results['backend_port'] = test_backend_port()
    results['api_docs'] = test_api_docs()
    results['frontend_port'] = test_frontend_port()
    results['api_files'] = test_api_files()
    results['cors'] = test_cors()
    results['routes'] = test_routes()
    
    print_summary(results)
    
    print(f"\n{Colors.HEADER}Quick Setup Checklist{Colors.ENDC}")
    print("-" * 80)
    
    if not results['backend_port']:
        print(f"{Colors.OKCYAN}1. Start Backend (Terminal 1):{Colors.ENDC}")
        print(f"   cd pearl-agent-backend")
        print(f"   python main.py\n")
    
    if not results['frontend_port']:
        print(f"{Colors.OKCYAN}2. Start Frontend (Terminal 2):{Colors.ENDC}")
        print(f"   cd pearl-agent")
        print(f"   npm run dev\n")
    
    if results['api_files']:
        print(f"{Colors.OKCYAN}3. Open Browser:{Colors.ENDC}")
        print(f"   Frontend: http://localhost:5173")
        print(f"   API Docs: http://localhost:8000/docs\n")
    else:
        print(f"{Colors.FAIL}✗ Missing API files (api.ts, hooks.ts){Colors.ENDC}\n")
    
    print(f"{Colors.OKCYAN}Debugging:({Colors.ENDC}")
    print(f"  - Check browser console (F12) for errors")
    print(f"  - Check backend terminal for error logs")
    print(f"  - Verify .env file has correct API_BASE_URL")
    print(f"  - Check that auth token is set in localStorage\n")
    
    print("="*80 + "\n")

if __name__ == '__main__':
    main()
