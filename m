From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:17:33 +0000
Subject: [PATCH 3/5] media: verisilicon: Reset the Rockchip encoder cores
 on timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hantro-robust-v1-3-6b6269c05bfa@gmail.com>
References: <20261110-hantro-robust-v1-0-6b6269c05bfa@gmail.com>
In-Reply-To: <20261110-hantro-robust-v1-0-6b6269c05bfa@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Andrzej Pietrasiewicz <andrzej.p@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295050; l=3365;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Ii56p0k233FnBuEWff4kj2GpZgLraSVcrE/YwPM2NZ8=;
 b=gvRF3RYSL3I78/jmqutif7iFPrK/2wtDBeN8PTyTuznOd0brf54ppGYrxucEH87bv1WSi/g9j
 8ndax84LyTiAf7w39CtfRb99VJN0uYyVUTR4wlPoqOoY08r2UspBpnn
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a job timeout, the Rockchip VEPU1 and VEPU2 reset operations mask the
interrupt and clear the encode enable and AXI control registers. That
only stops a core that is still responsive. On RK3588, when a VEPU121
core reads an IOVA that isn't mapped, the IOMMU reports a page fault and
the core never becomes idle again: its AXI transactions stay
outstanding, the IOMMU can't be stalled anymore ("Enable stall request
timed out", then "Disable paging request timed out" on runtime
suspend), every later job times out as well, and unbinding the driver
can lock up the system.

The driver already gets the optional reset lines of the device and
deasserts them at probe. Pulse them in the encoder reset operations,
after stopping the core through its registers, to return it to a clean
idle state. The clocks are still enabled at that point, as the job that
timed out holds them. This is a no-op on device trees that don't
describe the resets, which is the case for all of them so far.

The Rockchip BSP MPP driver resets these cores the same way, through
their AXI and AHB reset lines.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../media/platform/verisilicon/rockchip_vpu_hw.c   | 30 ++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
index 02673be9878e..0dced7515833 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
@@ -7,6 +7,7 @@
  */
 
 #include <linux/clk.h>
+#include <linux/delay.h>
 
 #include "hantro.h"
 #include "hantro_jpeg.h"
@@ -468,6 +469,33 @@ static void rk3066_vpu_dec_reset(struct hantro_ctx *ctx)
 	vdpu_write(vpu, G1_REG_CONFIG_DEC_CLK_GATE_E, G1_REG_CONFIG);
 }
 
+/*
+ * Stopping the encoder through its registers isn't enough when it is stuck
+ * on the bus, for instance after a translation fault in its IOMMU: it keeps
+ * AXI transactions outstanding and never becomes idle, which also prevents
+ * the IOMMU from stalling. Pulse the reset lines of the core, if the device
+ * tree describes them, to return it to its idle state.
+ */
+static void rockchip_vpu_enc_hw_reset(struct hantro_dev *vpu)
+{
+	int ret;
+
+	if (!vpu->resets)
+		return;
+
+	ret = reset_control_assert(vpu->resets);
+	if (ret) {
+		dev_warn(vpu->dev, "Failed to assert resets: %d\n", ret);
+		return;
+	}
+
+	udelay(5);
+
+	ret = reset_control_deassert(vpu->resets);
+	if (ret)
+		dev_err(vpu->dev, "Failed to deassert resets: %d\n", ret);
+}
+
 static void rockchip_vpu1_enc_reset(struct hantro_ctx *ctx)
 {
 	struct hantro_dev *vpu = ctx->dev;
@@ -475,6 +503,7 @@ static void rockchip_vpu1_enc_reset(struct hantro_ctx *ctx)
 	vepu_write(vpu, H1_REG_INTERRUPT_DIS_BIT, H1_REG_INTERRUPT);
 	vepu_write(vpu, 0, H1_REG_ENC_CTRL);
 	vepu_write(vpu, 0, H1_REG_AXI_CTRL);
+	rockchip_vpu_enc_hw_reset(vpu);
 }
 
 static void rockchip_vpu2_dec_reset(struct hantro_ctx *ctx)
@@ -493,6 +522,7 @@ static void rockchip_vpu2_enc_reset(struct hantro_ctx *ctx)
 	vepu_write(vpu, VEPU_REG_INTERRUPT_DIS_BIT, VEPU_REG_INTERRUPT);
 	vepu_write(vpu, 0, VEPU_REG_ENCODE_START);
 	vepu_write(vpu, 0, VEPU_REG_AXI_CTRL);
+	rockchip_vpu_enc_hw_reset(vpu);
 }
 
 /*

-- 
2.55.0

