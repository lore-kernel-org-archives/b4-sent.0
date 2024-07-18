From: "Jason-JH.Lin" <jason-jh.lin@mediatek.com>
Date: Thu, 18 Jul 2024 22:17:04 +0800
Subject: [PATCH v3] mailbox: mtk-cmdq: Move devm_mbox_controller_register()
 after devm_pm_runtime_enable()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-mtk-cmdq-fixup-v3-1-e3cbb75bb950@mediatek.com>
X-B4-Tracking: v=1; b=H4sIAN8jmWYC/23O3w6CIBgF8FdxXIfjj6B21Xu0LhAx0QADYzXnu
 4d20da6POfb+e1bQFBeqwCO2QK8ijpoZ1OghwzIXtirgrpNGRBEClTiCpp5hNK0d9jp52OCBaJ
 lzRlSNW9AGk1epcMOni8p9zrMzr92P+Kt/VAcU8wQJzwnjFQIYjiI4Cwc+vym7cmoVotZjbl0B
 mxOJN/tnzciSULHm4ZKxIjg6EdY1/UNa5RY+esAAAA=
To: Jassi Brar <jassisinghbrar@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 CK Hu <ck.hu@mediatek.com>
Cc: Jassi Brar <jaswinder.singh@linaro.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 "Jason-JH.Lin" <jason-jh.lin@mediatek.com>, 
 Singo Chang <singo.chang@mediatek.com>, Nancy Lin <nancy.lin@mediatek.com>, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 Project_Global_Chrome_Upstream_Group@mediatek.com
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721312235; l=3031;
 i=jason-jh.lin@mediatek.com; s=20240718; h=from:subject:message-id;
 bh=OFADgvXE3QyzUSfck3fA9qrQhD5Lvasr7wyTfx6OG4A=;
 b=6FSYmXDRSQheDTXmSlRWEShpwc9Bzr17pepSJ9sUgZUmdH6S4CdDDAapAQq9YQeCzDzg91/vl
 qcs9jRp7ZPRDbuscIGzljw/fUMu+iB9GNXBvlBZCS3ZsYEPYuO6ndc8
X-Developer-Key: i=jason-jh.lin@mediatek.com; a=ed25519;
 pk=7Hn+BnFBlPrluT5ks5tKVWb3f7O/bMBs6qEemVJwqOo=
X-Endpoint-Received: by B4 Relay for jason-jh.lin@mediatek.com/20240718 with auth_id=187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When mtk-cmdq unbinds, a WARN_ON message with condition
pm_runtime_get_sync() < 0 occurs.

According to the call tracei below:
  cmdq_mbox_shutdown
  mbox_free_channel
  mbox_controller_unregister
  __devm_mbox_controller_unregister
  ...

The root cause can be deduced to be calling pm_runtime_get_sync() after
calling pm_runtime_disable() as observed below:
1. CMDQ driver uses devm_mbox_controller_register() in cmdq_probe()
   to bind the cmdq device to the mbox_controller, so
   devm_mbox_controller_unregister() will automatically unregister
   the device bound to the mailbox controller when the device-managed
   resource is removed. That means devm_mbox_controller_unregister()
   and cmdq_mbox_shoutdown() will be called after cmdq_remove().
2. CMDQ driver also uses devm_pm_runtime_enable() in cmdq_probe() after
   devm_mbox_controller_register(), so that devm_pm_runtime_disable()
   will be called after cmdq_remove(), but before
   devm_mbox_controller_unregister().

To fix this problem, cmdq_probe() needs to move
devm_mbox_controller_register() after devm_pm_runtime_enable() to make
devm_pm_runtime_disable() be called after
devm_mbox_controller_unregister().

Fixes: 623a6143a845 ("mailbox: mediatek: Add Mediatek CMDQ driver")
Signed-off-by: Jason-JH.Lin <jason-jh.lin@mediatek.com>
---
Changes in v3:
- Remove redundant message in b4 cover letter.
- Remove the change of cmdq_remove() in v1
- Link to v2: https://lore.kernel.org/r/20240718-mtk-cmdq-fixup-v2-1-f6bb3c052a60@mediatek.com

Changes in v2:
- Change to move the calling sequence of devm_mbox_controller_register()
  and devm_pm_runtime_enable().
- Link to v1: https://lore.kernel.org/r/20240613150626.25280-1-jason-jh.lin@mediatek.com
---
 drivers/mailbox/mtk-cmdq-mailbox.c | 12 ++++++------
 1 file changed, 6 insertions(+), 6 deletions(-)

diff --git a/drivers/mailbox/mtk-cmdq-mailbox.c b/drivers/mailbox/mtk-cmdq-mailbox.c
index f1dfce9e27f5..4bff73532085 100644
--- a/drivers/mailbox/mtk-cmdq-mailbox.c
+++ b/drivers/mailbox/mtk-cmdq-mailbox.c
@@ -689,12 +689,6 @@ static int cmdq_probe(struct platform_device *pdev)
 		cmdq->mbox.chans[i].con_priv = (void *)&cmdq->thread[i];
 	}
 
-	err = devm_mbox_controller_register(dev, &cmdq->mbox);
-	if (err < 0) {
-		dev_err(dev, "failed to register mailbox: %d\n", err);
-		return err;
-	}
-
 	platform_set_drvdata(pdev, cmdq);
 
 	WARN_ON(clk_bulk_prepare(cmdq->pdata->gce_num, cmdq->clocks));
@@ -722,6 +716,12 @@ static int cmdq_probe(struct platform_device *pdev)
 	pm_runtime_set_autosuspend_delay(dev, CMDQ_MBOX_AUTOSUSPEND_DELAY_MS);
 	pm_runtime_use_autosuspend(dev);
 
+	err = devm_mbox_controller_register(dev, &cmdq->mbox);
+	if (err < 0) {
+		dev_err(dev, "failed to register mailbox: %d\n", err);
+		return err;
+	}
+
 	return 0;
 }
 

---
base-commit: 797012914d2d031430268fe512af0ccd7d8e46ef
change-id: 20240718-mtk-cmdq-fixup-40379650e96b

Best regards,
-- 
Jason-JH.Lin <jason-jh.lin@mediatek.com>

