From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: broonie@kernel.org, lgirdwood@gmail.com
Cc: perex@perex.cz, tiwai@suse.com, matthias.bgg@gmail.com, 
 angelogioacchino.delregno@collabora.com, linux-sound@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH] ASoC: mediatek: mtk-btcvsd: use the interrupt trigger type
 from DT
Date: Thu, 26 Nov 2026 00:07:13 +0000
Message-Id: <20261126000713.16278-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795651633; l=2186;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=eK0kCGN8jhYcvo75iPIlGqPqAmjRPKiR5NkFGxOHi/4=;
 b=imz1BKLz86VmdPyoyd6t5RBgPkiAnl93f6jGPcOq5pA4oJx1EvQKuzvcWprs5//TKtKop0B+U
 qCvEWlvZ3EEDz8Y1JN6omvvGnjb9JXHcTewq06LRmLxT/rTN5DdR0jF
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver requests its interrupt with IRQF_TRIGGER_LOW, which
overrides the trigger type given in the device tree. That only works
where a polarity inverter such as mediatek,mt6577-sysirq sits between
the BT-SCO interrupt and the GIC. On SoCs that route it straight to a
GICv3 SPI as level-high, MT6789 for example, gic_set_type() rejects a
level-low SPI, request_irq() fails with -EINVAL and the driver does not
probe.

Pass no trigger flags so that the type configured from the
"interrupts" property is used. The binding example keeps
IRQ_TYPE_LEVEL_LOW, which is still what such a node gets, and no
in-tree device tree uses this compatible yet. MediaTek's downstream
version of this driver requests the interrupt with IRQF_TRIGGER_NONE
and describes it as IRQ_TYPE_LEVEL_HIGH in its MT6789, MT6833, MT6853,
MT6855, MT6873 and MT6879 device trees.

Found and drafted with an AI coding assistant while bringing up MT6789.

Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---

Notes:
    The same change is in the MediaTek-derived copy of this driver that runs on
    an MT6789 phone (GIC_SPI 407 IRQ_TYPE_LEVEL_HIGH): it probes and is in use
    (logs of the 6.18 build). This exact mainline change was not built or run.
    No Fixes tag because no in-tree device tree is affected; a tag pointing at
    4bd8597dc36c (the commit that added the driver) can be added if preferred.

 sound/soc/mediatek/common/mtk-btcvsd.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/sound/soc/mediatek/common/mtk-btcvsd.c b/sound/soc/mediatek/common/mtk-btcvsd.c
index 19329dd..4448d99 100644
--- a/sound/soc/mediatek/common/mtk-btcvsd.c
+++ b/sound/soc/mediatek/common/mtk-btcvsd.c
@@ -1298,8 +1298,7 @@ static int mtk_btcvsd_snd_probe(struct platform_device *pdev)
 		return irq_id < 0 ? irq_id : -ENXIO;
 
 	ret = devm_request_irq(dev, irq_id, mtk_btcvsd_snd_irq_handler,
-			       IRQF_TRIGGER_LOW, "BTCVSD_ISR_Handle",
-			       (void *)btcvsd);
+			       0, "BTCVSD_ISR_Handle", (void *)btcvsd);
 	if (ret) {
 		dev_err(dev, "could not request_irq for BTCVSD_ISR_Handle\n");
 		return ret;
-- 
2.54.0 (Apple Git-157)


