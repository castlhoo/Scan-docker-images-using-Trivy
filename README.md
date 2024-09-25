# 📦 Scan Docker Images using Trivy

With Trivy, scan and check vulnerability of Docker images and set automation tools to improve security.

Container security is a critical aspect of the tech industry, as containers often hold valuable information. Scanning images for vulnerabilities is a key step in ensuring the safety of Docker containers, and Trivy by Aqua Security is a lightweight, feature-rich tool for this task.

In this guide, we will explore how to scan Docker images for vulnerabilities using Trivy and set up an automation process to optimize images, reducing vulnerabilities and ensuring a safer container environment.

---

## 🚀 Prerequisites

Before installing Trivy, you should know your platform. Trivy runs on various Linux distributions, including:
- **RHEL/CentOS**
- **Ubuntu/Debian**
- **Arch Linux**
- **macOS**
- **Nix**

## 1️⃣ Installing Trivy

### Install required packages:
```bash
sudo apt-get install wget apt-transport-https gnupg lsb-release
```
> Install package from HTTPS with gnupg which contains software for encryption and authentication

Explanation:
- `wget` - for downloading files
- `apt-transport-https` - for HTTPS support in APT
- `gnupg` - for encryption and authentication
- `lsb-release` - for determining the Linux distribution version

### Download and add the Trivy GPG key:
```bash
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy-archive-keyring.gpg
```

Explanation:
- Downloads the Trivy public key and converts it to a format usable by APT.

### Add the Trivy repository:
```bash
echo "deb [signed-by=/usr/share/keyrings/trivy-archive-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null
```

Explanation:
- Adds Trivy’s repository to the system. The `$(lsb_release -cs)` automatically inserts your current Ubuntu distribution codename.

### Update and install Trivy:
```bash
sudo apt update
sudo apt install trivy
```

---

## 2️⃣ Pull practice image from Docker Hub

