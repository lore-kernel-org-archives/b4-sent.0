From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Fri, 27 Nov 2026 21:26:27 +0100
Subject: [PATCH 4/5] media: qcom: camss: vfe-17x: use vfe_buf_done() and
 defer WM enable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-camss-titan17x-fixes-v1-4-541ab39e5889@gmail.com>
References: <20261127-camss-titan17x-fixes-v1-0-541ab39e5889@gmail.com>
In-Reply-To: <20261127-camss-titan17x-fixes-v1-0-541ab39e5889@gmail.com>
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Robert Foss <rfoss@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Andrey Konovalov <andrey.konovalov@linaro.org>, 
 Atanas Filipov <atanas.filipov@oss.qualcomm.com>, 
 Milen Mitkov <quic_mmitkov@quicinc.com>, 
 Gjorgji Rosikopulos <quic_grosikop@quicinc.com>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795811183; l=5143;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=QKzdaNX0ejvQy/NzKMFAMcwYp9tSII3/DNvIHJEEzdI=;
 b=pQueruEt74bFFnMxkCvtQ5ueakqF9H0/QMxGkxWE12XedkI4Fw8sSWzhN9jXy2Mqu0TUBqbBn
 3ceDvy+PlMaC5d9kIHr+CxSyJmLlcMi4tbQ6rBhDHgB3FRPeIaXdeBQ
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

camss-vfe-17x keeps a private copy of vfe_buf_done() in
vfe_isr_wm_done() that skips calling reg_update() after updating the
write master address, preventing the newly queued buffer address from
being latched for the next frame.

Reuse the shared vfe_buf_done() helper (after validating
wm_output_map[wm] != VFE_LINE_NONE before indexing vfe->line[]),
explicitly initialize the write master framedrop and IRQ subsample
registers to 0/1 in vfe_wm_start(), and defer enabling WM_CFG_EN until
vfe_wm_update() programs IMAGE_ADDR and FRAME_INC.

Fixes: 7319cdf189bb ("media: camss: Add support for VFE hardware version Titan 170")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-vfe-17x.c | 66 +++++------------------
 drivers/media/platform/qcom/camss/camss-vfe.c     |  5 +-
 2 files changed, 16 insertions(+), 55 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-vfe-17x.c b/drivers/media/platform/qcom/camss/camss-vfe-17x.c
index 304dafb39ad5121ade50cf278e0ada53f5e5203e..9aceea8609753fe3a8015c41398bfbc4e769ea9d 100644
--- a/drivers/media/platform/qcom/camss/camss-vfe-17x.c
+++ b/drivers/media/platform/qcom/camss/camss-vfe-17x.c
@@ -249,10 +249,14 @@ static void vfe_wm_start(struct vfe_device *vfe, u8 wm, struct vfe_line *line)
 	val = WM_STRIDE_DEFAULT_STRIDE;
 	writel_relaxed(val, vfe->base + VFE_BUS_WM_STRIDE(wm));
 
-	/* Enable WM */
-	val = 1 << WM_CFG_EN |
-	      MODE_MIPI_RAW << WM_CFG_MODE;
-	writel_relaxed(val, vfe->base + VFE_BUS_WM_CFG(wm));
+	/* No dropped frames, one IRQ per frame */
+	writel_relaxed(0, vfe->base + VFE_BUS_WM_FRAMEDROP_PERIOD(wm));
+	writel_relaxed(1, vfe->base + VFE_BUS_WM_FRAMEDROP_PATTERN(wm));
+	writel_relaxed(0, vfe->base + VFE_BUS_WM_IRQ_SUBSAMPLE_PERIOD(wm));
+	writel_relaxed(1, vfe->base + VFE_BUS_WM_IRQ_SUBSAMPLE_PATTERN(wm));
+
+	/* Ensure WM configuration completes before buffer enqueue */
+	wmb();
 }
 
 static void vfe_wm_stop(struct vfe_device *vfe, u8 wm)
