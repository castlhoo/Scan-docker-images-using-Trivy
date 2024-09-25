# Scan-docker-images-using-Trivy
With Trivy, scan and check vulnerability of docker images and set automation tool.

Container which contains a number of valuable things for all, so security about contatiner is vital factors for tech industry. Therefore, scanning images are one of the most necessary elements for developers. Also engineer who uses docker, kubernates should know how to scan images. Aquasecurity Trivy is one such tool that helps you with all of that. It is a vulnerability and security misconfiguration scanner that can scan container images, filesystems, and Git repositories, for vulnerabilities and misconfigurations within IaC, Kubernetes Manifests, and Dockerfiles. Also, why I recommend all about Trivy, this is by far one of the most lightweight and feature-rich tools.
Today, I am gonna explore the tool "Trivy" and also set automation setting for safe container environment.

## Prerequisites
Before installing Trivy, you need to know your platforms. Trivy runs in several Linux platforms, including RHEL/CentOs, Ubuntu/Debian, Arch Linux, MacOs, Nix, etc. 

## 1. Installing Trivy
sudo apt-get install wget apt-transport-https gnupg lsb-release
> Install package from HTTPS with gnupg which contains software for encryption and authentication

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy-archive-keyring.gpg
> Download Public Key from URL, Pipes it to gpg --dearmor to convert it to a format usable by APT.
> Saves the converted key file as /usr/share/keyrings/trivy-archive-keyring.gpg.

echo "deb [signed-by=/usr/share/keyrings/trivy-archive-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null
>Adds Trivy’s repository to system.
> $(lsb_release -cs) automatically inserts the codename of current Ubuntu distribution

sudo apt update
sudo apt install trivy
> package update and install trivy

