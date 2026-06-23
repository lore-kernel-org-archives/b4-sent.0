From: Roman Vivchar <rva333@protonmail.com>
Date: Wed, 24 Jun 2026 00:40:13 +0300
Subject: [PATCH] i2c: mediatek: fix WRRD for SoCs without auto_restart
 option
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260624-6572-6595-i2c-v1-1-9155cebaae20@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMyNjXTNTcyMgYWmqm2mUrGuWmmyZbJJqlgiESkA9BUWpaZkVYPOiYyH
 84tKkrNTkEpAhSrW1AIYrn0FxAAAA
X-Change-ID: 20260623-6572-6595-i2c-6ec9c4e6a6a6
To: Qii Wang <qii.wang@mediatek.com>, Andi Shyti <andi.shyti@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-i2c@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782250813; l=1767;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=TG2emG/PCj4Coy27v6ImKi08qxfg+rKakjADtWBifso=;
 b=MuDkLvPkgVRxiqfkdn6qowJfHL5BjKXog1KYCzBl6lSkA60ha518SEnL4W5DoJjBD4Idz6x8Z
 SUQMLDg76jfBE+L8FJc9UxV+vq91u4HSMSUjKXmtKe7KS9p2cwApUpi
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MediaTek mt65xx family SoCs have no auto restart, however, they still
support the WRRD mode in the hardware. Because auto_restart is set to 0,
the WRRD mode will be never enabled, leading to read errors.

Fix this by removing auto_restart check from the WRRD enable path.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
This is a preparation for the mt6572/6595 upstreaming.

mt65xx family SoCs don't have auto restart, but vendor kernels keep using
WRRD mode. Lack of the WRRD mode makes i2c reads impossible from both
userspace and kernel drivers.

Without patch (mt6595, da9210 buck at 0x68):
~ # i2cget -y 1 0x68 0x00
Error: Read failed
~ # i2cget -y 1 0x68 0x01
Error: Read failed

With patch:
~ # i2cget -y 1 0x68 0x00
0x80
~ # i2cget -y 1 0x68 0x01
0x00

Same behavior observed on mt6572 devices.

This change doesn't affect SoCs with auto restart option.
---
 drivers/i2c/busses/i2c-mt65xx.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/i2c/busses/i2c-mt65xx.c b/drivers/i2c/busses/i2c-mt65xx.c
index 126040ca05f1..307925fb78e3 100644
--- a/drivers/i2c/busses/i2c-mt65xx.c
+++ b/drivers/i2c/busses/i2c-mt65xx.c
@@ -1258,7 +1258,7 @@ static int mtk_i2c_transfer(struct i2c_adapter *adap,
 	i2c->auto_restart = i2c->dev_comp->auto_restart;
 
 	/* checking if we can skip restart and optimize using WRRD mode */
-	if (i2c->auto_restart && num == 2) {
+	if (num == 2) {
 		if (!(msgs[0].flags & I2C_M_RD) && (msgs[1].flags & I2C_M_RD) &&
 		    msgs[0].addr == msgs[1].addr) {
 			i2c->auto_restart = 0;

---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260623-6572-6595-i2c-6ec9c4e6a6a6

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

