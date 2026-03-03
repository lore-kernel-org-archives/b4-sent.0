From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 03 Mar 2026 18:49:25 +0100
Subject: [PATCH] wifi: rtl8xxxu: Mark RTL8188ETV (0bda:0179) as tested
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260303-rtl8xxx-tested-v1-1-291a38a6ff2f@posteo.net>
X-B4-Tracking: v=1; b=H4sIACQfp2kC/x2MQQqAIBAAvyJ7TihDs74SHTK3WogKV0II/550H
 IaZFxgDIcMgXgj4ENN1FmgqAcs+nxtK8oVB1UrXRmkZ4mFTSjIiR/Sy65u2KGuccVCiO+BK6R+
 OU84fjdymjGAAAAA=
X-Change-ID: 20250625-rtl8xxx-tested-791302586b6b
To: Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772560168; l=954;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=Y+HsudM93dZKBpUAqc5IIpt/+w920paNDH5/6c+0JkQ=;
 b=+wfBuV9IGxwlL7qY7wV4hknc0I39+Q6H1FNGDGouOs2tkdepviDwoUVA49LV33IFy2ss4fJwy
 ANJkj5bD2sFAnNShHC2RhLgBqppXCSwjXG16BxflWQ6P/vsCi3gIsI2
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This WiFi chip appears in the "TCU Fernsehfee 3.0" set-top box.
I have tested that it works in WPA2-PSK-CCMP client mode.

Cc: Jes.Sorensen@gmail.com
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 drivers/net/wireless/realtek/rtl8xxxu/core.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index 794187d28caa09..b4efc6f00a379a 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/core.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/core.c
@@ -7703,6 +7703,7 @@ static int rtl8xxxu_probe(struct usb_interface *interface,
 	switch (id->idVendor) {
 	case USB_VENDOR_ID_REALTEK:
 		switch(id->idProduct) {
+		case 0x0179:
 		case 0x1724:
 		case 0x8176:
 		case 0x8178:

---
base-commit: 11439c4635edd669ae435eec308f4ab8a0804808
change-id: 20250625-rtl8xxx-tested-791302586b6b

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

