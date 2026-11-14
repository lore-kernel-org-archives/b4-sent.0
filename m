From: cookys <cookys@gmail.com>
Date: Sat, 14 Nov 2026 22:02:54 +0800
Subject: [PATCH] i2c: qup: scale the transfer timeout with the transfer
 length
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-qup-timeout-v1-1-ab3be931d506@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw5AMBBA0V+RWWtiEBW/IhYtg5F49SES8e+K5
 Vnce4Elw2Shii4wdLDldQnAOIJ2VMtAgrtgSJO0QMRc7H4TjmdavROFlirpykxqiRCKzVDP53e
 rm9/W64la9y7gvh8wYiE2bwAAAA==
X-Change-ID: 20261114-qup-timeout-6b7a0d837b71
To: Andi Shyti <andi.shyti@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794664973; l=3701;
 i=cookys@gmail.com; s=20261114; h=from:subject:message-id;
 bh=zxianrKojbq9bic6+na8V+oRSupTcgwcBLkFgdWYgvE=;
 b=x9S2ehW1Zf27K0+xaHExDuSiTdAXjX1Fkaef3wnZLrOUEFHb5ECZSiGELuPKVY00avdXYKso0
 V4JMCGOiaA9AgE7PWsLO8h+pzBuFprYTVKWyWYQulhtB93iLr6YaoBk
X-Developer-Key: i=cookys@gmail.com; a=ed25519;
 pk=CR+HDlVDbzSn6HgGtSLe9WwOu5qDJieqaLN/LgFay6c=
X-Endpoint-Received: by B4 Relay for cookys@gmail.com/20261114 with auth_id=1525
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

qup_i2c_probe() sets one transfer timeout for the adapter, sized for the
largest DMA transfer: TOUT_MIN (2 s) plus MX_DMA_TX_RX_LEN (128 KiB)
byte times. At the default 100 kHz that is 2 s + 131072 x 99 us, about
15 s, and every wait uses it, even for a one-byte read. A transfer that
never completes therefore stalls its caller for 15 s before -ETIMEDOUT.

On the Lenovo ThinkSmart View (APQ8053) the FT8201 touch controller
sometimes does not complete the first read after power-up (about one
boot in four). edt_ft5x06 probes asynchronously, so for those 15 s
every module init waits in async_synchronize_full(), and boot stalls:

  probe of 2-0038 with driver edt_ft5x06 returned 0 after 15343275 usecs

Set the timeout before each wait from the bytes that wait covers: the
message length on the FIFO and block paths (v1 and v2), the total of
the messages in the batch on the BAM path. The probe-time value is now
only the initial default. With this change the same failed read returns
after about 2 s:

  probe of 2-0038 with driver edt_ft5x06 returned 0 after 2353169 usecs

Tested on the ThinkSmart View (msm8953-mainline 7.3 with this change),
24 boots: touch probe 0.32-0.35 s, and 2.35 s in the one boot where
the controller missed its first read.

Assisted-by: Grok:grok-4.6
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: cookys <cookys@gmail.com>
---
 drivers/i2c/busses/i2c-qup.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/i2c/busses/i2c-qup.c b/drivers/i2c/busses/i2c-qup.c
index a0e076fc5..cda78933e 100644
--- a/drivers/i2c/busses/i2c-qup.c
+++ b/drivers/i2c/busses/i2c-qup.c
@@ -439,6 +439,12 @@ static int qup_i2c_change_state(struct qup_i2c_dev *qup, u32 state)
 	return 0;
 }
 
+static void qup_i2c_set_xfer_timeout(struct qup_i2c_dev *qup, unsigned int len)
+{
+	qup->xfer_timeout = TOUT_MIN * HZ +
+		usecs_to_jiffies(len * qup->one_byte_t);
+}
+
 /* Check if I2C bus returns to IDLE state */
 static int qup_i2c_bus_active(struct qup_i2c_dev *qup, int len)
 {
@@ -864,6 +870,7 @@ static int qup_i2c_bam_xfer(struct i2c_adapter *adap, struct i2c_msg *msg,
 	struct qup_i2c_dev *qup = i2c_get_adapdata(adap);
 	int ret = 0;
 	int idx = 0;
+	unsigned int xfer_len = 0;
 
 	ret = qup_i2c_vote_bw(qup, qup->src_clk_freq);
 	if (ret)
@@ -900,6 +907,8 @@ static int qup_i2c_bam_xfer(struct i2c_adapter *adap, struct i2c_msg *msg,
 		if (ret)
 			break;
 
+		xfer_len += qup->msg->len;
+
 		/*
 		 * Make DMA descriptor and schedule the BAM transfer if its
 		 * already crossed the maximum length. Since the memory for all
@@ -910,11 +919,13 @@ static int qup_i2c_bam_xfer(struct i2c_adapter *adap, struct i2c_msg *msg,
 		if (qup->btx.sg_cnt > qup->max_xfer_sg_len ||
 		    qup->brx.sg_cnt > qup->max_xfer_sg_len ||
 		    qup->is_last) {
+			qup_i2c_set_xfer_timeout(qup, xfer_len);
 			ret = qup_i2c_bam_schedule_desc(qup);
 			if (ret)
 				break;
 
 			qup_i2c_bam_clear_tag_buffers(qup);
+			xfer_len = 0;
 		}
 	}
 
@@ -1054,6 +1065,7 @@ static int qup_i2c_conf_xfer_v1(struct qup_i2c_dev *qup, bool is_rx)
 	if (ret)
 		goto err;
 
+	qup_i2c_set_xfer_timeout(qup, qup->msg->len);
 	ret = qup_i2c_wait_for_complete(qup, qup->msg);
 	if (ret)
 		goto err;
@@ -1432,6 +1444,7 @@ qup_i2c_conf_xfer_v2(struct qup_i2c_dev *qup, bool is_rx, bool is_first,
 	if (ret)
 		goto err;
 
+	qup_i2c_set_xfer_timeout(qup, msg->len);
 	ret = qup_i2c_wait_for_complete(qup, msg);
 	if (ret)
 		goto err;

---
base-commit: 04e9bf1648f846976b543e91c1838a712433772a
change-id: 20261114-qup-timeout-6b7a0d837b71

Best regards,
--  
cookys <cookys@gmail.com>

