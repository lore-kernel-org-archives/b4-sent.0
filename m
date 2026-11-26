From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 11:03:06 +0000
Subject: [PATCH v4 2/2] media: verisilicon: Reset the VDPU2 decoder after
 an error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-vdpu2-errreset-v4-2-a955b1c8b119@gmail.com>
References: <20261126-vdpu2-errreset-v4-0-a955b1c8b119@gmail.com>
In-Reply-To: <20261126-vdpu2-errreset-v4-0-a955b1c8b119@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Jonas Karlman <jonas@kwiboo.se>, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795690985; l=3990;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=TORRPWXC3iBgtHVwjl5GcrAeI92+toU+vqsHJf1bUUM=;
 b=q5SYi+x00w+QhyqAcfCqPAUb8vbpICcWTRhLfaSkZboRS6ZSlxE+icwYxvBQbjK7XOZ9xVbJy
 wsdbWt9z9ZxBBmQV209az8OsZcNacxbuBs7Uqh9p1WQqUQD6RTBuWv5
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Ignore interrupts the decoder did not raise and report the error type.

After a bus, stream or ASO error or a timeout, soft-reset the decoder
before its buffers go back to userspace: it may still be active.
If only its input buffer ran empty, the decoder stays enabled; a later
interrupt or the driver's watchdog then ends the job.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../platform/verisilicon/rockchip_vpu2_regs.h      |  4 +++
 .../media/platform/verisilicon/rockchip_vpu_hw.c   | 40 +++++++++++++++++++---
 2 files changed, 40 insertions(+), 4 deletions(-)

diff --git a/drivers/media/platform/verisilicon/rockchip_vpu2_regs.h b/drivers/media/platform/verisilicon/rockchip_vpu2_regs.h
index 49e40889545b..d11c84a18161 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu2_regs.h
+++ b/drivers/media/platform/verisilicon/rockchip_vpu2_regs.h
@@ -347,6 +347,10 @@
 #define     VDPU_REG_INTERRUPT_DEC_RDY_INT		BIT(4)
 #define     VDPU_REG_INTERRUPT_DEC_IRQ_DIS		BIT(1)
 #define     VDPU_REG_INTERRUPT_DEC_IRQ			BIT(0)
+#define     VDPU_REG_INTERRUPT_DEC_ERRORS		(VDPU_REG_INTERRUPT_DEC_TIMEOUT | \
+						 VDPU_REG_INTERRUPT_DEC_ERROR_INT | \
+						 VDPU_REG_INTERRUPT_DEC_ASO_INT | \
+						 VDPU_REG_INTERRUPT_DEC_BUS_INT)
 #define VDPU_REG_AXI_CTRL			0x0e0
 #define     VDPU_REG_AXI_DEC_SEL			BIT(23)
 #define     VDPU_REG_CONFIG_DEC_DATA_DISC_E		BIT(22)
diff --git a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
index 4bc1bdb41c70..69552195c974 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
@@ -7,6 +7,7 @@
  */
 
 #include <linux/clk.h>
+#include <linux/iopoll.h>
 
 #include "hantro.h"
 #include "hantro_jpeg.h"
@@ -384,17 +385,49 @@ static irqreturn_t rockchip_vpu1_vepu_irq(int irq, void *dev_id)
 	return IRQ_HANDLED;
 }
 
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
 	enum vb2_buffer_state state;
-	u32 status;
+	u32 status, en;
 
 	status = vdpu_read(vpu, VDPU_REG_INTERRUPT);
+	if (!(status & VDPU_REG_INTERRUPT_DEC_IRQ))
+		return IRQ_NONE;
+
+	/* Read DEC_E with the status, before the clear. */
+	en = vdpu_read(vpu, VDPU_REG_EN_FLAGS);
+	vdpu_write(vpu, 0, VDPU_REG_INTERRUPT);
+
 	state = (status & VDPU_REG_INTERRUPT_DEC_RDY_INT) ?
 		VB2_BUF_STATE_DONE : VB2_BUF_STATE_ERROR;
+	if (state == VB2_BUF_STATE_ERROR) {
+		if (status & VDPU_REG_INTERRUPT_DEC_BUS_INT)
+			dev_warn_ratelimited(vpu->dev, "bus error detected.\n");
+		if (status & VDPU_REG_INTERRUPT_DEC_ERROR_INT)
+			dev_warn_ratelimited(vpu->dev, "decode error detected.\n");
+		if (status & VDPU_REG_INTERRUPT_DEC_TIMEOUT)
+			dev_warn_ratelimited(vpu->dev, "frame decode timed out.\n");
+
+		/* Buffer empty: a later interrupt or the watchdog ends the job. */
+		if (!(status & VDPU_REG_INTERRUPT_DEC_ERRORS) &&
+		    (en & VDPU_REG_INTERRUPT_DEC_E))
+			return IRQ_HANDLED;
+
+		rockchip_vpu2_dec_soft_reset(vpu);
+	}
 
-	vdpu_write(vpu, 0, VDPU_REG_INTERRUPT);
 	vdpu_write(vpu, 0, VDPU_REG_AXI_CTRL);
 
 	hantro_irq_done(vpu, state);
@@ -482,8 +515,7 @@ static void rockchip_vpu2_dec_reset(struct hantro_ctx *ctx)
 	struct hantro_dev *vpu = ctx->dev;
 
 	vdpu_write(vpu, VDPU_REG_INTERRUPT_DEC_IRQ_DIS, VDPU_REG_INTERRUPT);
-	vdpu_write(vpu, 0, VDPU_REG_EN_FLAGS);
-	vdpu_write(vpu, 1, VDPU_REG_SOFT_RESET);
+	rockchip_vpu2_dec_soft_reset(vpu);
 }
 
 static void rockchip_vpu2_enc_reset(struct hantro_ctx *ctx)

-- 
2.55.0

