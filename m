From: Vincent Jardin <vjardin@free.fr>
Date: Wed, 12 Aug 2026 21:16:05 +0200
Subject: [PATCH v2] i2c: imx: add I2C_M_REV_DIR_ADDR and I2C_M_NOSTART
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-for-upstream-i2c-imx-lx2160-reverse-v2-1-f1343714c5a9@free.fr>
X-B4-Tracking: v=1; b=H4sIAHTGfGoC/5WNSw6CMBBAr0Jm7Zi20VJccQ/DAupUJpFPpkgwp
 He3cgOX7y3e2yGSMEW4FTsIrRx5GjOYUwG+b8cnIT8yg1HGKqdKDJPge46LUDsgG488bPjajLY
 Kc4AkEpZtdemqq9XaOcilWSjwdlzuTeae4zLJ55iu+mf/668aNQZTWk/Od9aqOgjROQg0KaUvt
 JtifNQAAAA=
To: Oleksij Rempel <o.rempel@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Andi Shyti <andi.shyti@kernel.org>, Frank Li <Frank.Li@nxp.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, Fabio Estevam <festevam@gmail.com>
Cc: linux-i2c@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786562171; l=10750;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=FpCrX4lwAPTSqYANmveCLwNTw7LbAWMK39UMM8ZpFjM=;
 b=d9BrWXfGUbEbRbxkwNLachmppbCdcpjE/h9wqbXbfvdVGW1hk8f/9g+XcFzGJVAzpFfqur2Et
 5L2BeMsIwB6Bwj0a5wPsnSAEpJH1GJLqBQPSq5hmXimpaCKUylTtsRx
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Realtek RTL8366SE SMI read frame per:

  S Addr Rd [A] reg[7:0] [A] reg[15:8] [A] [data[7:0]] A [data[15:8]] NA P

Linux support it using I2C_M_REV_DIR_ADDR on a write message
that inverts the transmitted R/W bit, and I2C_M_NOSTART on the following
read message that continues the frame without re-addressing.

This NXP i2c-imx is missing such support, so on an LX2160A the Realtek switch
could not be used.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Follow the logics from i2c-algo-bit and i2c-s3c2410 (addr ^= 1).

Documentation/i2c/i2c-protocol.rst says I2C_M_NOSTART "may also be used
between direction changes by some rare devices"; the RTL8366SE is one of
such device !

- The NOSTART read turns the bus around without waiting for a completion,
  because the controller stretches SCL after the previous byte and the
  frame is therefore still open. That is what lets i2c_imx_read() enter
  the state the ISR would otherwise have moved to.

- I2C_FUNC_PROTOCOL_MANGLING also covers I2C_M_IGNORE_NAK,
  I2C_M_NO_RD_ACK and I2C_M_STOP, which this driver does not implement.
  They are rejected with -EOPNOTSUPP rather than advertised and silently
  ignored. I2C_M_NOSTART on the first message is rejected as well.
---
Changes in v2:
- message validation with i2c_imx_check_msgs() (Carlos Song)
  No functional change
- Link to v1: https://lore.kernel.org/r/20260807-for-upstream-i2c-imx-lx2160-reverse-v1-1-f276ce8cb660@free.fr
---
 drivers/i2c/busses/i2c-imx.c | 153 ++++++++++++++++++++++++++++++++-----------
 1 file changed, 113 insertions(+), 40 deletions(-)

diff --git a/drivers/i2c/busses/i2c-imx.c b/drivers/i2c/busses/i2c-imx.c
index 9477d814fde9..7dc9c43673ee 100644
--- a/drivers/i2c/busses/i2c-imx.c
+++ b/drivers/i2c/busses/i2c-imx.c
@@ -1000,16 +1000,10 @@ static inline int i2c_imx_isr_write(struct imx_i2c_struct *i2c_imx)
 	return 1;
 }
 
