From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Fri, 27 Nov 2026 21:26:26 +0100
Subject: [PATCH 3/5] media: qcom: camss: vfe: call vb2_buffer_done()
 outside output_lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-camss-titan17x-fixes-v1-3-541ab39e5889@gmail.com>
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
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795811183; l=3255;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=JHsklOJs0XN6Ha8eYoDzxlDGyKqFWMC+hYh/5EQBjw4=;
 b=gB/RF/E6kqv9LkHBwQGonuPUaGR2NVRrWtSedwy41llPcg9fXGbtPTVm5S1S/1p9s5LUyDyjz
 wusERQloLuvA7ypweyNasxf2cOC1Stt7PfURdPkcFmiZLhO56/sgU7F
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vfe_flush_buffers() currently invokes vb2_buffer_done() while holding
vfe->output_lock, unlike vfe_buf_done(). Returning buffers to vb2 can
re-enter driver callbacks or run user hooks under an IRQ-safe spinlock.

Splice pending_bufs into a local list, detach active buffer pointers and
reset gen2.active_num under output_lock, and complete the buffers after
releasing output_lock. Also drop the now-unused vfe_buf_flush_pending()
helper.

Fixes: ff11faad8a9e ("media: qcom: camss: vfe: Clear active buffer pointers after flushing")
Cc: stable@vger.kernel.org
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-vfe.c | 56 +++++++++++++--------------
 1 file changed, 26 insertions(+), 30 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-vfe.c b/drivers/media/platform/qcom/camss/camss-vfe.c
index b5a8196c9145163dfa3ee1af549a4684901e2fa7..b01c7c919de459bdb6581dba81c15a176e551208 100644
--- a/drivers/media/platform/qcom/camss/camss-vfe.c
+++ b/drivers/media/platform/qcom/camss/camss-vfe.c
@@ -757,23 +757,6 @@ void vfe_buf_add_pending(struct vfe_output *output,
 	list_add_tail(&buffer->queue, &output->pending_bufs);
 }
 
-/*
- * vfe_buf_flush_pending - Flush all pending buffers.
- * @output: VFE output
- * @state: vb2 buffer state
- */
-static void vfe_buf_flush_pending(struct vfe_output *output,
-				  enum vb2_buffer_state state)
-{
-	struct camss_buffer *buf;
-	struct camss_buffer *t;
-
-	list_for_each_entry_safe(buf, t, &output->pending_bufs, queue) {
-		vb2_buffer_done(&buf->vb.vb2_buf, state);
-		list_del(&buf->queue);
-	}
-}
-
 int vfe_put_output(struct vfe_line *line)
 {
 	struct vfe_device *vfe = to_vfe(line);
@@ -1215,31 +1198,44 @@ int vfe_flush_buffers(struct camss_video *vid,
 	struct vfe_line *line = container_of(vid, struct vfe_line, video_out);
 	struct vfe_device *vfe = to_vfe(line);
 	struct vfe_output *output;
+	struct camss_buffer *buf, *t;
+	struct camss_buffer *b0, *b1, *blast;
+	LIST_HEAD(local_pending);
 	unsigned long flags;
 
 	output = &line->output;
 
 	spin_lock_irqsave(&vfe->output_lock, flags);
 
-	vfe_buf_flush_pending(output, state);
+	list_splice_init(&output->pending_bufs, &local_pending);
 
-	if (output->buf[0]) {
-		vb2_buffer_done(&output->buf[0]->vb.vb2_buf, state);
-		output->buf[0] = NULL;
-	}
+	b0 = output->buf[0];
+	output->buf[0] = NULL;
 
-	if (output->buf[1]) {
-		vb2_buffer_done(&output->buf[1]->vb.vb2_buf, state);
-		output->buf[1] = NULL;
-	}
+	b1 = output->buf[1];
+	output->buf[1] = NULL;
 
-	if (output->last_buffer) {
-		vb2_buffer_done(&output->last_buffer->vb.vb2_buf, state);
-		output->last_buffer = NULL;
-	}
+	blast = output->last_buffer;
+	output->last_buffer = NULL;
+
+	output->gen2.active_num = 0;
 
 	spin_unlock_irqrestore(&vfe->output_lock, flags);
 
+	list_for_each_entry_safe(buf, t, &local_pending, queue) {
+		list_del(&buf->queue);
+		vb2_buffer_done(&buf->vb.vb2_buf, state);
+	}
+
+	if (b0)
+		vb2_buffer_done(&b0->vb.vb2_buf, state);
+
+	if (b1)
+		vb2_buffer_done(&b1->vb.vb2_buf, state);
+
+	if (blast)
+		vb2_buffer_done(&blast->vb.vb2_buf, state);
+
 	return 0;
 }
 

-- 
2.47.3

