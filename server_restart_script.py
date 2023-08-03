import requests
import subprocess

def check_application_health():
    # Replace 'http://your_application_health_endpoint' with the actual URL of your application's health endpoint
    response = requests.get('http://your_application_health_endpoint')
    if response.status_code == 200:
        return True
    else:
        return False

def main():
    if not check_application_health():
        print("Application is unhealthy. Restarting the EC2 instance...")
        subprocess.run("sudo reboot", shell=True)

if __name__ == "__main__":
    main()
