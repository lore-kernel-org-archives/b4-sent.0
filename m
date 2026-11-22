From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:13:16 +0000
Subject: [PATCH 1/2] media: venus: Signal end-of-stream with a mapped
 buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-venus-eos-seek-v1-1-2e38912c7cf9@enser.io>
References: <20261122-b4-venus-eos-seek-v1-0-2e38912c7cf9@enser.io>
In-Reply-To: <20261122-b4-venus-eos-seek-v1-0-2e38912c7cf9@enser.io>
To: Vikash Garodia <vikash.garodia@oss.qualcomm.com>, 
 Dikshita Agarwal <dikshita.agarwal@oss.qualcomm.com>
Cc: Bryan O'Donoghue <bod@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Stanimir Varbanov <stanimir.varbanov@linaro.org>, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324396; l=7783;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=LYIKmiVYhHueVSkCwtia7v3TSHQG+liZ0JL1pDnQfi4=;
 b=a3/YjhjvV+YKznhQ1N4gXGROGMkDfK5F5tNCTOlXV1WdotcXcGofh0jgWin0pvVoXbi9KAgw8
 7jrDfZV0citAXFTjM1uCnnIhRPKFL0nwbXWkU+idcfp5q9tcWmNWEV2
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

V4L2_ENC_CMD_STOP and V4L2_DEC_CMD_STOP signal end-of-stream by queueing
an empty input buffer at the made-up device address 0xdeadb000. The
SDM845 firmware on a OnePlus 6T (VIDEO.VE.5.2-00050-PROD-1) rejects it:

  qcom-venus aa00000.video-codec: session error: event id:1001 (deadb000)

