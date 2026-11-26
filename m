From: Hank Liou <hank.liou@mediatek.com>
Date: Thu, 26 Nov 2026 11:15:43 +0800
Subject: [PATCH] drm/mediatek: dp: Disable HPD IRQ before cancelling
 debounce timer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-mtk-dp-hpd-irq-v1-1-0b8663980732@mediatek.com>
X-B4-Tracking: v=1; b=H4sIAF6kB2sC/x3MQQqAIBBA0avErBvIgSy6SrSoHGuIyjQiEO+et
 HyL/yME9sIBuiKC50eCnEeGKguY1/FYGMVkA1WklSKN+72hcbg6g+IvrO3cTto2xJohR86zlfc
 f9kNKHzLLnKdgAAAA
X-Change-ID: 20261126-mtk-dp-hpd-irq-5fc8b6f72e6e
To: Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 CK Hu <ck.hu@mediatek.com>, Jitao Shi <jitao.shi@mediatek.com>, 
 dri-devel@lists.freedesktop.org, linux-mediatek@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Hank Liou <hank.liou@mediatek.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795662942; l=1945;
 i=hank.liou@mediatek.com; s=20261126; h=from:subject:message-id;
 bh=l8xHL6bFv9F0w89mKejFr4yktC399A1FMDm4H5KqRU4=;
 b=GMsAhPoL7vpG1VsZ4mqOsHWU7s0UrcQwn0VDsAGlTrnk2NTX+fHABoTmEUf+xrjgHTZSOx5qV
 8qi+ncW7drhCPh3Y5V+fsYw6ylYT6RVz4Z9L86R0hWFvc5cCKTeJoHC
X-Developer-Key: i=hank.liou@mediatek.com; a=ed25519;
 pk=oQN2zU+HMrJQgqX4bhL5CVRrBmac4amZ/53yK20L/6M=
X-Endpoint-Received: by B4 Relay for hank.liou@mediatek.com/20261126 with auth_id=1646
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mtk_dp_remove() cancels debounce_timer with timer_delete_sync(), but the
HPD interrupt that re-arms it from mtk_dp_hpd_event_thread() is
requested with devm_request_threaded_irq() and stays enabled until
devres runs after .remove returns. An HPD falling edge between the
timer cancellation and the IRQ release re-arms the timer, which can
then expire after the driver has been unbound, when the struct mtk_dp
that embeds it may already be freed.

Disable the IRQ first, which also waits for a running hard or threaded
handler, then cancel the timer. Do this before the runtime PM calls so
the interrupt is quiesced while the hardware is still powered.

Fixes: 4652e95e7ea6 ("drm/mediatek: dp: Add hpd debounce")
Signed-off-by: Hank Liou <hank.liou@mediatek.com>
---
Fix the ordering of the HPD IRQ disable and the debounce timer cancellation in mtk_dp_remove().
---
 drivers/gpu/drm/mediatek/mtk_dp.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_dp.c b/drivers/gpu/drm/mediatek/mtk_dp.c
index 974c4fff6..7a5e380fd 100644
--- a/drivers/gpu/drm/mediatek/mtk_dp.c
+++ b/drivers/gpu/drm/mediatek/mtk_dp.c
@@ -2865,10 +2865,13 @@ static void mtk_dp_remove(struct platform_device *pdev)
 {
 	struct mtk_dp *mtk_dp = platform_get_drvdata(pdev);
 
+	if (mtk_dp->data->bridge_type != DRM_MODE_CONNECTOR_eDP) {
+		disable_irq(mtk_dp->irq);
+		timer_delete_sync(&mtk_dp->debounce_timer);
+	}
+
 	pm_runtime_put(&pdev->dev);
 	pm_runtime_disable(&pdev->dev);
-	if (mtk_dp->data->bridge_type != DRM_MODE_CONNECTOR_eDP)
-		timer_delete_sync(&mtk_dp->debounce_timer);
 	platform_device_unregister(mtk_dp->phy_dev);
 	if (mtk_dp->audio_pdev)
 		platform_device_unregister(mtk_dp->audio_pdev);

---
base-commit: ebb7a8dc1e74c705daffe11c2faf38ec2628f838
change-id: 20261126-mtk-dp-hpd-irq-5fc8b6f72e6e

Best regards,
-- 
Hank Liou <hank.liou@mediatek.com>

