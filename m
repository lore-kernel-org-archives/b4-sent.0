From: Sergei Khomenkov <shomenkow@gmail.com>
Date: Tue, 10 Nov 2026 15:41:44 +0300
Subject: [PATCH v2 1/3] media: verisilicon: stop the VEPU1 JPEG encoder
 after an unfinished frame
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hantro-buflimit-v2-1-ff7790def9fc@gmail.com>
References: <20261110-hantro-buflimit-v2-0-ff7790def9fc@gmail.com>
In-Reply-To: <20261110-hantro-buflimit-v2-0-ff7790def9fc@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Chen-Yu Tsai <wenst@chromium.org>, 
 Hugues Fruchet <hugues.fruchet@foss.st.com>, linux-media@vger.kernel.org, 
 linux-rockchip@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sergei Khomenkov <shomenkow@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794314506; l=3084;
 i=shomenkow@gmail.com; s=20261104; h=from:subject:message-id;
 bh=YHxh7pOb2K0qV8FuiClIzJFZEkYN6AmWKtxTo6KANAk=;
 b=uZxJGwVHOcWH3jWGfP8L1xLnMi7Sr/GSOL1WEVuW+C2Pi3WQsnfDvXgw2aoDxwWAs2rHNKOSz
 9v92gCbP2MfBnlUnTVUb6/Ye4SVCdcNY0Jwxh/vRozR2gp33+BJcSbd
X-Developer-Key: i=shomenkow@gmail.com; a=ed25519;
 pk=FwuHDVe7aiISDMLmQEcMC+RflEIJ6kEp/ekwznWXmI8=
X-Endpoint-Received: by B4 Relay for shomenkow@gmail.com/20261104 with auth_id=1409
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the JPEG stream reaches the stream buffer limit, the H1 raises a
buffer-full interrupt and pauses with the enable bit of H1_REG_ENC_CTRL
still set. rockchip_vpu1_vepu_irq() does not stop it, so the next job is
programmed into the paused encoder and times out.

Clear only the enable bit when an interrupt does not report a finished
frame, and warn (rate limited) about each fault bit that is set, as
hantro_g2_irq() does.

Found with an LLM coding assistant while porting mainline Linux to a
Rockchip RK3026 board; the assistant also drafted this change. Tested
on that board, with the next patch applied: a frame that does not fit
now ends with the ERROR flag and one interrupt, and the following jobs
complete. Not tested on other SoCs.

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Cc: stable@vger.kernel.org
Signed-off-by: Sergei Khomenkov <shomenkow@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_h1_regs.h  |  4 ++++
 drivers/media/platform/verisilicon/rockchip_vpu_hw.c | 18 ++++++++++++++++++
 2 files changed, 22 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro_h1_regs.h b/drivers/media/platform/verisilicon/hantro_h1_regs.h
index 8650cc489392..a7f18683dac1 100644
--- a/drivers/media/platform/verisilicon/hantro_h1_regs.h
+++ b/drivers/media/platform/verisilicon/hantro_h1_regs.h
@@ -11,6 +11,10 @@
 
 /* Encoder registers. */
 #define H1_REG_INTERRUPT				0x004
+#define     H1_REG_INTERRUPT_TIMEOUT			BIT(6)
+#define     H1_REG_INTERRUPT_BUFFER_FULL		BIT(5)
+#define     H1_REG_INTERRUPT_RESET			BIT(4)
+#define     H1_REG_INTERRUPT_BUS_ERROR			BIT(3)
 #define     H1_REG_INTERRUPT_FRAME_RDY			BIT(2)
 #define     H1_REG_INTERRUPT_DIS_BIT			BIT(1)
 #define     H1_REG_INTERRUPT_BIT			BIT(0)
diff --git a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
index 02673be9878e..d201b058e5e8 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
@@ -376,6 +376,24 @@ static irqreturn_t rockchip_vpu1_vepu_irq(int irq, void *dev_id)
 	state = (status & H1_REG_INTERRUPT_FRAME_RDY) ?
 		VB2_BUF_STATE_DONE : VB2_BUF_STATE_ERROR;
 
+	if (status & H1_REG_INTERRUPT_BUFFER_FULL)
+		dev_warn_ratelimited(vpu->dev, "stream buffer full\n");
+	if (status & H1_REG_INTERRUPT_BUS_ERROR)
+		dev_warn_ratelimited(vpu->dev, "bus error detected\n");
+	if (status & H1_REG_INTERRUPT_TIMEOUT)
+		dev_warn_ratelimited(vpu->dev, "frame encode timed out\n");
+	if (status & H1_REG_INTERRUPT_RESET)
+		dev_warn_ratelimited(vpu->dev, "encoder reset\n");
+
+	/* After a buffer full the encoder pauses, still enabled: stop it. */
+	if (!(status & H1_REG_INTERRUPT_FRAME_RDY)) {
+		u32 ctrl = vepu_read(vpu, H1_REG_ENC_CTRL);
+
+		if (ctrl & H1_REG_ENC_CTRL_EN_BIT)
+			vepu_write(vpu, ctrl & ~H1_REG_ENC_CTRL_EN_BIT,
+				   H1_REG_ENC_CTRL);
+	}
+
 	vepu_write(vpu, 0, H1_REG_INTERRUPT);
 	vepu_write(vpu, 0, H1_REG_AXI_CTRL);
 

-- 
2.53.0

