From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH v2 0/3] scripts: imx: imx-usb-loader: fix mingw compilation
Date: Mon, 01 Dec 2025 11:26:15 +0100
Message-Id: <20251201-imx_usb-v2-0-95ec2a0e8694@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEdtLWkC/2XMQQrCMBCF4auUWRtJoqnBlfeQIp04tgNtU5IaK
 iV3N3br8n88vg0iBaYI12qDQIkj+6mEPlTg+nbqSPCzNGipjVLaCh7XxzuiOCuJiOZCsrZQ3nO
 gF6+7dG9K9xwXHz47nNRv/TeSElIg1q1RVuLJ0q3zzk9L8MNwdH6EJuf8BXtkyQ6jAAAA
X-Change-ID: 20251128-imx_usb-410bbb57e068
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764584777; l=902;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=F8ktlJonnEn8cfMgL8uqYJDCvD+zs0ubs3EcbflE3GU=;
 b=qc2J6672L0jI5mCqLkhSCvsPKS5KEuCnesql8IDk9s2bfKmRDwmsowE6pbGO/J1WVlGEkkopY
 wfYrdLezY8bCSgYXA1T0F9K76918uTZ3gd4UwmA1gspfGBc4f94AZd6
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Compiling imx-usb-loader for windows targets had become broken, fix it.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
Changes in v2:
- Extract the mingw pread implementation to a seperate file that only
  gets used when mingw is the target.
- Link to v1: https://lore.kernel.org/r/20251128-imx_usb-v1-0-bb6a5180b38e@gocontroll.com

---
Maud Spierings (3):
      scripts: imx: Makefile.mingw64: add _GNU_SOURCE
      scripts: imx: add pread implementation for mingw target
      gitignore: ignore *.exe

 .gitignore                   |  1 +
 scripts/imx/Makefile.mingw64 |  4 ++--
 scripts/imx/pread.c          | 25 +++++++++++++++++++++++++
 3 files changed, 28 insertions(+), 2 deletions(-)
---
base-commit: 3e01efb6c6527ca72a1213000006be1902db7be9
change-id: 20251128-imx_usb-410bbb57e068

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

