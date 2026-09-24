From: David Heidelberg <david@ixit.cz>
Date: Thu, 24 Sep 2026 14:46:51 +0200
Subject: [PATCH v3 7/8] slimbus: qcom-ngd-ctrl: Remove data channels on
 stream disable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-pixel3-audio-v3-7-5d06460fc8a9@ixit.cz>
References: <20260924-pixel3-audio-v3-0-5d06460fc8a9@ixit.cz>
In-Reply-To: <20260924-pixel3-audio-v3-0-5d06460fc8a9@ixit.cz>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 David Rhodes <drhodes@opensource.cirrus.com>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, patches@opensource.cirrus.com, 
 devicetree@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4926; i=david@ixit.cz;
 h=from:subject:message-id; bh=L1zZgtGEouYGzKgRZLVxO9EXpSlpZurV4JACrcU/HQI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtRu4+QTbcZHOnBlR7xwF3SE+KknAz7FJPPKFE
 DXTWA8J8gyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarUbuAAKCRBgAj/E00kg
 cvR6EADED+5bZiFOKpq2r2N3R48F7+/fGlxFAbHT0knkdDqR8M1/+BYdFeSgGH/N+/oK3toPvpd
 dUam1+CHPv9dUUaG6CuwkiTqIDw23wJgbLtapXV9KqfZw2MhBGV3CjLHkibk8cHTI4UeqqS7UFh
 3kGdppFpGBs0npR7RuaOHU7h3vbsyBuAe/thGXEpBMdt342zzSHmKz53cj1nk9Fg4Pp0kQKjj2l
 1lB/G/q+2sotI+yy581UFKk1M8BNT7kDUw5DrY8kSc48JEltllGeSPRMUAbMZHUvJN+Xb78/G5T
 NWMtDMjDrGEU4E4I04WvMF31sWrIQch4UNqpf4zE/I07EiQK1yppGD/Wz1gtEEuhld2hEphgjWo
 RUetDmnq3Msge3zXOrSgwVhGQcud18JFUsKM1RIq/HiCvwTXCR+hwHQsIMqfKHP2/yYbDQUpkRe
 5IWtQz9hKJYaRHir2aWBhdWUzd0L0xnC+oNNFU2VbABpBBzehKn54Y7bW0OGP0qwa0sJcvVdEFT
 B2PaTwUeorUmH5u5Yj3rL/Y4v+76K5l5QtFLmjH0Foo+HOYImzKQQ9Q+odBP6BqbfppcKkB61oS
 hs9hwfRddV32TcC7eRVVCEduKTP6xFRrVsbVwAbYZ4NbgX0tT/s3wmUa4PTzBmNBDLzVb0l2lI0
 xhQok0HIde1YI6A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

qcom_slim_ngd_xfer_msg() silently returns success for every core
reconfiguration message, so the generic channel removal done by
slim_stream_disable() never reaches the ADSP SLIMbus master. The
master therefore keeps the channels of a closed stream. When the next
stream defines the same channel numbers again, the WCD9340 capture
completes without any error but records only zeros; removing the
channels explicitly when the stream is disabled makes it work again.

Implement the disable_stream controller op with the sequence the
downstream NGD driver sends for channel removal, CHAN_CTRL(REMOVE)
listing the stream's channels followed by RECONFIG_NOW. Like
downstream, treat -EREMOTEIO from the removal as success: it means the
controller is being restarted and the channels are gone anyway.

Based on work done by Casey Tunturi.

Assisted-by: Claude:claude-fable-5-1
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/slimbus/qcom-ngd-ctrl.c | 81 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 81 insertions(+)

diff --git a/drivers/slimbus/qcom-ngd-ctrl.c b/drivers/slimbus/qcom-ngd-ctrl.c
index 934c44c5bc1a9..c91f55036dd55 100644
--- a/drivers/slimbus/qcom-ngd-ctrl.c
+++ b/drivers/slimbus/qcom-ngd-ctrl.c
@@ -1080,16 +1080,96 @@ static int qcom_slim_ngd_enable_stream(struct slim_stream_runtime *rt)
 		slim_free_txn_tid(ctrl, &txn);
 		dev_err(&sdev->dev, "TX timed out:MC:0x%x,mt:0x%x", txn.mc,
 				txn.mt);
 	}
 
 	return ret;
 }
 
