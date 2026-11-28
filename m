From: Felix Huang <akafelixab@gmail.com>
Date: Fri, 27 Nov 2026 21:33:46 -0500
Subject: [PATCH] i2c: diolan-u2c: use get_unaligned_le32() in
 diolan_get_serial()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-i2c-diolan-u2c-unaligned-v1-1-0c3621b7690d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMBCE4Vcpe3bBLFQbX0U8xGSsK2UriRGh9
 N0b9TbfYf6FCrKi0KlbKOOtRWdrcLuO4j3YCNbUTLKXg3NyZJXISecpGNc2q4VJR0Ni6b1HwjA
 EL9Tuz4ybfn7p8+XvUq8PxNe3R+u6AaUcgCx8AAAA
X-Change-ID: 20261127-i2c-diolan-u2c-unaligned-2599ede88a92
To: Guenter Roeck <linux@roeck-us.net>, Andi Shyti <andi.shyti@kernel.org>
Cc: linux-i2c@vger.kernel.org, Felix Huang <akafelixab@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795833227; l=1508;
 i=akafelixab@gmail.com; s=20261128; h=from:subject:message-id;
 bh=tWaQaBt3Y5jwyqbvYJKTgjkG1O2HuHP5e0f9pq+Ozgc=;
 b=O8fJvZE3M4Sj/iA8XY8eQleLHc/CraYpTj0bJDqUhBcvFDFMPKsXvr/HMA1O5QORNqsdKQpTO
 6w0H9ht2BijAC5iBFlpinuux7hBE6OEw7eiBpjkpljKFJ7vJEBhM3LV
X-Developer-Key: i=akafelixab@gmail.com; a=ed25519;
 pk=Axl3BM1UWa+m0/AWcEhRIdIk/WY9FnY4wZkyQn64uVY=
X-Endpoint-Received: by B4 Relay for akafelixab@gmail.com/20261128 with auth_id=1670
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following sparse warning by replacing le32_to_cpu(*(u32 *)...)
with get_unaligned_le32():

  drivers/i2c/busses/i2c-diolan-u2c.c:290:26: warning: cast to restricted __le32

This preserves the exact little-endian conversion semantics while also
avoiding potential unaligned memory access on dev->ibuffer.

Signed-off-by: Felix Huang <akafelixab@gmail.com>
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

