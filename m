From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Tue, 24 Nov 2026 23:46:47 +0100
Subject: [PATCH 2/2] soundwire: qcom: populate wr_fifo_depth before
 enabling interrupts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-qcom-soundwire-fixes-v1-2-8ca94d60ddd6@gmail.com>
References: <20261124-qcom-soundwire-fixes-v1-0-8ca94d60ddd6@gmail.com>
In-Reply-To: <20261124-qcom-soundwire-fixes-v1-0-8ca94d60ddd6@gmail.com>
To: Srinivas Kandagatla <srini@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Bard Liao <yung-chuan.liao@linux.intel.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-arm-msm@vger.kernel.org, linux-sound@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795560406; l=2771;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=ubMHdvNcEq0xw+6HLkc77K1JCBeG6v8nJPQDHg2TJDg=;
 b=LDzxCCmc1jiBlI8Cq77vPJEnjiYxKJ1S/ZEnSwYFr5n7i1PlUgalWgAUES8EbePNX4caTa3cJ
 SXIHBYkmVw1BdRkMm8F3cQ8i8s8g4jujN339SfJKzEm2sCwLUBHp1rC
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ctrl->wr_fifo_depth is currently populated at the end of
qcom_swrm_init(), after devm_request_threaded_irq() in qcom_swrm_probe()
and after enabling CPU interrupts in qcom_swrm_init().

If a SoundWire interrupt fires before SWRM_COMP_PARAMS has been read,
qcom_swrm_cmd_fifo_wr_cmd() observes ctrl->wr_fifo_depth == 0 and fails
with -EIO ("err write overflow").

Read and validate SWRM_COMP_PARAMS in qcom_swrm_probe() prior to
requesting the threaded IRQ, and read SWRM_COMP_PARAMS before enabling
CPU interrupts in qcom_swrm_init().

Fixes: 02efb49aa805 ("soundwire: qcom: add support for SoundWire controller")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/soundwire/qcom.c | 27 +++++++++++++++++++++------
 1 file changed, 21 insertions(+), 6 deletions(-)

diff --git a/drivers/soundwire/qcom.c b/drivers/soundwire/qcom.c
index 368f511..3a42ab8 100644
--- a/drivers/soundwire/qcom.c
+++ b/drivers/soundwire/qcom.c
@@ -997,6 +997,12 @@ static int qcom_swrm_init(struct qcom_swrm_ctrl *ctrl)
 	ctrl->reg_write(ctrl, ctrl->reg_layout[SWRM_REG_INTERRUPT_CLEAR],
 			0xFFFFFFFF);
 
+	ctrl->reg_read(ctrl, SWRM_COMP_PARAMS, &val);
+	if (ctrl->version >= SWRM_VERSION_3_1_0)
+		ctrl->wr_fifo_depth = FIELD_GET(SWRM_V3_COMP_PARAMS_WR_FIFO_DEPTH, val);
+	else
+		ctrl->wr_fifo_depth = FIELD_GET(SWRM_COMP_PARAMS_WR_FIFO_DEPTH, val);
+
 	/* enable CPU IRQs for the selected EE window */
 	ctrl->reg_write(ctrl, ctrl->reg_layout[SWRM_REG_INTERRUPT_CPU_EN],
 			SWRM_INTERRUPT_STATUS_RMSK);
@@ -1008,12 +1014,6 @@ static int qcom_swrm_init(struct qcom_swrm_ctrl *ctrl)
 
 	swrm_wait_for_frame_gen_enabled(ctrl);
 	ctrl->slave_status = 0;
-	ctrl->reg_read(ctrl, SWRM_COMP_PARAMS, &val);
-
-	if (ctrl->version >= SWRM_VERSION_3_1_0)
-		ctrl->wr_fifo_depth = FIELD_GET(SWRM_V3_COMP_PARAMS_WR_FIFO_DEPTH, val);
-	else
-		ctrl->wr_fifo_depth = FIELD_GET(SWRM_COMP_PARAMS_WR_FIFO_DEPTH, val);
 
 	return 0;
 }
@@ -1717,6 +1717,21 @@ static int qcom_swrm_probe(struct platform_device *pdev)
 	ctrl->reg_read(ctrl, SWRM_COMP_HW_VERSION, &ctrl->version);
 	qcom_swrm_set_ee_register_layout(ctrl, data);
 
+	ret = ctrl->reg_read(ctrl, SWRM_COMP_PARAMS, &val);
+	if (ret != SDW_CMD_OK) {
+		ret = -EIO;
+		goto err_clk;
+	}
+	if (ctrl->version >= SWRM_VERSION_3_1_0)
+		ctrl->wr_fifo_depth = FIELD_GET(SWRM_V3_COMP_PARAMS_WR_FIFO_DEPTH, val);
+	else
+		ctrl->wr_fifo_depth = FIELD_GET(SWRM_COMP_PARAMS_WR_FIFO_DEPTH, val);
+	if (!ctrl->wr_fifo_depth) {
+		dev_err(dev, "Invalid write FIFO depth in SWRM_COMP_PARAMS: %#x\n", val);
+		ret = -EINVAL;
+		goto err_clk;
+	}
+
 	ret = devm_request_threaded_irq(dev, ctrl->irq, NULL,
 					qcom_swrm_irq_handler,
 					IRQF_TRIGGER_RISING |

-- 
2.56.0