Pull a Docker image for testing:
```bash
docker pull castlehoo/my-java-app
```
![image](https://github.com/user-attachments/assets/cf820075-6924-42ac-901b-42ad59c1e648)

---

## 3️⃣ Scan Docker Image using Trivy

Scan the Docker image:
```bash
docker image scan castlehoo/my-java-app:1.0
```
![image](https://github.com/user-attachments/assets/8d56acc6-08d1-439a-98af-019c0d802c14)
You will see 42 high vulnerabilities above image:


---


## Ways to minimize vulnerability

#### 1️⃣ Using the latest version of packages
Always update to the latest version:
```Dockerfile
RUN apt-get update && apt-get upgrade -y
```
> Using the latest version package is vital for security. When images are updated, they do security patch. Therefore, updating version package is important

#### 2️⃣ Use Alpine image
Alpine images are smaller, thus reducing potential vulnerabilities:
```Dockerfile
FROM openjdk:17-alpine AS build
```
> When we use Alpine image, we can downsize the size of image. That means we can minimize the vulnerability of package.

#### 3️⃣ Optimization through build stages
Distribute builds and application dependencies using multi-stage builds:
```Dockerfile
FROM openjdk:17-alpine AS build
WORKDIR /app
COPY . .
RUN javac Main.java

FROM openjdk:17-alpine
WORKDIR /app
COPY --from=build /app/Main.class /app/
CMD ["java", "Main"]
```
> Distribute build and application which really need for operating system. It helps to lose weight image and strengthen security factors

#### 4️⃣ Eliminate unnecessary files
Use a `.dockerignore` file to remove files that are not needed:
```plaintext
*.log
*.tmp
.git
/tests/
Dockerfile
docker-compose.yml
```
> Using .dockerignore file, we can delete files which are not necessary. Therefore, it helps to minimize the size of image and impove effectivity of image.

---
# 🛠️ Practice: Downsize Vulnerabilities & Set Automation

### Setting up Automation

The code provided below automates the vulnerability scanning process. It uses Trivy to scan for **HIGH-level** vulnerabilities. If the vulnerabilities exceed 5, an email alert is sent. The image is then optimized using multi-stage builds, re-scanned, and a final result is emailed.

### Major Workflow:
1. Vulnerability Scanning with Trivy (`check_trivy_vulnerabilities`)
2. Sending Email Alerts (`send_alert`)
3. Image Optimization (Multi-stage Build) (`optimize_image`)
4. Re-scan the Optimized Image
5. Send Final Result via Email

---

## 📄 Code Explanation:

### 🔍 Vulnerability Scanning with Trivy (`check_trivy_vulnerabilities`)

```python
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
```
### Input
  -  image_name is the Docker image to be scanned by Trivy.
### Process
  - Uses os.popen() to run the Trivy scan and filters out only the HIGH severity vulnerabilities.
### Output
  - Returns a list containing only the HIGH severity vulnerabilities.
---
### ✉️ Sending Email Alerts (`send_alert`)

```python
def send_alert(image_name, high_vulns, stage="initial"):
    from_email = "your_email@gmail.com"
    to_email = "recipient_email@gmail.com"
    password = "password"  # Use environment variables for security.

    # Set the email subject
    subject = f"Alert: Docker Image {image_name} - {stage.capitalize()}"
    
    # Create the email body
    body = ""
    if stage == "initial":
        body += f"Warning: Docker image {image_name} has {len(high_vulns)} HIGH vulnerabilities.

"
    elif stage == "optimized":
        body += f"The image {image_name} has been optimized.
Current HIGH vulnerabilities: {len(high_vulns)}.

"

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
        
        body += f"Here are the details of the HIGH vulnerabilities:

{table}
"

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
```
### Input:
- **image_name**: The name of the Docker image to be displayed in the email.
- **high_vulns**: A list of HIGH severity vulnerabilities obtained from Trivy.
- **stage**: Identifies whether the scan is from the initial stage or after optimization.

### Process:
- Structures vulnerability details into a table using `PrettyTable`.
- Sends the email containing the vulnerability information.

### Output:
- An email alert is sent containing the vulnerability details.
---
### 🛠 Image Optimization (Multi-stage Build)

This function optimizes the Docker image by applying multi-stage builds. It first builds the source code and dependencies, then only copies the necessary files into the final lightweight image.

```python
def optimize_image(image_name):
    print("Optimizing the Docker image using multi-stage build...")

    dockerfile_content = '''
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
    '''

    # Create Dockerfile
    with open("Dockerfile", "w") as f:
        f.write(dockerfile_content)

    # Build the image without using cache
    os.system(f"docker build --no-cache -t {image_name}_optimized .")
```

### Input:
- **image_name**: The name of the Docker image to be optimized.

### Process:
- Builds the source code using Alpine base images for a smaller size.
- Copies only the necessary files into the final stage to minimize the image size.

### Output:
- Builds the optimized Docker image.
---
### 🔄 Main Logic

This section controls the overall process:

- Runs Trivy to check for HIGH severity vulnerabilities.
- If the vulnerabilities exceed 5, sends an email alert.
- Optimizes the Docker image.
- Re-scans the optimized image and sends the results via email.

```python
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
```

---

## 📝 Summary of Key Features:

- **Trivy Vulnerability Scanning**: Scans Docker images for HIGH severity vulnerabilities.
- **Email Alerts**: Sends the number of vulnerabilities and their details via email in a table format.
- **Image Optimization**: Applies multi-stage builds to optimize and reduce image size.
- **Re-scan and Alerts**: Re-scans the optimized image and sends the result via email.

This process helps to efficiently manage Docker images by automating the vulnerability scanning and optimization process, ensuring that the image is as secure and lightweight as possible.

---

## 📊 Results:

### Before:
![image](https://github.com/user-attachments/assets/1cc11d28-4fad-4910-a9e6-f9d09b618c54)

### After:
![image](https://github.com/user-attachments/assets/55d278a2-7d3b-411b-af7d-e70592b6eb5a)

### When you see the two pictures above, there is a 56% reduction in the vulnerability count of the image! 🚀🔐
---

## Conclusion:
### This process helps in the automation of Docker image security scanning with Trivy, providing alerts when vulnerabilities are detected and optimizing Docker images to reduce the attack surface.