## 2. Pull pratice image from docker repository
docker pull castlehoo/my-java-app
![image](https://github.com/user-attachments/assets/cf820075-6924-42ac-901b-42ad59c1e648)


## 3. Scan docker image using Trivy
docker image castlehoo/my-java-app:1.0
![image](https://github.com/user-attachments/assets/8d56acc6-08d1-439a-98af-019c0d802c14)
As you can above, There is 42 high vulnerabilities in the image.

## Practice : Downsize vulnerability of the image and set automation
Using python, I Downsize vulnerability of the image and set automation. First, There are lot of ways to downsize vulnerability of the image
  ## 1. Ways to minimize vulnerability
  ### 1) Using the latest version package
  Using the latest version package is vital for security. When images are updated, they do security patch. Therefore, updating version package is important
  RUN apt-get update && apt-get upgrade -y

  ### 2) Using Alpine image
  When we use Alpine image, we can downsize the size of image. That means we can minimize the vulnerability of package.
  FROM openjdk:17-alpine AS build

  ### 3) Optimization build stage
  Distribute build and application which really need for operating system. It helps to lose weight image and strengthen security factors
  FROM openjdk:17-alpine AS build
WORKDIR /app
COPY . .
RUN javac Main.java

FROM openjdk:17-alpine
WORKDIR /app
COPY --from=build /app/Main.class /app/
CMD ["java", "Main"]


  ### 4) Eliminate unecessary file
  Using .dockerignore file, we can delete files which are not necessary. Therefore, it helps to minimize the size of image and impove effectivity of image.
  *.log
*.tmp
.git
/tests/
Dockerfile
docker-compose.yml

## 2. Setting for automation
This code is a pipeline that uses the Trivy security scanner to scan for HIGH-level vulnerabilities in Docker images. If the number of vulnerabilities exceeds 5, an email alert is sent, and the image is optimized using multi-stage builds. After optimization, the image is re-scanned to check if the vulnerabilities have been reduced, and the result is sent via email again.

Major Workflow:
Vulnerability Scanning with Trivy (check_trivy_vulnerabilities)
Sending Email Alerts (send_alert)
Image Optimization (Multi-stage Build) (optimize_image)
Re-scan the Optimized Image
Send Final Result via Email
I'll explain this code step-by-step, focusing on each function.

---

1. Vulnerability Scanning with Trivy (check_trivy_vulnerabilities)
This function runs a Trivy command to scan a Docker image for vulnerabilities of HIGH severity and filters them out.

python
def check_trivy_vulnerabilities(image_name):
    try:
        # Executes the Trivy command and retrieves the results in JSON format
        trivy_output = os.popen(f"trivy image --severity HIGH --format json {image_name}").read()
        trivy_data = json.loads(trivy_output)
        
        # Filters out only HIGH severity vulnerabilities from the list
        vulnerabilities = trivy_data.get('Results', [])[0].get('Vulnerabilities', [])
        high_vulns = [vuln for vuln in vulnerabilities if vuln['Severity'] == 'HIGH']
        
        return high_vulns  # Returns only HIGH severity vulnerabilities
    except Exception as e:
        print(f"Error running Trivy scan: {e}")
        return None  # Returns None if an error occurs
Input: image_name is the Docker image to be scanned by Trivy.
Process: Uses os.popen() to run the Trivy scan and filters out only the HIGH severity vulnerabilities.
Output: Returns a list containing only the HIGH severity vulnerabilities.

---

2. Sending Email Alerts (send_alert)
This function sends the list of vulnerabilities via email. It structures the details of vulnerabilities into a table format.

python
def send_alert(image_name, high_vulns, stage="initial"):
    from_email = "ksungho9991@gmail.com"
    to_email = "ksungho9991@gmail.com"
    password = "password"  # It's recommended to manage actual passwords via environment variables.

    # Set the email subject
    subject = f"Alert: Docker Image {image_name} - {stage.capitalize()}"
    
    # Create the email body
    body = ""
    if stage == "initial":
        body += f"Warning: Docker image {image_name} has {len(high_vulns)} HIGH vulnerabilities.\n\n"
    elif stage == "optimized":
        body += f"The image {image_name} has been optimized.\nCurrent HIGH vulnerabilities: {len(high_vulns)}.\n\n"

    # Structure vulnerability details into a table
    if high_vulns:
        table = PrettyTable()
        table.field_names = ["Vulnerability ID", "Package Name", "Installed Version", "Fixed Version", "Severity"]
        for vuln in high_vulns:
            vid = vuln.get("VulnerabilityID", "N/A")
            pkg_name = vuln.get("PkgName", "N/A")
            installed_version = vuln.get("InstalledVersion", "N/A")
            fixed_version = vuln.get("FixedVersion", "N/A")
            severity = vuln.get("Severity", "N/A")
            table.add_row([vid, pkg_name, installed_version, fixed_version, severity])
        
        body += f"Here are the details of the HIGH vulnerabilities:\n\n{table}\n"

    # Set up the email
    message = MIMEMultipart()
    message['From'] = from_email
    message['To'] = to_email
    message['Subject'] = subject
    message.attach(MIMEText(body, 'plain'))

    try:
        # Send the email
        with smtplib.SMTP("smtp.gmail.com", 587) as server:
            server.starttls()  # Activate TLS encryption
            server.login(from_email, password)  # Login to Gmail
            server.sendmail(from_email, to_email, message.as_string())
            print(f"Email alert sent to {to_email}")
    except Exception as e:
        print(f"Failed to send email: {e}")
Input:
image_name: The name of the Docker image to be displayed in the email.
high_vulns: A list of HIGH severity vulnerabilities obtained from Trivy.
stage: Identifies whether the scan is from the initial stage or after optimization.
Process:
Structures vulnerability details into a table using PrettyTable.
Sends the email containing vulnerability information.
Output: An email alert containing the vulnerability details is sent.

---

3. Image Optimization (Multi-stage Build) (optimize_image)
This function optimizes the Docker image by applying multi-stage builds. First, it builds the source code and dependencies, then only copies the necessary files into the final lightweight image.

python
def optimize_image(image_name):
    print("Optimizing the Docker image using multi-stage build...")

    dockerfile_content = """
    # Build stage
    FROM openjdk:17-alpine AS build

    # Update to the latest version of packages
    RUN apk update && apk upgrade --no-cache

    # Copy the source code
    WORKDIR /app
    COPY . .

    # Build the source code
    RUN javac Main.java

    # Final stage - Use a lightweight image for optimization
    FROM openjdk:17-alpine

    WORKDIR /app

    # Copy the build artifacts
    COPY --from=build /app/Main.class /app/

    # Run the application
    CMD ["java", "Main"]
    """

    # Create Dockerfile
    with open("Dockerfile", "w") as f:
        f.write(dockerfile_content)

    # Build the image without using cache
    os.system(f"docker build --no-cache -t {image_name}_optimized .")
Input: image_name is the name of the Docker image to be optimized.
Process:
Builds the source code using Alpine base images for a smaller size.
Copies only the necessary files into the final stage to minimize the image size.
Output: Builds the optimized Docker image.

---

4. Main Logic (__main__)
This section controls the overall process:

Runs Trivy to check for HIGH severity vulnerabilities.
If the vulnerabilities exceed 5, sends an email alert.
Optimizes the Docker image.
Re-scans the optimized image and sends the results via email.

python
if __name__ == "__main__":
    image_name = "castlehoo/my-java-app:1.0"
    
    # Scans for vulnerabilities with Trivy (HIGH severity only)
    high_vulns = check_trivy_vulnerabilities(image_name)

    if high_vulns is not None:
        print(f"Image {image_name} has {len(high_vulns)} HIGH vulnerabilities.")
        if len(high_vulns) > 5:
            # Sends an email alert if vulnerabilities exceed 5
            send_alert(image_name, high_vulns, stage="initial")
            
            # Optimize the image
            optimize_image(image_name)
            
            # Re-scan the optimized image with Trivy
            optimized_image_name = f"{image_name}_optimized"
            optimized_high_vulns = check_trivy_vulnerabilities(optimized_image_name)
            
            if optimized_high_vulns is not None:
                print(f"Optimized image {optimized_image_name} has {len(optimized_high_vulns)} HIGH vulnerabilities.")
                send_alert(optimized_image_name, optimized_high_vulns, stage="optimized")
            else:
                print(f"Failed to check vulnerabilities for optimized image {optimized_image_name}")
        else:
            print(f"Image {image_name} has acceptable HIGH vulnerabilities ({len(high_vulns)}).")
    else:
        print(f"Failed to check vulnerabilities for image {image_name}")

---

Summary of Key Features:
Trivy Vulnerability Scanning: Scans Docker images for HIGH severity vulnerabilities.
Email Alerts: Sends the number of vulnerabilities and their details via email in table format.
Image Optimization: Applies multi-stage builds to optimize and reduce image size.
Re-scan and Alerts: Re-scans the optimized image and sends the result via email.
This code helps to efficiently manage Docker images by automating the vulnerability scanning and optimization process, ensuring the image is as secure and lightweight as possible.


## 3. Results
Before
![image](https://github.com/user-attachments/assets/1cc11d28-4fad-4910-a9e6-f9d09b618c54)
After
![image](https://github.com/user-attachments/assets/55d278a2-7d3b-411b-af7d-e70592b6eb5a)
When you see two pictures above, there is a 56% of minimizng vulnerability of image.

