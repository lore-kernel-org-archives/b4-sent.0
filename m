From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 21:41:46 +0300
Subject: [PATCH 2/2] Input: sx8654 - check SX8650 status read errors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-sx8650-fixes-v1-2-b82a881b971d@gmail.com>
References: <20261123-b4-sx8650-fixes-v1-0-b82a881b971d@gmail.com>
In-Reply-To: <20261123-b4-sx8650-fixes-v1-0-b82a881b971d@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459304; l=1341;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=j7j0QABqTYkyAI99G3MkmYNFWGfU+BRfuwxQGR7FYUQ=;
 b=hULECcoojitZP+pdrqNygybaX6ioV4cxlzfhmHcoFE2ypGfqmkKU23TUc6GA3WWApdVcX4F5r
 0tyqMowE55xD4j+hCYp50w3NPquNMPFb1GJUq4iGkAlkFNMBU9GXydX
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Keep the signed return value of i2c_smbus_read_byte_data and reject
errors before testing CONVIRQ. Truncating an errno to u8 can set the
conversion-pending bit; for example, -EIO becomes 0xfb and causes a
channel read and potentially a touch report after the failed status
read.

Fixes: 43df039c6d92 ("Input: sx8654 - add sx8650 support")

Cc: stable@vger.kernel.org

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/input/touchscreen/sx8654.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/input/touchscreen/sx8654.c b/drivers/input/touchscreen/sx8654.c
index 13dd80a8e..1ae00cc2a 100644
--- a/drivers/input/touchscreen/sx8654.c
+++ b/drivers/input/touchscreen/sx8654.c
@@ -130,8 +130,7 @@ static irqreturn_t sx8650_irq(int irq, void *handle)
 {
 	struct sx8654 *ts = handle;
 	struct device *dev = &ts->client->dev;
-	int len, i;
-	u8 stat;
+	int len, i, stat;
 	u16 x, y;
 	u16 ch;
 	u16 chdata;
@@ -142,6 +141,9 @@ static irqreturn_t sx8650_irq(int irq, void *handle)
 	stat = i2c_smbus_read_byte_data(ts->client, CMD_READ_REGISTER
 						    | I2C_REG_SX8650_STAT);
 
+	if (stat < 0)
+		return IRQ_HANDLED;
+
 	if (!(stat & SX8650_STAT_CONVIRQ)) {
 		dev_dbg(dev, "%s ignore stat [0x%02x]", __func__, stat);
 		return IRQ_HANDLED;

-- 
2.53.0

