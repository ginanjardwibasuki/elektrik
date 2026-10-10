# ⚡ Elektrik Server Autoinstall & Deployment

<div align="center">

![Proxmox](https://img.shields.io/badge/Proxmox-VE-E57000?style=for-the-badge&logo=proxmox&logoColor=white)
![Debian 13](https://img.shields.io/badge/Debian-13-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-v20-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![PHP 8.4](https://img.shields.io/badge/PHP-8.4-777BB4?style=for-the-badge&logo=php&logoColor=white)
![Cloudflare](https://img.shields.io/badge/Cloudflare-Tunnel-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)

*An advanced automation script to instantly deploy a complete application stack inside an LXC Container on Proxmox VE.*

</div>

---

## 🚀 Key Features & Highlights

* **Proxmox LXC Integration**: Automatically detects available container IDs, downloads the Debian 13 template, and handles hardware provisioning (CPU, RAM, Disk, Swap, Network).
* **Modern Web Stack**: Installs Apache2 and PHP 8.4 with essential extensions (`php-gd`, `mysql`, `mbstring`, etc.) along with MariaDB Server.
* **Backend & Automation (Puppeteer)**: Supports Node.js, PM2 process manager, and Puppeteer for web scraping and automation tasks.
* **🤖 Auto-Backup via Telegram Bot**: Scheduled daily backup system (Database + Image directory) that automatically compresses data and sends archives directly to your Telegram.
* **☁️ Cloudflare Tunnel (Argo)**: Automatically creates a secure tunnel via API, registers CNAME records dynamically, and connects your website and backend without messy router port forwarding.

---

## 📋 Prerequisites & Credential Setup

Before executing the autoinstall script, make sure you have prepared the required authentication tokens and IDs for **Telegram Automated Backups** and **Cloudflare Argo Tunneling**.

---

### 🤖 Telegram Backup Credentials

To enable automated daily backups sent directly to your Telegram chat or channel, you need a **Bot Token** and your **Chat ID**.

#### 1. How to Get a Telegram Bot Token

1. Open the Telegram app and search for **`@BotFather`** (the official bot manager).
2. Press **Start** or send the command:
   ```text
   /newbot
   ```
3. Enter a **Name** for your bot (e.g., `Elektrik Backup Bot`).
4. Enter a unique **Username** ending in `bot` (e.g., `elektrik_backup_bot`).
5. **BotFather** will reply with an API Token formatted like this:
   ```text
   7123456789:AAE1234567890abcdefghijklmnopqrstuvwxyz
   ```
6. Copy and save this HTTP API Token.

#### 2. How to Get Your Telegram Chat ID

* **For Personal Chat:**
  1. Search for **`@userinfobot`** or **`@GetIDBot`** on Telegram.
  2. Send `/start` to the bot.
  3. The bot will respond with your **Id** (e.g., `123456789`). This numerical value is your **Chat ID**.

* **For Group or Channel Backup:**
  1. Add your newly created bot to the target group or channel as an **Administrator**.
  2. Send a test message in that group or channel.
  3. Forward a message from the channel to **`@GetIDBot`** to retrieve the Channel Chat ID (Channel/Group IDs typically start with a minus sign, e.g., `-1001234567890`).

---

### ☁️ Cloudflare Tunneling Credentials

To automatically provision a secure zero-trust tunnel without forwarding public router ports, you will need your **Account ID**, **Zone Name/ID**, and a **Cloudflare API Token**.

#### 1. How to Get Your Account ID & Zone Details

1. Log in to the [Cloudflare Dashboard](https://dash.cloudflare.com/).
2. Select the domain name (Zone) you want to map your server to (e.g., `example.com`).
3. **Zone Name**: This is simply your domain name (e.g., `example.com`).
4. On the domain **Overview** page, scroll down the right-side sidebar to the **API** section.
5. You will see both your **Zone ID** and **Account ID**. Copy both values.

#### 2. How to Get Your Cloudflare API Token

1. Click on your **User Profile Icon** at the top-right corner of Cloudflare Dashboard and select **My Profile**.
2. Select **API Tokens** from the left-hand navigation menu.
3. Click **Create Token**.
4. Scroll down to **Create Custom Token** and click **Get started**.
5. Set a descriptive **Token Name** (e.g., `Elektrik Auto Tunnel`).
6. Under **Permissions**, add the following three rules:
   * `Account` | `Cloudflare Tunnel` | `Edit`
   * `Zone` | `DNS` | `Edit`
   * `Zone` | `Zone` | `Read`
7. Under **Account Resources**, select **Include** -> **Your Account Name**.
8. Under **Zone Resources**, select **Include** -> **All zones** (or choose your specific domain).
9. Click **Continue to summary** and then click **Create Token**.
10. Copy and safely store your generated API token. *(Note: Cloudflare will only display this token once!)*

---

## 🛠️ Installation

Run the single-line command below directly from your **Proxmox Host** terminal:

```bash
bash <(curl -s https://raw.githubusercontent.com/ginanjardwibasuki/elektrik/main/autoinstall.sh)
```

OR

Run the single-line command below directly from your **Proxmox LXC** terminal Recomendation use Debian 13 (debian-13-standard_13.6-1_amd64.tar.zst) :

```bash
bash <(curl -s https://raw.githubusercontent.com/ginanjardwibasuki/elektrik/main/standalone.sh)
```
