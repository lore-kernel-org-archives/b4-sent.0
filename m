From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 28 Jul 2026 12:42:48 +0300
Subject: [PATCH 3/3] mailbox: mtk-cmdq: add mt6572 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260728-6572-gce-v1-3-750bba32689e@protonmail.com>
References: <20260728-6572-gce-v1-0-750bba32689e@protonmail.com>
In-Reply-To: <20260728-6572-gce-v1-0-750bba32689e@protonmail.com>
To: Jassi Brar <jassisinghbrar@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Houlong Wei <houlong.wei@mediatek.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785231864; l=1755;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=wlNt8w4pK42NOY4pipdycMZ5TzX4r9IY7xlPIXoIXu4=;
 b=em8m3keAx8V+DEbFxfHYM9caC9+m2KxyazIAl9NkghlYodMVJLxPtOwvaJrzxthYwgXX8ILn6
 O2oPz0eD9uwAJe10xMRTPsdOBs/VuAToBRcn98foH/+ksODxndUn4dX
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add legacy_isa field forwarding to the cmdq helper and a platform data
for the mt6572 GCE.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/mailbox/mtk-cmdq-mailbox.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/mailbox/mtk-cmdq-mailbox.c b/drivers/mailbox/mtk-cmdq-mailbox.c
index e523c84b4808..5e7bc52baaa1 100644
--- a/drivers/mailbox/mtk-cmdq-mailbox.c
+++ b/drivers/mailbox/mtk-cmdq-mailbox.c
@@ -99,6 +99,7 @@ struct gce_plat {
 	bool control_by_sw;
 	bool sw_ddr_en;
 	bool gce_vm;
+	bool legacy_isa;
 	u32 gce_num;
 };
 
@@ -119,6 +120,7 @@ void cmdq_get_mbox_priv(struct mbox_chan *chan, struct cmdq_mbox_priv *priv)
 	struct cmdq *cmdq = container_of(chan->mbox, struct cmdq, mbox);
 
 	priv->shift_pa = cmdq->pdata->shift;
+	priv->legacy_isa = cmdq->pdata->legacy_isa;
 	priv->mminfra_offset = cmdq->pdata->mminfra_offset;
 }
 EXPORT_SYMBOL(cmdq_get_mbox_priv);
@@ -787,6 +789,14 @@ static const struct dev_pm_ops cmdq_pm_ops = {
 			   cmdq_runtime_resume, NULL)
 };
 
+static const struct gce_plat gce_plat_mt6572 = {
+	.thread_nr = 14,
+	.shift = 0,
+	.control_by_sw = false,
+	.legacy_isa = true,
+	.gce_num = 1
+};
+
 static const struct gce_plat gce_plat_mt6779 = {
 	.thread_nr = 24,
 	.shift = 3,
@@ -848,6 +858,7 @@ static const struct gce_plat gce_plat_mt8196 = {
 };
 
 static const struct of_device_id cmdq_of_ids[] = {
+	{.compatible = "mediatek,mt6572-gce", .data = (void *)&gce_plat_mt6572},
 	{.compatible = "mediatek,mt6779-gce", .data = (void *)&gce_plat_mt6779},
 	{.compatible = "mediatek,mt8173-gce", .data = (void *)&gce_plat_mt8173},
 	{.compatible = "mediatek,mt8183-gce", .data = (void *)&gce_plat_mt8183},

-- 
2.54.0

