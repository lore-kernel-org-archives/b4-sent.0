From: Zi-Hao Huang <zi-hao.huang@mediatek.com>
Date: Wed, 18 Nov 2026 17:33:11 +0800
Subject: [PATCH v2] drm/mediatek: dsi: Don't let a signal cut the IRQ wait
 short
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-mtk-dsi-irq-wait-v2-1-8bda52993c6f@mediatek.com>
X-B4-Tracking: v=1; b=H4sIANZw/WoC/32NTQ6CQAxGr0K6toY28hNX3sOwqEyRhgA6M0EN4
 e6OHMDle8n3vhWCetMA52wFr4sFm6cEfMig7WW6K5pLDJxzSUQ1jnFAFwzNP/ElFlH4VBGLk5I
 rSLOH187ee/LaJO4txNl/9oeFfvZPbCEk5LzouOikrW98GdWZRB2O7TxCs23bF6MjLaazAAAA
X-Change-ID: 20261118-mtk-dsi-irq-wait-a24712ada627
To: Chun-Kuang Hu <chunkuang.hu@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 shaoming chen <shaoming.chen@mediatek.com>, dri-devel@lists.freedesktop.org, 
 linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Zi-Hao Huang <zi-hao.huang@mediatek.com>, CK Hu <ck.hu@mediatek.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794994396; l=2849;
 i=zi-hao.huang@mediatek.com; s=20261112; h=from:subject:message-id;
 bh=oSiLiwqCKkPp3lIKuiL5raZFKV28BSNXcVhbBi3SzXg=;
 b=vxu/8VdPlOJ1xHqEyJ64lB/7rEWbl4aMOvpjVViVoUm+YA7qopHYx1fIM4QO8RL6XUuWtY4CL
 sdTUiA0sJc2DCUsoRmyP0GpmHJ3PFqKaZ1F679Y91eWjGk/LZvKulA+
X-Developer-Key: i=zi-hao.huang@mediatek.com; a=ed25519;
 pk=tbMIVegYSSBtz5MaQSUCX9RJO88MA/AI5cbmQKbaoIc=
X-Endpoint-Received: by B4 Relay for zi-hao.huang@mediatek.com/20261112 with auth_id=1493
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mtk_dsi_wait_for_irq_done() waits for the DSI IRQ with
wait_event_interruptible_timeout(). If it returns early, for example
with -ERESTARTSYS when a signal is pending, both callers still treat the
command as done, because they only handle a return value of 0 as a
failure.

On an MT8196 board this led to a hard lockup during shutdown. The wait
returned before the IRQ arrived, the panel disable sequence went on and
restarted video mode, and the late CMD_DONE interrupt was then handled
by mtk_dsi_irq(). The handler writes RACK and loops until DSI_BUSY
clears, but DSI_BUSY stays set while video mode is running, so the CPU
never leaves the handler until the watchdog fires. Forcing the wait to
return early reproduces the lockup every time, and it no longer
happens once the wait cannot return early.

The wait synchronises the driver with the hardware, and it is bounded by
its timeout. Use wait_event_timeout() so that it only ends on the IRQ or
the timeout.

wake_up_interruptible() cannot wake a task in uninterruptible sleep, so
switch mtk_dsi_irq() to wake_up(). Without it every wait would last
until its timeout.

Fixes: dd5080a54df8 ("drm/mediatek: add dsi interrupt control")
Signed-off-by: Zi-Hao Huang <zi-hao.huang@mediatek.com>
Reviewed-by: CK Hu <ck.hu@mediatek.com>
---
Changes in v2:
- Drop the remark that the wait is not made on behalf of userspace, since
  a userspace backlight change can reach it (CK)
- Collect Reviewed-by
- Link to v1: https://lore.kernel.org/r/20261118-mtk-dsi-irq-wait-v1-1-205f25fac8b2@mediatek.com
---
 drivers/gpu/drm/mediatek/mtk_dsi.c | 7 +++----
 1 file changed, 3 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/mediatek/mtk_dsi.c b/drivers/gpu/drm/mediatek/mtk_dsi.c
index f82506e10fd5..1315dd31a834 100644
--- a/drivers/gpu/drm/mediatek/mtk_dsi.c
+++ b/drivers/gpu/drm/mediatek/mtk_dsi.c
@@ -627,9 +627,8 @@ static s32 mtk_dsi_wait_for_irq_done(struct mtk_dsi *dsi, u32 irq_flag,
 	unsigned long jiffies = msecs_to_jiffies(timeout);
 	struct drm_device *drm = dsi->bridge.dev;
 
-	ret = wait_event_interruptible_timeout(dsi->irq_wait_queue,
-					       dsi->irq_data & irq_flag,
-					       jiffies);
+	ret = wait_event_timeout(dsi->irq_wait_queue,
+				 dsi->irq_data & irq_flag, jiffies);
 	if (ret == 0) {
 		drm_warn(drm, "Wait DSI IRQ(0x%08x) Timeout\n", irq_flag);
 
@@ -656,7 +655,7 @@ static irqreturn_t mtk_dsi_irq(int irq, void *dev_id)
 
 		mtk_dsi_mask(dsi, DSI_INTSTA, status, 0);
 		mtk_dsi_irq_data_set(dsi, status);
-		wake_up_interruptible(&dsi->irq_wait_queue);
+		wake_up(&dsi->irq_wait_queue);
 	}
 
 	return IRQ_HANDLED;

---
base-commit: 067c5c24cef23d913b67eaaf71ae67e7169a6620
change-id: 20261118-mtk-dsi-irq-wait-a24712ada627

Best regards,
-- 
Zi-Hao Huang <zi-hao.huang@mediatek.com>

