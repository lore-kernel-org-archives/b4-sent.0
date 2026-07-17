From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 17 Jul 2026 16:40:52 -0500
Subject: [PATCH] Bluetooth: btbcm: Add entry for BCM4356A3 UART bluetooth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-bcm4356a3-bt-v1-1-ffa2d5233360@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDc0Nz3aTkXBNjU7NEY92kEt3kFHOL5GSDNBOjVAsloJaCotS0zAqwcdG
 xtbUAdlmMQ14AAAA=
X-Change-ID: 20260717-bcm4356a3-bt-cd78cc0f42e8
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784324467; l=1010;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=bQ6WFjUIqP2rPELTYAWoRuAn5MAUJ18Jq8ZRipAGP0w=;
 b=EaKI+21I/MInPDJoJM2xSBNHH120R+oL6EOtq3kiw4DSt5n2L23U6dINaPR/HLzooQOSUMauH
 pPKh+txgygWBGOyK/KeNrHsLKC3Oq9UIRL/zjbDeCuIslWXR/Z32DUK
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds the device ID for the bluetooth chip used in the
Nvidia specific Broadcom BCM4356 PCI-E WiFi / UART BT chip.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/bluetooth/btbcm.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/bluetooth/btbcm.c b/drivers/bluetooth/btbcm.c
index 463d59890befe..14acea7325478 100644
--- a/drivers/bluetooth/btbcm.c
+++ b/drivers/bluetooth/btbcm.c
@@ -506,6 +506,7 @@ static const struct bcm_subver_table bcm_uart_subver_table[] = {
 	{ 0x6606, "BCM4345C5"	},	/* 003.006.006 */
 	{ 0x230f, "BCM4356A2"	},	/* 001.003.015 */
 	{ 0x2310, "BCM4343A2"	},	/* 001.003.016 */
+	{ 0x2409, "BCM4356A3"	},	/* 001.004.009 */
 	{ 0x220e, "BCM20702A1"  },	/* 001.002.014 */
 	{ 0x420d, "BCM4349B1"	},	/* 002.002.013 */
 	{ 0x420e, "BCM4349B1"	},	/* 002.002.014 */

---
base-commit: 49362394dad7df66c274c867a271394c10ca2bb8
change-id: 20260717-bcm4356a3-bt-cd78cc0f42e8

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

