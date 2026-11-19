From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 06:20:08 +0000
Subject: [PATCH 2/2] media: verisilicon: Reset the VDPU2 decoder after an
 error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-vdpu2-errreset-v1-2-f8fa403b6a3a@gmail.com>
References: <20261119-vdpu2-errreset-v1-0-f8fa403b6a3a@gmail.com>
In-Reply-To: <20261119-vdpu2-errreset-v1-0-f8fa403b6a3a@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Jonas Karlman <jonas@kwiboo.se>, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795069206; l=2516;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=sjdfbb38xSnpl2qcZS+zDoOlunwHqKwXDRUV5q2wqsU=;
 b=WqxcSouqA+T7MzDgKzey3DPKmJA8dW53kZv4m7HQO81sYEsEG+IJCli/vrtWW45S9MVoiAsd6
 VTWS9aKvOQrA9Hchq40aPRHhC6X+5r+aY/2O3OnU+sNYNNkNS62RQ7Z
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After a stream or bus error the decoder can still access the buffers of
the failed picture. On RK3588 these accesses hit buffers userspace had
already freed: IOMMU page faults, an IOMMU that can no longer stall and
corrupted output for the next job.

Soft-reset the decoder on every error interrupt, as the vendor driver
does, and wait for the reset to complete.

Fixes: 879dee56a40c ("media: rockchip/vpu: Add MPEG2 decoding support to RK3399")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../media/platform/verisilicon/rockchip_vpu_hw.c    | 21 +++++++++++++++++++--
 1 file changed, 19 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
index 4bc1bdb41c70..01cd449f3ab2 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
@@ -7,6 +7,7 @@
  */
 
 #include <linux/clk.h>
+#include <linux/iopoll.h>
 
 #include "hantro.h"
 #include "hantro_jpeg.h"
@@ -384,6 +385,21 @@ static irqreturn_t rockchip_vpu1_vepu_irq(int irq, void *dev_id)
 	return IRQ_HANDLED;
 }
 
+/*
+ * After an error the decoder can still have bus accesses of the failed
+ * picture in flight; reset it before its buffers go back to userspace.
+ */
+static void rockchip_vpu2_dec_soft_reset(struct hantro_dev *vpu)
+{
+	u32 val;
+
+	vdpu_write(vpu, 0, VDPU_REG_EN_FLAGS);
+	vdpu_write(vpu, 1, VDPU_REG_SOFT_RESET);
+	if (read_poll_timeout_atomic(vdpu_read, val, !val, 0, 5, false, vpu,
+				     VDPU_REG_SOFT_RESET))
+		dev_warn_ratelimited(vpu->dev, "decoder soft reset timed out\n");
+}
+
 static irqreturn_t rockchip_vpu2_vdpu_irq(int irq, void *dev_id)
 {
 	struct hantro_dev *vpu = dev_id;
@@ -396,6 +412,8 @@ static irqreturn_t rockchip_vpu2_vdpu_irq(int irq, void *dev_id)
 
 	vdpu_write(vpu, 0, VDPU_REG_INTERRUPT);
 	vdpu_write(vpu, 0, VDPU_REG_AXI_CTRL);
+	if (state != VB2_BUF_STATE_DONE)
+		rockchip_vpu2_dec_soft_reset(vpu);
 
 	hantro_irq_done(vpu, state);
 
@@ -482,8 +500,7 @@ static void rockchip_vpu2_dec_reset(struct hantro_ctx *ctx)
 	struct hantro_dev *vpu = ctx->dev;
 
 	vdpu_write(vpu, VDPU_REG_INTERRUPT_DEC_IRQ_DIS, VDPU_REG_INTERRUPT);
-	vdpu_write(vpu, 0, VDPU_REG_EN_FLAGS);
-	vdpu_write(vpu, 1, VDPU_REG_SOFT_RESET);
+	rockchip_vpu2_dec_soft_reset(vpu);
 }
 
 static void rockchip_vpu2_enc_reset(struct hantro_ctx *ctx)

-- 
2.55.0