+/* CHAN_CTRL operation, bits [7:6] of the first payload byte */
+#define SLIM_USR_CHAN_CTRL_REMOVE	2
+
+static int qcom_slim_ngd_disable_stream(struct slim_stream_runtime *rt)
+{
+	struct slim_device *sdev = rt->dev;
+	struct slim_controller *ctrl = sdev->ctrl;
+	struct slim_val_inf msg =  {0};
+	u8 wbuf[SLIM_MSGQ_BUF_LEN];
+	u8 rbuf[SLIM_MSGQ_BUF_LEN];
+	struct slim_msg_txn txn = {0,};
+	int i, ret;
+
+	txn.mt = SLIM_MSG_MT_DEST_REFERRED_USER;
+	txn.dt = SLIM_MSG_DEST_LOGICALADDR;
+	txn.la = SLIM_LA_MGR;
+	txn.ec = 0;
+	txn.msg = &msg;
+	txn.msg->num_bytes = 0;
+	txn.msg->wbuf = wbuf;
+	txn.msg->rbuf = rbuf;
+
+	/*
+	 * The NGD drops the core reconfiguration messages that
+	 * slim_stream_disable() uses to remove channels, so ask the master
+	 * to remove them the way the downstream NGD driver does:
+	 * CHAN_CTRL(REMOVE) listing every channel, then RECONFIG_NOW.
+	 * Without this the master keeps the channels active and a later
+	 * DEF_ACT_CHAN with the same channel numbers is a no-op, so the
+	 * data path is never re-armed and a reopened stream moves no data.
+	 */
+	/* 5-bit client number, operation in bits [7:6] */
+	wbuf[txn.msg->num_bytes++] = (SLIM_USR_CHAN_CTRL_REMOVE << 6) |
+				     (sdev->laddr & 0x1f);
+
+	ret = slim_alloc_txn_tid(ctrl, &txn);
+	if (ret) {
+		dev_err(&sdev->dev, "Fail to allocate TID\n");
+		return ret;
+	}
+	wbuf[txn.msg->num_bytes++] = txn.tid;
+
+	for (i = 0; i < rt->num_ports; i++)
+		wbuf[txn.msg->num_bytes++] = rt->ports[i].ch.id;
+
+	txn.mc = SLIM_USR_MC_CHAN_CTRL;
+	txn.rl = txn.msg->num_bytes + 4;
+	ret = qcom_slim_ngd_xfer_msg_sync(ctrl, &txn);
+	if (ret) {
+		slim_free_txn_tid(ctrl, &txn);
+		/* Controller restarting, the channels are gone anyway */
+		if (ret == -EREMOTEIO)
+			return 0;
+		dev_err(&sdev->dev, "TX timed out:MC:0x%x,mt:0x%x", txn.mc,
+				txn.mt);
+		return ret;
+	}
+
+	txn.mc = SLIM_USR_MC_RECONFIG_NOW;
+	txn.msg->num_bytes = 2;
+	wbuf[1] = sdev->laddr;
+	txn.rl = txn.msg->num_bytes + 4;
+
+	ret = slim_alloc_txn_tid(ctrl, &txn);
+	if (ret) {
+		dev_err(ctrl->dev, "Fail to allocate TID\n");
+		return ret;
+	}
+
+	wbuf[0] = txn.tid;
+	ret = qcom_slim_ngd_xfer_msg_sync(ctrl, &txn);
+	if (ret) {
+		slim_free_txn_tid(ctrl, &txn);
+		dev_err(&sdev->dev, "TX timed out:MC:0x%x,mt:0x%x", txn.mc,
+				txn.mt);
+	}
+
+	return ret;
+}
+
 static int qcom_slim_ngd_get_laddr(struct slim_controller *ctrl,
 				   struct slim_eaddr *ea, u8 *laddr)
 {
 	struct slim_val_inf msg =  {0};
 	u8 failed_ea[6] = {0, 0, 0, 0, 0, 0};
 	struct slim_msg_txn txn;
 	u8 wbuf[10] = {0};
 	u8 rbuf[10] = {0};
@@ -1619,16 +1699,17 @@ static int qcom_slim_ngd_ctrl_probe(struct platform_device *pdev)
 	ctrl->framer.rootfreq = SLIM_ROOT_FREQ >> 3;
 	ctrl->framer.superfreq =
 		ctrl->framer.rootfreq / SLIM_CL_PER_SUPERFRAME_DIV8;
 
 	ctrl->ctrl.a_framer = &ctrl->framer;
 	ctrl->ctrl.clkgear = SLIM_MAX_CLK_GEAR;
 	ctrl->ctrl.get_laddr = qcom_slim_ngd_get_laddr;
 	ctrl->ctrl.enable_stream = qcom_slim_ngd_enable_stream;
+	ctrl->ctrl.disable_stream = qcom_slim_ngd_disable_stream;
 	ctrl->ctrl.xfer_msg = qcom_slim_ngd_xfer_msg;
 	ctrl->ctrl.wakeup = NULL;
 	ctrl->state = QCOM_SLIM_NGD_CTRL_DOWN;
 
 	mutex_init(&ctrl->tx_lock);
 	mutex_init(&ctrl->ssr_lock);
 	spin_lock_init(&ctrl->tx_buf_lock);
 	init_completion(&ctrl->reconf);

-- 
2.55.0

