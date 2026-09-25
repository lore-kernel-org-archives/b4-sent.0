From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 25 Sep 2026 01:52:50 -0500
Subject: [PATCH v2] Bluetooth: btbcm: Add entry for BCM4356A3 UART
 bluetooth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-bcm4356a3-bt-v2-1-42098aca235b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XMSwrDIBSF4a2EO67FR6Kho+6jZGB8JBdqLBqkJ
 bj32sw7/A+c74DsEroMt+6A5ApmjFsLfunArHpbHEHbGjjlkiqmyGxCLwapBZl3YqwajaG+526
 Ednkl5/F9co+p9Yp5j+lz6oX91j9QYYQR7zW3AxdCSHpfgsbn1cQAU631C4lyC7aoAAAA
X-Change-ID: 20260717-bcm4356a3-bt-cd78cc0f42e8
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790319184; l=1578;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=AD/eIUQbbqFcpJLnIHNzJvShs6PAafOnSxMSfdwR5aY=;
 b=hvB9VnfWyCfk/orBFrRCxM7ya3Prs06AZUE6g+o4iJ9UT+/QQ5vydsb3zumvsc7KNQhCG/lEZ
 rlBMHG/mB3GBinuH8/l/nFTEppldRBTlQzdwUNHmNfR4xec4AvesYvt
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds the device ID for the bluetooth chip used in the
Nvidia specific Broadcom BCM4356 PCI-E WiFi / UART BT chip.

Startup log:

  Bluetooth: hci0: BCM: chip id 122
  Bluetooth: hci0: BCM: features 0x0f
  Bluetooth: hci0: BCM4356A3
  Bluetooth: hci0: BCM4356A3 (001.004.009) build 0000
  Bluetooth: hci0: BCM4356A3 'brcm/BCM4356A3.nvidia,p2894-2551-b00.hcd' Patch
  Bluetooth: hci0: BCM: features 0x0f
  Bluetooth: hci0: BCM4356A3 37.4MHz Class 1.5 Nvidia mDarcy-0108
  Bluetooth: hci0: BCM4356A3 (001.004.009) build 0109

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Add startup log to commit message
- Link to v1: https://lore.kernel.org/r/20260717-bcm4356a3-bt-v1-1-ffa2d5233360@gmail.com
---
 drivers/bluetooth/btbcm.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/bluetooth/btbcm.c b/drivers/bluetooth/btbcm.c
index 63c4c788d9c48..065536d4ec762 100644
--- a/drivers/bluetooth/btbcm.c
+++ b/drivers/bluetooth/btbcm.c
@@ -508,6 +508,7 @@ static const struct bcm_subver_table bcm_uart_subver_table[] = {
 	{ 0x6606, "BCM4345C5"	},	/* 003.006.006 */
 	{ 0x230f, "BCM4356A2"	},	/* 001.003.015 */
 	{ 0x2310, "BCM4343A2"	},	/* 001.003.016 */
+	{ 0x2409, "BCM4356A3"	},	/* 001.004.009 */
 	{ 0x220e, "BCM20702A1"  },	/* 001.002.014 */
 	{ 0x420d, "BCM4349B1"	},	/* 002.002.013 */
 	{ 0x420e, "BCM4349B1"	},	/* 002.002.014 */

---
base-commit: 4c253ac4b29b8c6cc6fdef8f92d4facde62e63b9
change-id: 20260717-bcm4356a3-bt-cd78cc0f42e8

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

