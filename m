From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 21:41:45 +0300
Subject: [PATCH 1/2] Input: sx8654 - use the SX8650 soft-reset register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-sx8650-fixes-v1-1-b82a881b971d@gmail.com>
References: <20261123-b4-sx8650-fixes-v1-0-b82a881b971d@gmail.com>
In-Reply-To: <20261123-b4-sx8650-fixes-v1-0-b82a881b971d@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459304; l=2322;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=2R3B9Vs5B5D+UbWQT9UP0EYwUi/ItokvKyXPewI6m3M=;
 b=mjoXTxK2sHoiteAUKWFxkHss1JZ7mQmG8OvXuZ+YnsBcEiaCRfx4E/zood2zIEPYs9+nE6qpL
 h5h94A2lDyrCw1sq8f/U2GqWw++l75+vMUG5U4vtsISEPYpC7IiymU2
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SX8650 register map uses five address bits and places soft reset at
0x1f. Sending the SX8654 address 0x3f also changes the command bits, so
it does not reset an SX8650.

Select the soft-reset register from the chip data, retaining 0x3f for
the SX8654/SX8655/SX8656 variants. Hardware reset through NRST is
unchanged.

On Almond+, programming CTRL2 to 5 and writing 0xde to 0x3f leaves CTRL2
at 5. Writing 0xde to 0x1f restores its reset value of 0. Both I2C
writes acknowledge, so checking only the write return value misses the
failure.

Fixes: 43df039c6d92 ("Input: sx8654 - add sx8650 support")

Cc: stable@vger.kernel.org

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/input/touchscreen/sx8654.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/input/touchscreen/sx8654.c b/drivers/input/touchscreen/sx8654.c
index 23fb0c683..13dd80a8e 100644
--- a/drivers/input/touchscreen/sx8654.c
+++ b/drivers/input/touchscreen/sx8654.c
@@ -42,6 +42,7 @@
 #define I2C_REG_IRQMASK			0x22
 #define I2C_REG_IRQSRC			0x23
 #define I2C_REG_SOFTRESET		0x3f
+#define I2C_REG_SX8650_SOFTRESET		0x1f
 
 #define I2C_REG_SX8650_STAT		0x05
 #define SX8650_STAT_CONVIRQ		BIT(7)
@@ -86,6 +87,7 @@
 #define CH_Y				0x01
 
 struct sx865x_data {
+	u8 reg_softreset;
 	u8 cmd_manual;
 	u8 chan_mask;
 	bool has_irq_penrelease;
@@ -244,7 +246,8 @@ static int sx8654_reset(struct sx8654 *ts)
 		gpiod_set_value_cansleep(ts->gpio_reset, 0);
 	} else {
 		dev_dbg(&ts->client->dev, "NRST unavailable, try softreset\n");
-		err = i2c_smbus_write_byte_data(ts->client, I2C_REG_SOFTRESET,
+		err = i2c_smbus_write_byte_data(ts->client,
+						ts->data->reg_softreset,
 						SOFTRESET_VALUE);
 		if (err)
 			return err;
@@ -413,6 +416,7 @@ static int sx8654_probe(struct i2c_client *client)
 }
 
 static const struct sx865x_data sx8650_data = {
+	.reg_softreset		= I2C_REG_SX8650_SOFTRESET,
 	.cmd_manual		= 0xb0,
 	.has_irq_penrelease	= false,
 	.has_reg_irqmask	= false,
@@ -421,6 +425,7 @@ static const struct sx865x_data sx8650_data = {
 };
 
 static const struct sx865x_data sx8654_data = {
+	.reg_softreset		= I2C_REG_SOFTRESET,
 	.cmd_manual		= 0xc0,
 	.has_irq_penrelease	= true,
 	.has_reg_irqmask	= true,

-- 
2.53.0

