From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v2 0/3] mmc: hi6220-dwmmc: handle resets and clocks
Date: Thu, 01 Feb 2024 22:05:41 +0800
Message-Id: <20240201-mmc-v2-0-9f09dc1335fd@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADWlu2UC/1WMQQ7CIBBFr9LMWgwgrcGV9zBdtONgJ0oxUImm4
 e5idy7fz39vhUSRKcGpWSFS5sRhrqB3DeA0zDcSfK0MWmojlbLCexQW3dEdTNviaKA+n5Ecv7f
 Kpa88cVpC/GzRrH7rv5+VUGIg6kaNrrNSn8NreYRw32Pw0JdSvrej8EeYAAAA
To: Peng Fan <peng.fan@nxp.com>, Jaehoon Chung <jh80.chung@samsung.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706796342; l=893;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=qoO1GWUwglkouL30KLVHZpQKTUw3WzxauJY+ZHGAzaU=;
 b=dOufC9sn2B03Ug7hXCoPaP0mz906uzVmCPGsmToWPXgXbHB0pj30R/78iZdwBgRcEw8bnmwq0
 f79IaQDY2cZBd0t7TMDUZPfmB1RwCRXTkZtMUYDFaLMjto+4ug32/FR
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Also allow setup fifoth_val in driver

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v2:
- dw-mmc: proceed if data busy found
- hi6220-dw-mmc: add fifoth_val setup, separate hi3798mv200 data
- Link to v1: https://lore.kernel.org/r/20240119-mmc-v1-1-aee6b2cf6902@outlook.com

---
Yang Xiwen (3):
      mmc: hi6220-dwmmc: handle clocks and resets if CONFIG_CLK and CONFIG_DM_RESET enabled
      mmc: dw_mmc: Don't return error if data busy timeout
      mmc: hi6220_dw_mmc: add fifoth_val to private data and set it in .probe

 drivers/mmc/dw_mmc.c        |  4 +--
 drivers/mmc/hi6220_dw_mmc.c | 72 +++++++++++++++++++++++++++++++++++++++++++--
 2 files changed, 72 insertions(+), 4 deletions(-)
---
base-commit: f7cca7ccc5117eaafcc2bde91ad1bed6fee7cfc3
change-id: 20240119-mmc-9cf7f3455cb4

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