@@ -270,6 +274,10 @@ static void vfe_wm_update(struct vfe_device *vfe, u8 wm, u32 addr,
 
 	writel_relaxed(addr, vfe->base + VFE_BUS_WM_IMAGE_ADDR(wm));
 	writel_relaxed(stride * pix->height, vfe->base + VFE_BUS_WM_FRAME_INC(wm));
+	/* Ensure IMAGE_ADDR and FRAME_INC land before enabling WM_CFG */
+	wmb();
+	writel_relaxed((1 << WM_CFG_EN) | (MODE_MIPI_RAW << WM_CFG_MODE),
+		       vfe->base + VFE_BUS_WM_CFG(wm));
 }
 
 static void vfe_reg_update(struct vfe_device *vfe, enum vfe_line_id line_id)
@@ -475,55 +483,7 @@ static void vfe_isr_reg_update(struct vfe_device *vfe, enum vfe_line_id line_id)
  */
 static void vfe_isr_wm_done(struct vfe_device *vfe, u8 wm)
 {
-	struct vfe_line *line = &vfe->line[vfe->wm_output_map[wm]];
-	struct camss_buffer *ready_buf;
-	struct vfe_output *output;
-	unsigned long flags;
-	u32 index;
-	u64 ts = ktime_get_ns();
-
-	spin_lock_irqsave(&vfe->output_lock, flags);
-
-	if (vfe->wm_output_map[wm] == VFE_LINE_NONE) {
-		dev_err_ratelimited(vfe->camss->dev,
-				    "Received wm done for unmapped index\n");
-		goto out_unlock;
-	}
-	output = &vfe->line[vfe->wm_output_map[wm]].output;
-
-	ready_buf = output->buf[0];
-	if (!ready_buf) {
-		dev_err_ratelimited(vfe->camss->dev,
-				    "Missing ready buf %d!\n", output->state);
-		goto out_unlock;
-	}
-
-	ready_buf->vb.vb2_buf.timestamp = ts;
-	if (line->sof_seq)
-		ready_buf->vb.sequence = atomic_read(line->sof_seq);
-	else
-		ready_buf->vb.sequence = output->sequence++;
-
-	index = 0;
-	output->buf[0] = output->buf[1];
-	if (output->buf[0])
-		index = 1;
-
-	output->buf[index] = vfe_buf_get_pending(output);
-
-	if (output->buf[index])
-		vfe_wm_update(vfe, output->wm_idx[0], output->buf[index]->addr[0], line);
-	else
-		output->gen2.active_num--;
-
-	spin_unlock_irqrestore(&vfe->output_lock, flags);
-
-	vb2_buffer_done(&ready_buf->vb.vb2_buf, VB2_BUF_STATE_DONE);
-
-	return;
-
-out_unlock:
-	spin_unlock_irqrestore(&vfe->output_lock, flags);
+	vfe_buf_done(vfe, wm);
 }
 
 static const struct vfe_isr_ops vfe_isr_ops_170 = {
diff --git a/drivers/media/platform/qcom/camss/camss-vfe.c b/drivers/media/platform/qcom/camss/camss-vfe.c
index b01c7c919de459bdb6581dba81c15a176e551208..71f3731f05f10194e36a5802065fb82f751baa16 100644
--- a/drivers/media/platform/qcom/camss/camss-vfe.c
+++ b/drivers/media/platform/qcom/camss/camss-vfe.c
@@ -432,8 +432,8 @@ u32 vfe_hw_version(struct vfe_device *vfe)
  */
 void vfe_buf_done(struct vfe_device *vfe, int wm)
 {
-	struct vfe_line *line = &vfe->line[vfe->wm_output_map[wm]];
 	const struct vfe_hw_ops *ops = vfe->res->hw_ops;
+	struct vfe_line *line;
 	struct camss_buffer *ready_buf;
 	struct vfe_output *output;
 	unsigned long flags;
@@ -447,7 +447,8 @@ void vfe_buf_done(struct vfe_device *vfe, int wm)
 				    "Received wm done for unmapped index\n");
 		goto out_unlock;
 	}
-	output = &vfe->line[vfe->wm_output_map[wm]].output;
+	line = &vfe->line[vfe->wm_output_map[wm]];
+	output = &line->output;
 
 	ready_buf = output->buf[0];
 	if (!ready_buf) {

-- 
2.47.3

