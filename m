From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Thu, 26 Nov 2026 09:06:24 +0100
Subject: [PATCH v2 1/2] soundwire: qcom: serialize WCD AHB bridge
 transactions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-qcom-soundwire-fixes-v2-1-07075d571c6c@gmail.com>
References: <20261126-qcom-soundwire-fixes-v2-0-07075d571c6c@gmail.com>
In-Reply-To: <20261126-qcom-soundwire-fixes-v2-0-07075d571c6c@gmail.com>
To: Srinivas Kandagatla <srini@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Bard Liao <yung-chuan.liao@linux.intel.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-arm-msm@vger.kernel.org, linux-sound@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795680384; l=3091;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=5uJq685h5aRJoQkGPj7uFNL/b8j1PB/pVjJOUzHUz2E=;
 b=GNdhuHp0Mre8YZRbkNI5DEED5T+BAMcB0/gaM+OCxchZbGAs1O5Pi0vgvdkwkVHS8nXxkP5GJ
 Rhyvzds58RzCVGqg7ayNllfbLDT2FyrLEtZN6EaMauIxfmM5LQgOwez
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On SLIMbus-hosted WCD934x Qualcomm SoundWire controllers, each AHB
bridge register access spans two separate regmap_bulk_*() transfers
(SWRM_AHB_BRIDGE_RD_ADDR_0 followed by SWRM_AHB_BRIDGE_RD_DATA_0, or
SWRM_AHB_BRIDGE_WR_DATA_0 followed by SWRM_AHB_BRIDGE_WR_ADDR_0).

Without controller-level serialization across each pair, concurrent
accesses from the threaded IRQ handler and bus/init callers can
interleave on the shared AHB bridge registers and corrupt reads or
writes.

Add ahb_lock to struct qcom_swrm_ctrl to serialize each two-step AHB
bridge register transaction.

Fixes: 02efb49aa805 ("soundwire: qcom: add support for SoundWire controller")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/soundwire/qcom.c | 30 +++++++++++++++++-------------
 1 file changed, 17 insertions(+), 13 deletions(-)

diff --git a/drivers/soundwire/qcom.c b/drivers/soundwire/qcom.c
index c31d921f679f968652c744aceecf001ab3794a6c..368f511867835e6ce1e1d7f0827461413c25a96e 100644
--- a/drivers/soundwire/qcom.c
+++ b/drivers/soundwire/qcom.c
@@ -202,6 +202,8 @@ struct qcom_swrm_ctrl {
 	struct completion enumeration;
 	/* Port alloc/free lock */
 	struct mutex port_lock;
+	/* Serialize two-step WCD AHB bridge address/data accesses */
+	struct mutex ahb_lock;
 	struct clk *hclk;
 	int irq;
 	u32 ee;
@@ -388,18 +390,18 @@ static int qcom_swrm_ahb_reg_read(struct qcom_swrm_ctrl *ctrl, int reg,
 	struct regmap *wcd_regmap = ctrl->regmap;
 	int ret;
 
+	mutex_lock(&ctrl->ahb_lock);
 	/* pg register + offset */
 	ret = regmap_bulk_write(wcd_regmap, SWRM_AHB_BRIDGE_RD_ADDR_0,
-			  (u8 *)&reg, 4);
+				(u8 *)&reg, 4);
 	if (ret < 0)
-		return SDW_CMD_FAIL;
+		goto out;
 
 	ret = regmap_bulk_read(wcd_regmap, SWRM_AHB_BRIDGE_RD_DATA_0,
 			       val, 4);
-	if (ret < 0)
-		return SDW_CMD_FAIL;
-
-	return SDW_CMD_OK;
+out:
+	mutex_unlock(&ctrl->ahb_lock);
+	return ret < 0 ? SDW_CMD_FAIL : SDW_CMD_OK;
 }
 
 static int qcom_swrm_ahb_reg_write(struct qcom_swrm_ctrl *ctrl,
@@ -407,19 +409,20 @@ static int qcom_swrm_ahb_reg_write(struct qcom_swrm_ctrl *ctrl,
 {
 	struct regmap *wcd_regmap = ctrl->regmap;
 	int ret;
+
+	mutex_lock(&ctrl->ahb_lock);
 	/* pg register + offset */
 	ret = regmap_bulk_write(wcd_regmap, SWRM_AHB_BRIDGE_WR_DATA_0,
-			  (u8 *)&val, 4);
+				(u8 *)&val, 4);
 	if (ret)
-		return SDW_CMD_FAIL;
+		goto out;
 
 	/* write address register */
 	ret = regmap_bulk_write(wcd_regmap, SWRM_AHB_BRIDGE_WR_ADDR_0,
-			  (u8 *)&reg, 4);
-	if (ret)
-		return SDW_CMD_FAIL;
-
-	return SDW_CMD_OK;
+				(u8 *)&reg, 4);
+out:
+	mutex_unlock(&ctrl->ahb_lock);
+	return ret ? SDW_CMD_FAIL : SDW_CMD_OK;
 }
 
 static int qcom_swrm_cpu_reg_read(struct qcom_swrm_ctrl *ctrl, int reg,
@@ -1680,6 +1683,7 @@ static int qcom_swrm_probe(struct platform_device *pdev)
 	ctrl->dev = dev;
 	dev_set_drvdata(&pdev->dev, ctrl);
 	mutex_init(&ctrl->port_lock);
+	mutex_init(&ctrl->ahb_lock);
 	init_completion(&ctrl->broadcast);
 	init_completion(&ctrl->enumeration);
 

-- 
2.47.3

