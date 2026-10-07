From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 07 Oct 2026 18:31:53 +0800
Subject: [PATCH v2 2/2] media: i2c: it6625: allow 250 ms for host control
 requests to complete
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261007-upstream-it6625-reset-delay-v2-2-c5d6b2522bbe@ite.com.tw>
References: <20261007-upstream-it6625-reset-delay-v2-0-c5d6b2522bbe@ite.com.tw>
In-Reply-To: <20261007-upstream-it6625-reset-delay-v2-0-c5d6b2522bbe@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791369112; l=3513;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=6uZOr3QVwYGOfofYdEgdRcxELwJIKpUkYV2QbBd6d48=;
 b=bqKrhecQLEwwIE6XQiugP6/gPcnbzw9SsE73/P2ecneCcgotJEhTtBBdD9BKkeQQxYbz/Evic
 a6HwHrCHEksABpg9+LWPRYNtdR+DV6qrLeHbKW36+Cla0hCseP/Gw+l
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Host requests to the on-chip MCU (commands, config updates, info-block
bank switches, CEC transmits) are acknowledged by the MCU clearing
REG_HOST_CTRL_INT. While the MCU is busy handling the HDMI input, this
can take up to 150 ms, but the driver only polls for 25 ms. The request
then times out even though the MCU completes it shortly after, and the
caller fails or continues with stale state.

Raise the timeout for all host control requests to 250 ms, which
covers the worst case with some margin, using a single named constant
instead of the open-coded value.

Fixes: 142e5f00bd57 ("media: i2c: add driver for ITE IT6625/IT6626")
Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 20 +++++++++++++++-----
 1 file changed, 15 insertions(+), 5 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index fc8b22cc1c9ba3612f9c55bea1de61fa9a9c0e84..58d58d40035547e85a7f868777b57276a90a9d93 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -212,6 +212,11 @@ MODULE_PARM_DESC(debug, "debug level (0-3)");
 #define B_CEC_SEND_DATA BIT(5)
 #define B_CONFIG_UPDATE BIT(6)
 #define B_IF_BANK BIT(7)
+/*
+ * The MCU can take up to 150 ms to clear REG_HOST_CTRL_INT while it is
+ * busy handling the HDMI input; allow 250 ms to leave some margin.
+ */
+#define IT6625_HOST_CTRL_TIMEOUT_MS 250
 
 #define REG_MCU_INTERRUPT 0xFF
 #define B_SYS_INT_ACTIVE BIT(0)
@@ -530,7 +535,8 @@ static void it6625_write_command(struct it6625 *it6625, u8 *cmds, int cmd_len)
 {
 	it6625_write_bytes(it6625, REG_CMD_SET, cmds, cmd_len);
 	it6625_write_byte(it6625, REG_HOST_CTRL_INT, B_CMD_SET);
-	it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00, 25);
+	it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00,
+			       IT6625_HOST_CTRL_TIMEOUT_MS);
 }
 
 static int it6625_update_config(struct it6625 *it6625)
@@ -542,7 +548,8 @@ static int it6625_update_config(struct it6625 *it6625)
 	if (err < 0)
 		return err;
 
-	return it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00, 25);
+	return it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00,
+				      IT6625_HOST_CTRL_TIMEOUT_MS);
 }
 
 static int it6625_set_bank(struct it6625 *it6625, u8 bank)
@@ -557,7 +564,8 @@ static int it6625_set_bank(struct it6625 *it6625, u8 bank)
 	if (err < 0)
 		return err;
 
-	return it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00, 25);
+	return it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00,
+				      IT6625_HOST_CTRL_TIMEOUT_MS);
 }
 
 static inline bool is_hdmi(struct it6625 *it6625)
@@ -1027,7 +1035,8 @@ static int it6625_initial_setup(struct it6625 *it6625)
 	if (err)
 		return err;
 
-	return it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00, 25);
+	return it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00,
+				      IT6625_HOST_CTRL_TIMEOUT_MS);
 }
 
 static int it6625_cec_adap_enable(struct cec_adapter *adap, bool enable)
@@ -1084,7 +1093,8 @@ static int it6625_cec_adap_transmit(struct cec_adapter *adap, u8 attempts,
 	it6625_write_bytes(it6625, REG_CEC_TX_DATA, msg->msg, msg->len);
 	it6625_write_byte(it6625, REG_CEC_TX_DATA_LEN, msg->len);
 	it6625_set_bits(it6625, REG_HOST_CTRL_INT, B_CEC_SEND_DATA, B_CEC_SEND_DATA);
-	it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00, 25);
+	it6625_wait_for_status(it6625, REG_HOST_CTRL_INT, 0x00,
+			       IT6625_HOST_CTRL_TIMEOUT_MS);
 
 	return 0;
 }

-- 
2.34.1

