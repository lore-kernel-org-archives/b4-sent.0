From: Yang Li <yang.li@amlogic.com>
Date: Tue, 10 Nov 2026 17:05:22 +0800
Subject: [PATCH] amlogic: Update w155s2 firmware to version 6b.10
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-upgrade_w155s2_bin-v1-1-4533ba6005cd@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAFHe8moC/x3MTQqAIBBA4avErBMcyYKuEhFqU83GYqQfkO6et
 PwW72VIJEwJ+iqD0MWJ91iAdQVhc3ElxXMxGG1aRNTqPFZxM003WpvM5DkqMkG3zndNWCyU8BB
 a+Pmnw/i+H+qq6/5kAAAA
To: linux-firmware@kernel.org
Cc: bluez-devel@lists.bluez.org, Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794301531; l=1127;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=4MadsrxCz7u2kuThDp1gRCH+zvOW7t7Vn6MZBQWV2wY=;
 b=C74V5cmQmGTQ81F3QAxcNE5VwdDUghsmI8eaIO8Tk8Chqq9/hk4et3HoOtjX6awzwYUaG0RV8
 8S08+vi4pD6AEV9bIgMGricfoom8nSe+rDxXxdyOpBgAZCyzdNG+usi
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Release notes:
- Allow cases where BD address is not burned into
  eFuse (no longer restricted).
- Mark secure connection as unsupported.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 WHENCE                         |   4 ++--
 amlogic/aml_w155s2_bt_uart.bin | Bin 393224 -> 393224 bytes
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/WHENCE b/WHENCE
index 27de996d..2101bbae 100644
--- a/WHENCE
+++ b/WHENCE
@@ -10733,8 +10733,8 @@ Originates from https://github.com/nxp-imx/imx-firmware/tree/lf-6.1.22_2.0.0/nxp
 
 Driver: amlogic - Amlogic SoC Firmware
 File: amlogic/aml_w155s2_bt_uart.bin
-Version: 42.23
-Info: 0x2de8
+Version: 6b.10
+Info: 0x6789
 
 File: amlogic/aml_w265s1_bt_uart.bin
 Version: 43.13
diff --git a/amlogic/aml_w155s2_bt_uart.bin b/amlogic/aml_w155s2_bt_uart.bin
index 02f1fe3f..5ffcd15f 100644
Binary files a/amlogic/aml_w155s2_bt_uart.bin and b/amlogic/aml_w155s2_bt_uart.bin differ

---
base-commit: a42217fc9c813dfc2e0254f0ac21ff6034098a79
change-id: 20261110-upgrade_w155s2_bin-e2c06ab74cf5

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