-static inline int i2c_imx_isr_read(struct imx_i2c_struct *i2c_imx)
+static inline void i2c_imx_setup_read(struct imx_i2c_struct *i2c_imx)
 {
-	int result;
 	unsigned int temp;
 
-	result = i2c_imx_isr_acked(i2c_imx);
-	if (result)
-		return result;
-
-	/* setup bus to read data */
 	temp = imx_i2c_read_reg(i2c_imx, IMX_I2C_I2CR);
 	temp &= ~I2CR_MTX;
 	if ((i2c_imx->msg->len - 1) || (i2c_imx->msg->flags & I2C_M_RECV_LEN))
@@ -1017,6 +1011,18 @@ static inline int i2c_imx_isr_read(struct imx_i2c_struct *i2c_imx)
 
 	imx_i2c_write_reg(temp, i2c_imx, IMX_I2C_I2CR);
 	imx_i2c_read_reg(i2c_imx, IMX_I2C_I2DR); /* dummy read */
+}
+
+static inline int i2c_imx_isr_read(struct imx_i2c_struct *i2c_imx)
+{
+	int result;
+
+	result = i2c_imx_isr_acked(i2c_imx);
+	if (result)
+		return result;
+
+	/* setup bus to read data */
+	i2c_imx_setup_read(i2c_imx);
 
 	return 0;
 }
@@ -1172,6 +1178,16 @@ static irqreturn_t i2c_imx_isr(int irq, void *dev_id)
 	return i2c_imx_master_isr(i2c_imx, status);
 }
 