and the LAST buffer never comes back. An encoder session then goes on to
session error 1006 and a system error whose recovery fails ("recovery
failed to init HFI"), and the encoder is unusable until reboot. A decoder
leaves the client draining forever: ffmpeg and mpv with v4l2m2m decoded
1188 of 1200 frames of a clip, then hung at end of file.

A zero-length buffer queued by userspace reaches the firmware with the
EOS flag at its real, mapped address, and is accepted. Do the same for
STOP: allocate one small buffer per instance the first time STOP is
issued, against the core device like the internal buffers, and free it
once the session has been destroyed at close. The IRIS2 branch for old
firmware, which needs address 0, is unchanged.

Tested on a OnePlus 6T with this change on the postmarketOS sdm845
kernel (6.18): three 640x480 H.264 encodes in one boot, each drained
with ENC_CMD_STOP, all reach end-of-stream with a valid stream; decoding
one of them returns all 90 frames and end-of-stream; no session or
system errors are logged.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Fixes: e69b987a9759 ("media: venus: reimplement decoder stop command")
Fixes: 7493db46e4c4 ("venus: venc: add handling for VIDIOC_ENCODER_CMD")
Signed-off-by: EMCP333 <emcp@enser.io>
---
 drivers/media/platform/qcom/venus/core.h    |  4 ++++
 drivers/media/platform/qcom/venus/helpers.c | 35 +++++++++++++++++++++++++++++
 drivers/media/platform/qcom/venus/helpers.h |  3 +++
 drivers/media/platform/qcom/venus/vdec.c    | 11 ++++++---
 drivers/media/platform/qcom/venus/venc.c    |  7 +++++-
 5 files changed, 56 insertions(+), 4 deletions(-)

diff --git a/drivers/media/platform/qcom/venus/core.h b/drivers/media/platform/qcom/venus/core.h
index 93fa77f058..f521bccfe3 100644
--- a/drivers/media/platform/qcom/venus/core.h
+++ b/drivers/media/platform/qcom/venus/core.h
@@ -463,6 +463,8 @@ enum venus_inst_modes {
  * @drain_active:	Drain sequence is in progress
  * @flags:	bitmask flags describing current instance mode
  * @dpb_ids:	DPB buffer ID's
+ * @eos_va:	CPU address of the empty buffer that carries end-of-stream
+ * @eos_da:	device address of that buffer
  */
 struct venus_inst {
 	struct list_head list;
@@ -534,6 +536,8 @@ struct venus_inst {
 	bool drain_active;
 	enum venus_inst_modes flags;
 	struct ida dpb_ids;
+	void *eos_va;
+	dma_addr_t eos_da;
 };
 
 #define IS_V1(core)	((core)->res->hfi_version == HFI_VERSION_1XX)
diff --git a/drivers/media/platform/qcom/venus/helpers.c b/drivers/media/platform/qcom/venus/helpers.c
index 59eee3dd9e..e0bd2b0478 100644
--- a/drivers/media/platform/qcom/venus/helpers.c
+++ b/drivers/media/platform/qcom/venus/helpers.c
@@ -3,9 +3,11 @@
  * Copyright (c) 2012-2016, The Linux Foundation. All rights reserved.
  * Copyright (C) 2017 Linaro Ltd.
  */
+#include <linux/dma-mapping.h>
 #include <linux/idr.h>
 #include <linux/list.h>
 #include <linux/mutex.h>
+#include <linux/sizes.h>
 #include <linux/slab.h>
 #include <linux/kernel.h>
 #include <media/videobuf2-dma-contig.h>
@@ -1541,6 +1543,39 @@ void venus_helper_buffers_done(struct venus_inst *inst, unsigned int type,
 }
 EXPORT_SYMBOL_GPL(venus_helper_buffers_done);
 
+#define VENUS_EOS_BUF_SIZE	SZ_4K
+
+/*
+ * The STOP commands signal end-of-stream with an empty input buffer. Give it
+ * a real, mapped address, as a zero-length buffer queued by userspace has:
+ * SDM845 firmware rejects a made-up one (session error 1001), and the LAST
+ * buffer then never comes back.
+ */
+int venus_helper_eos_buf(struct venus_inst *inst, struct hfi_frame_data *fdata)
+{
+	if (!inst->eos_va) {
+		inst->eos_va = dma_alloc_attrs(inst->core->dev, VENUS_EOS_BUF_SIZE,
+					       &inst->eos_da, GFP_KERNEL, 0);
+		if (!inst->eos_va)
+			return -ENOMEM;
+	}
+	fdata->device_addr = inst->eos_da;
+	fdata->alloc_len = VENUS_EOS_BUF_SIZE;
+	fdata->filled_len = 0;
+	return 0;
+}
+EXPORT_SYMBOL_GPL(venus_helper_eos_buf);
+
+void venus_helper_free_eos(struct venus_inst *inst)
+{
+	if (!inst->eos_va)
+		return;
+	dma_free_attrs(inst->core->dev, VENUS_EOS_BUF_SIZE, inst->eos_va,
+		       inst->eos_da, 0);
+	inst->eos_va = NULL;
+}
+EXPORT_SYMBOL_GPL(venus_helper_free_eos);
+
 void venus_helper_vb2_stop_streaming(struct vb2_queue *q)
 {
 	struct venus_inst *inst = vb2_get_drv_priv(q);
diff --git a/drivers/media/platform/qcom/venus/helpers.h b/drivers/media/platform/qcom/venus/helpers.h
index 358e4f39c9..6acae43459 100644
--- a/drivers/media/platform/qcom/venus/helpers.h
+++ b/drivers/media/platform/qcom/venus/helpers.h
@@ -10,6 +10,7 @@
 
 struct venus_inst;
 struct venus_core;
+struct hfi_frame_data;
 
 bool venus_helper_check_codec(struct venus_inst *inst, u32 v4l2_pixfmt);
 struct vb2_v4l2_buffer *venus_helper_find_buf(struct venus_inst *inst,
@@ -71,4 +72,6 @@ int venus_helper_get_profile_level(struct venus_inst *inst, u32 *profile, u32 *l
 int venus_helper_set_profile_level(struct venus_inst *inst, u32 profile, u32 level);
 int venus_helper_set_stride(struct venus_inst *inst, unsigned int aligned_width,
 			    unsigned int aligned_height);
+int venus_helper_eos_buf(struct venus_inst *inst, struct hfi_frame_data *fdata);
+void venus_helper_free_eos(struct venus_inst *inst);
 #endif
diff --git a/drivers/media/platform/qcom/venus/vdec.c b/drivers/media/platform/qcom/venus/vdec.c
index 6a43ea191d..a49acef5db 100644
--- a/drivers/media/platform/qcom/venus/vdec.c
+++ b/drivers/media/platform/qcom/venus/vdec.c
@@ -574,10 +574,13 @@ vdec_decoder_cmd(struct file *file, void *fh, struct v4l2_decoder_cmd *cmd)
 		 * avoids misapplying this quirk and breaking VP9 decode on SC7280.
 		 */
 
-		if (IS_IRIS2(inst->core) && is_fw_rev_or_older(inst->core, 1, 0, 87))
+		if (IS_IRIS2(inst->core) && is_fw_rev_or_older(inst->core, 1, 0, 87)) {
 			fdata.device_addr = 0;
-		else
-			fdata.device_addr = 0xdeadb000;
+		} else {
+			ret = venus_helper_eos_buf(inst, &fdata);
+			if (ret)
+				goto unlock;
+		}
 
 		ret = hfi_session_process_buf(inst, &fdata);
 
@@ -1762,6 +1765,8 @@ static int vdec_close(struct file *file)
 	vdec_pm_get(inst);
 	cancel_work_sync(&inst->delayed_process_work);
 	venus_close_common(inst, file);
+	/* The session is destroyed, so the firmware can no longer touch it. */
+	venus_helper_free_eos(inst);
 	ida_destroy(&inst->dpb_ids);
 	vdec_pm_put(inst, false);
 
diff --git a/drivers/media/platform/qcom/venus/venc.c b/drivers/media/platform/qcom/venus/venc.c
index 79acf7c1ec..9c2b602568 100644
--- a/drivers/media/platform/qcom/venus/venc.c
+++ b/drivers/media/platform/qcom/venus/venc.c
@@ -548,7 +548,10 @@ venc_encoder_cmd(struct file *file, void *fh, struct v4l2_encoder_cmd *cmd)
 
 		fdata.buffer_type = HFI_BUFFER_INPUT;
 		fdata.flags |= HFI_BUFFERFLAG_EOS;
-		fdata.device_addr = 0xdeadb000;
+
+		ret = venus_helper_eos_buf(inst, &fdata);
+		if (ret)
+			goto unlock;
 
 		ret = hfi_session_process_buf(inst, &fdata);
 
@@ -1538,6 +1541,8 @@ static int venc_close(struct file *file)
 
 	venc_pm_get(inst);
 	venus_close_common(inst, file);
+	/* The session is destroyed, so the firmware can no longer touch it. */
+	venus_helper_free_eos(inst);
 	inst->enc_state = VENUS_ENC_STATE_DEINIT;
 	venc_pm_put(inst, false);
 

-- 
2.47.3

