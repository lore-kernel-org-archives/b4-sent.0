From: Felix Huang <akafelixab@gmail.com>
Date: Sat, 28 Nov 2026 02:06:39 -0500
Subject: [PATCH v2] i2c: diolan-u2c: Use get_unaligned_le32() to read
 serial number
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-i2c-diolan-u2c-unaligned-v2-1-c6028a74f24f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NQQ6CMBBFr0K6dgwdI1BX3sOwKO0IY6AlLRAN4
 e4WvIC7/5L//1tFpMAUxS1bRaCFI3uXAE+ZMJ12LQHbxAJzLKTEEhgNWPa9djCnODvdc+vIAl6
 VIktVpRWKNB8DPfl9XD/qH8e5eZGZ9r+90XGcfPgc7kXuvT80iwQJubkUKJuyULm9t4Pm/mz8I
 Opt277Acooi0gAAAA==
X-Change-ID: 20261127-i2c-diolan-u2c-unaligned-2599ede88a92
To: Guenter Roeck <linux@roeck-us.net>, Andi Shyti <andi.shyti@kernel.org>
Cc: linux-i2c@vger.kernel.org, Felix Huang <akafelixab@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795849600; l=1942;
 i=akafelixab@gmail.com; s=20261128; h=from:subject:message-id;
 bh=n00xqsAnw9+08teHGoItt6A75VThG+EK+ZptSH56EsQ=;
 b=rCspYky+MS46n/nURjB5MDUA/m02OpYbVjAv92czm7Brx4kmw14mbTWQG1w1IAwe1HjvX92Ve
 5r4nThnujT6A6dFWCKRrYLTSIX/cnxz8whsIkvTJwcOjRfli1+3lr37
X-Developer-Key: i=akafelixab@gmail.com; a=ed25519;
 pk=Axl3BM1UWa+m0/AWcEhRIdIk/WY9FnY4wZkyQn64uVY=
X-Endpoint-Received: by B4 Relay for akafelixab@gmail.com/20261128 with auth_id=1670
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sparse reports:

  drivers/i2c/busses/i2c-diolan-u2c.c:290:26: warning:
  cast to restricted __le32

Replace the explicit cast and le32_to_cpu() conversion with
get_unaligned_le32(). This preserves the existing conversion semantics
and silences the sparse warning.

Signed-off-by: Felix Huang <akafelixab@gmail.com>
---
Changes in v2:
- Reword the commit message to accurately describe the motivation.
- Do not claim that the existing access may be unaligned; the
  serial-number buffer is naturally aligned.
- Focus on fixing the sparse "cast to restricted __le32" warning.
- Link to v1: https://patch.msgid.link/20261127-i2c-diolan-u2c-unaligned-v1-1-0c3621b7690d@gmail.com

To: Guenter Roeck <linux@roeck-us.net>
To: Andi Shyti <andi.shyti@kernel.org>
Cc: linux-i2c@vger.kernel.org
---
 drivers/i2c/busses/i2c-diolan-u2c.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/i2c/busses/i2c-diolan-u2c.c b/drivers/i2c/busses/i2c-diolan-u2c.c
index d502f6e47..24db6d26c 100644
--- a/drivers/i2c/busses/i2c-diolan-u2c.c
+++ b/drivers/i2c/busses/i2c-diolan-u2c.c
@@ -16,6 +16,7 @@
 #include <linux/slab.h>
 #include <linux/usb.h>
 #include <linux/i2c.h>
+#include <linux/unaligned.h>
 
 #define DRIVER_NAME		"i2c-diolan-u2c"
 
@@ -283,13 +284,12 @@ static void diolan_fw_version(struct i2c_diolan_u2c *dev)
 static void diolan_get_serial(struct i2c_diolan_u2c *dev)
 {
 	int ret;
-	u32 serial;
 
 	ret = diolan_usb_cmd(dev, CMD_GET_SERIAL, true);
 	if (ret >= 4) {
-		serial = le32_to_cpu(*(u32 *)dev->ibuffer);
 		dev_info(&dev->interface->dev,
-			 "Diolan U2C serial number %u\n", serial);
+			 "Diolan U2C serial number %u\n",
+			 get_unaligned_le32(dev->ibuffer));
 	}
 }
 

---
base-commit: f4585067150b85e33f60876149a6e742928da75e
change-id: 20261127-i2c-diolan-u2c-unaligned-2599ede88a92

Best regards,
--  
Felix Huang <akafelixab@gmail.com>