+static u8 i2c_imx_addr_byte(struct i2c_msg *msg)
+{
+	u8 addr = i2c_8bit_addr_from_msg(msg);
+
+	if (msg->flags & I2C_M_REV_DIR_ADDR)
+		addr ^= 1;
+
+	return addr;
+}
+
 static int i2c_imx_dma_write(struct imx_i2c_struct *i2c_imx,
 					struct i2c_msg *msgs)
 {
@@ -1200,7 +1216,7 @@ static int i2c_imx_dma_write(struct imx_i2c_struct *i2c_imx,
 	 * Write slave address.
 	 * The first byte must be transmitted by the CPU.
 	 */
-	imx_i2c_write_reg(i2c_8bit_addr_from_msg(msgs), i2c_imx, IMX_I2C_I2DR);
+	imx_i2c_write_reg(i2c_imx_addr_byte(msgs), i2c_imx, IMX_I2C_I2DR);
 	time_left = wait_for_completion_timeout(
 				&i2c_imx->dma->cmd_complete,
 				msecs_to_jiffies(DMA_TIMEOUT));
@@ -1242,14 +1258,20 @@ static int i2c_imx_prepare_read(struct imx_i2c_struct *i2c_imx,
 	int result;
 	unsigned int temp = 0;
 
-	/* write slave address */
-	imx_i2c_write_reg(i2c_8bit_addr_from_msg(msgs), i2c_imx, IMX_I2C_I2DR);
-	result = i2c_imx_trx_complete(i2c_imx, !use_dma);
-	if (result)
-		return result;
-	result = i2c_imx_acked(i2c_imx);
-	if (result)
-		return result;
+	/*
+	 * I2C_M_NOSTART continues a frame that is already open, so there is
+	 * no address phase: go straight to turning the bus around.
+	 */
+	if (!(msgs->flags & I2C_M_NOSTART)) {
+		/* write slave address */
+		imx_i2c_write_reg(i2c_imx_addr_byte(msgs), i2c_imx, IMX_I2C_I2DR);
+		result = i2c_imx_trx_complete(i2c_imx, !use_dma);
+		if (result)
+			return result;
+		result = i2c_imx_acked(i2c_imx);
+		if (result)
+			return result;
+	}
 
 	dev_dbg(&i2c_imx->adapter.dev, "<%s> setup bus\n", __func__);
 
@@ -1371,16 +1393,18 @@ static int i2c_imx_atomic_write(struct imx_i2c_struct *i2c_imx,
 	int i, result;
 
 	dev_dbg(&i2c_imx->adapter.dev, "<%s> write slave address: addr=0x%x\n",
-		__func__, i2c_8bit_addr_from_msg(msgs));
+		__func__, i2c_imx_addr_byte(msgs));
 
-	/* write slave address */
-	imx_i2c_write_reg(i2c_8bit_addr_from_msg(msgs), i2c_imx, IMX_I2C_I2DR);
-	result = i2c_imx_trx_complete(i2c_imx, true);
-	if (result)
-		return result;
-	result = i2c_imx_acked(i2c_imx);
-	if (result)
-		return result;
+	if (!(msgs->flags & I2C_M_NOSTART)) {
+		/* write slave address */
+		imx_i2c_write_reg(i2c_imx_addr_byte(msgs), i2c_imx, IMX_I2C_I2DR);
+		result = i2c_imx_trx_complete(i2c_imx, true);
+		if (result)
+			return result;
+		result = i2c_imx_acked(i2c_imx);
+		if (result)
+			return result;
+	}
 	dev_dbg(&i2c_imx->adapter.dev, "<%s> write data\n", __func__);
 
 	/* write data */
@@ -1402,7 +1426,7 @@ static int i2c_imx_atomic_write(struct imx_i2c_struct *i2c_imx,
 static int i2c_imx_write(struct imx_i2c_struct *i2c_imx, struct i2c_msg *msgs)
 {
 	dev_dbg(&i2c_imx->adapter.dev, "<%s> write slave address: addr=0x%x\n",
-		__func__, i2c_8bit_addr_from_msg(msgs));
+		__func__, i2c_imx_addr_byte(msgs));
 
 	i2c_imx->state = IMX_I2C_STATE_WRITE;
 	i2c_imx->msg = msgs;
@@ -1411,8 +1435,16 @@ static int i2c_imx_write(struct imx_i2c_struct *i2c_imx, struct i2c_msg *msgs)
 	/*
 	 * By writing the device address we start the state machine in the ISR.
 	 * The ISR will report when it is done or when it fails.
+	 *
+	 * I2C_M_NOSTART continues a frame that is already open and so has no
+	 * address byte: push the first data byte instead. That raises the same
+	 * interrupt and the ISR carries on from the second byte.
 	 */
-	imx_i2c_write_reg(i2c_8bit_addr_from_msg(msgs), i2c_imx, IMX_I2C_I2DR);
+	if (msgs->flags & I2C_M_NOSTART)
+		imx_i2c_write_reg(msgs->buf[i2c_imx->msg_buf_idx++], i2c_imx,
+				  IMX_I2C_I2DR);
+	else
+		imx_i2c_write_reg(i2c_imx_addr_byte(msgs), i2c_imx, IMX_I2C_I2DR);
 	wait_event_timeout(i2c_imx->queue,
 			   i2c_imx->state == IMX_I2C_STATE_DONE ||
 			   i2c_imx->state == IMX_I2C_STATE_FAILED,
@@ -1529,22 +1561,29 @@ static int i2c_imx_read(struct imx_i2c_struct *i2c_imx, struct i2c_msg *msgs,
 
 	dev_dbg(&i2c_imx->adapter.dev,
 		"<%s> write slave address: addr=0x%x\n",
-		__func__, i2c_8bit_addr_from_msg(msgs));
+		__func__, i2c_imx_addr_byte(msgs));
 
 	i2c_imx->is_lastmsg = is_lastmsg;
 
-	if (block_data)
-		i2c_imx->state = IMX_I2C_STATE_READ_BLOCK_DATA;
-	else
-		i2c_imx->state = IMX_I2C_STATE_READ;
 	i2c_imx->msg = msgs;
 	i2c_imx->msg_buf_idx = 0;
 
-	/*
-	 * By writing the device address we start the state machine in the ISR.
-	 * The ISR will report when it is done or when it fails.
-	 */
-	imx_i2c_write_reg(i2c_8bit_addr_from_msg(msgs), i2c_imx, IMX_I2C_I2DR);
+	if (msgs->flags & I2C_M_NOSTART) {
+		i2c_imx->state = block_data ? IMX_I2C_STATE_READ_BLOCK_DATA_LEN
+					    : IMX_I2C_STATE_READ_CONTINUE;
+		i2c_imx_setup_read(i2c_imx);
+	} else {
+		if (block_data)
+			i2c_imx->state = IMX_I2C_STATE_READ_BLOCK_DATA;
+		else
+			i2c_imx->state = IMX_I2C_STATE_READ;
+
+		/*
+		 * By writing the device address we start the state machine in the ISR.
+		 * The ISR will report when it is done or when it fails.
+		 */
+		imx_i2c_write_reg(i2c_imx_addr_byte(msgs), i2c_imx, IMX_I2C_I2DR);
+	}
 	wait_event_timeout(i2c_imx->queue,
 			   i2c_imx->state == IMX_I2C_STATE_DONE ||
 			   i2c_imx->state == IMX_I2C_STATE_FAILED,
@@ -1574,6 +1613,33 @@ static int i2c_imx_read(struct imx_i2c_struct *i2c_imx, struct i2c_msg *msgs,
 	return ret;
 }
 
+#define I2C_IMX_UNSUPPORTED_PROTOCOL_MANGLING_FLAGS \
+	(I2C_M_IGNORE_NAK | I2C_M_NO_RD_ACK | I2C_M_STOP)
+
+static int i2c_imx_check_msgs(struct i2c_msg *msgs, int num)
+{
+	int i;
+
+	for (i = 0; i < num; i++) {
+		/* Reject rather than silently transfer */
+		if (msgs[i].flags & I2C_IMX_UNSUPPORTED_PROTOCOL_MANGLING_FLAGS)
+			return -EOPNOTSUPP;
+
+		if (msgs[i].flags & I2C_M_NOSTART) {
+			/*
+			 * NOSTART continues an already open frame. The first
+			 * message has nothing to continue from,
+			 * a 0 length continuation leaves the controller with
+			 * no byte to clock.
+			 */
+			if (i == 0 || msgs[i].len == 0)
+				return -EOPNOTSUPP;
+		}
+	}
+
+	return 0;
+}
+
 static int i2c_imx_xfer_common(struct i2c_adapter *adapter,
 			       struct i2c_msg *msgs, int num, bool atomic)
 {
@@ -1583,6 +1649,10 @@ static int i2c_imx_xfer_common(struct i2c_adapter *adapter,
 	struct imx_i2c_struct *i2c_imx = i2c_get_adapdata(adapter);
 	int use_dma = 0;
 
+	result = i2c_imx_check_msgs(msgs, num);
+	if (result)
+		return result;
+
 	/* Start I2C transfer */
 	result = i2c_imx_start(i2c_imx, atomic);
 	if (result) {
@@ -1604,7 +1674,7 @@ static int i2c_imx_xfer_common(struct i2c_adapter *adapter,
 		if (i == num - 1)
 			is_lastmsg = true;
 
-		if (i) {
+		if (i && !(msgs[i].flags & I2C_M_NOSTART)) {
 			dev_dbg(&i2c_imx->adapter.dev,
 				"<%s> repeated start\n", __func__);
 			temp = imx_i2c_read_reg(i2c_imx, IMX_I2C_I2CR);
@@ -1636,7 +1706,8 @@ static int i2c_imx_xfer_common(struct i2c_adapter *adapter,
 #endif
 
 		use_dma = i2c_imx->dma && msgs[i].len >= DMA_THRESHOLD &&
-			msgs[i].flags & I2C_M_DMA_SAFE;
+			msgs[i].flags & I2C_M_DMA_SAFE &&
+			!(msgs[i].flags & I2C_M_NOSTART);
 		if (msgs[i].flags & I2C_M_RD) {
 			int block_data = msgs->flags & I2C_M_RECV_LEN;
 
@@ -1730,7 +1801,9 @@ static int i2c_imx_init_recovery_info(struct imx_i2c_struct *i2c_imx,
 static u32 i2c_imx_func(struct i2c_adapter *adapter)
 {
 	return I2C_FUNC_I2C | I2C_FUNC_SMBUS_EMUL
-		| I2C_FUNC_SMBUS_READ_BLOCK_DATA;
+		| I2C_FUNC_SMBUS_READ_BLOCK_DATA
+		| I2C_FUNC_NOSTART
+		| I2C_FUNC_PROTOCOL_MANGLING;
 }
 
 static const struct i2c_algorithm i2c_imx_algo = {

---
base-commit: 3d6d817622b0a9721e3cc404df3469171582be13
change-id: 20260807-for-upstream-i2c-imx-lx2160-reverse-7a94b9561188

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

