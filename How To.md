# 🚀 Installing Odoo 16/17/18 on a Free Cloud Server (AWS Lightsail, DigitalOcean, etc.)

## 🔹 Scenario

If you need to install **Odoo 16, 17, or 18** on a **free cloud server** like **AWS Lightsail, DigitalOcean Droplets, or similar**, this guide will help you set up an Odoo instance at **zero cost**. This setup is perfect for **testing functionalities, running demos, or short-term development**.

### 🛠 Supported Versions

- **Odoo Versions:** 16, 17, 18, 19 (tested)
- **Ubuntu Version:** 24.04 LTS

## ✅ Step-by-Step Installation Guide

### 1️⃣ Create a Free Ubuntu 24.04 Server

- Sign up for **AWS Lightsail** and create a **90-day free Ubuntu 24.04 instance**.
- Choose a **basic server configuration** (e.g., 1GB RAM, 1vCPU, 20GB SSD).

### 2️⃣ Apply the Launch Script

During the instance creation process, **paste the following launch script** in the **"Launch Script"** section:

https://github.com/princeppy/odoo-install-scripts/blob/main/lightsail.aws/launch_script.sh

This script **automates the initial setup**, including system updates, package installations, and preparing the Odoo environment.

### 3️⃣ Access the Server via Browser-Based SSH

Once your instance is up and running:

- **Open AWS Lightsail** and select your instance.
- Click **"Connect using SSH"** to access the terminal.

### 4️⃣ Monitor Installation Progress

Run the following command to **track installation logs** in real time:

```sh
tail -f /tmp/launchscript.log
```

• Wait until you see:

```
Preinstallation Completed........
```

This indicates that the **server setup is complete**.

### 5️⃣ Elevate to Root User

Once the installation completes, switch to the root user to run administrative commands:

```sh
sudo su
```

### 6️⃣ Run the Odoo Installation Script

Now, execute the Odoo installation script:

```sh
bash /InstallScript/install_odoo.sh
```

• The script will download, install, and configure Odoo on your server.
• Once completed, look for the confirmation message:

```
Done
```

• Your Odoo instance is now ready to use! 🎉

## 📌 References & Additional Resources

For further reading and alternative installation scripts, check out these resources:
• Odoo Install Script by Yenthe666
• Odoo Install Script by Moaaz
• Odoo Install Script by Ventor Tech

## 🚀 Conclusion

By following this guide, you can quickly deploy Odoo 16/17/18/19 on a free Ubuntu 24.04 server using AWS Lightsail or similar platforms. This setup allows you to test Odoo functionalities, run demos, or perform short-term development—all without any cost.

💡 Got questions or need help? Drop a comment below! 🚀
