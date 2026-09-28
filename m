From: David Heidelberg <david@ixit.cz>
Date: Mon, 28 Sep 2026 23:40:15 +0200
Subject: [PATCH 2/2] media: venus: vdec: Start capture after a seek that
 streams CAPTURE first
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-venus-vdec-eos-v1-2-6e9eb3ce9849@ixit.cz>
References: <20260928-venus-vdec-eos-v1-0-6e9eb3ce9849@ixit.cz>
In-Reply-To: <20260928-venus-vdec-eos-v1-0-6e9eb3ce9849@ixit.cz>
To: Vikash Garodia <vikash.garodia@oss.qualcomm.com>, 
 Dikshita Agarwal <dikshita.agarwal@oss.qualcomm.com>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Stanimir Varbanov <stanimir.varbanov@linaro.org>
Cc: Mauro Carvalho Chehab <mchehab+samsung@kernel.org>, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2585; i=david@ixit.cz;
 h=from:subject:message-id; bh=frYE/kM7Q7fbMjI7Ug1XRcOz9fBQyhrocMHXusn0u/g=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqut7D4QVywzZIE4/C1hFXXWuLwBE1O0jIBEexx
 7r08vaAuZqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarrewwAKCRBgAj/E00kg
 clPUEACZLj+T67hNpIoyn0r3jdBl2zQ32L1XQt8nsqammZqAb5GRm9k3rMB2DPiJyaoGsOdRqsd
 AHL2f2/+kS7wt/YvwfHm9gCROGCXSKk8xqk3wd/Z/DGBtX+/QWTSbcmXlb0onJcM+FHxTXJ14Ko
 nJJ+eJKEcM74DrWrKlBBY79tMLS3JQEa5OHcor1LOat+vVDM9tsPro3aVjyPxZe16aidtdMJXrw
 TyA7mvmoPLTBeD64AnkobEa1Gzfc9vaU5GEUGPP2cHHSxPH/BVMfJmzG8IcnNL50Xlclk38aWFo
 DCblsn6l1qKORXrEfLhgUI8gPQqYt3Rk3w64nIY4aEb7mJFwsEnSrYJX9y+Y+LEbDkboPPakfDp
 j4YpTsPdDlYj/CGNpOBJq9FZ7fEbyGeo1QvJ5/NbTMWzZL+dxBP4VTalkgg2nvauKNEs0iaCkF7
 7/vTtaI1cjQlIGQiWWpNRjcWDcw3oL5sfa9ehqeafEB9mBepKrYyTsKURTBcywLzQqNYcWhjX+H
 /Gm0kJmmCLgc6aBXw317d4ImoiEX9Jg3Zknfm+IjddOb6STBNjJuS5PRIGwCm727y8B3goSQr1l
 zkcU6KgmqkfouzpAOJI9l9zQ8HvPDAjJ1WreeNCA56QT0vSrXrBVg7gQQWZpCS0N1s5roi5TxYh
 jk7NmBba4mddUEw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After both queues are streamed off, the decoder sits in
VENUS_DEC_STATE_SEEK. vdec_start_capture() does nothing while OUTPUT is
not streaming, and when OUTPUT is streamed on again, the SEEK path only
queues the DPB buffers if the capture side was already started. So an
application that streams on CAPTURE before OUTPUT gets a decoder that
never receives DPB or capture buffers: the firmware consumes the
bitstream and no frame is ever returned.

The stateful decoder interface does not require either order, and
GStreamer restarts with CAPTURE first. Finish the capture start from the
OUTPUT SEEK path when the CAPTURE queue is already streaming, the same
way vdec_start_capture() does in VENUS_DEC_STATE_DECODING.

Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/venus/vdec.c | 20 +++++++++++++++++++-
 1 file changed, 19 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/qcom/venus/vdec.c b/drivers/media/platform/qcom/venus/vdec.c
index 74591c7a820f5..ae6c2fc65404b 100644
--- a/drivers/media/platform/qcom/venus/vdec.c
+++ b/drivers/media/platform/qcom/venus/vdec.c
@@ -1128,33 +1128,51 @@ static int vdec_start_capture(struct venus_inst *inst)
 free_dpb_bufs:
 	venus_helper_free_dpb_bufs(inst);
 err:
 	return ret;
 }
 
 static int vdec_start_output(struct venus_inst *inst)
 {
+	struct vb2_queue *dst_vq;
+	bool cap_waiting;
 	int ret;
 
 	if (inst->codec_state == VENUS_DEC_STATE_SEEK) {
 		ret = venus_helper_process_initial_out_bufs(inst);
 		if (ret)
 			return ret;
 
 		if (inst->next_buf_last) {
 			inst->codec_state = VENUS_DEC_STATE_DRC;
 		} else {
 			inst->codec_state = VENUS_DEC_STATE_DECODING;
 
-			if (inst->streamon_cap) {
+			/*
+			 * If CAPTURE was streamed on first, vdec_start_capture()
+			 * returned early because OUTPUT was not streaming, so
+			 * start the capture side from here.
+			 */
+			dst_vq = v4l2_m2m_get_dst_vq(inst->m2m_ctx);
+			cap_waiting = !inst->streamon_cap && vb2_is_streaming(dst_vq);
+
+			if (inst->streamon_cap || cap_waiting) {
 				ret = venus_helper_queue_dpb_bufs(inst);
 				if (ret)
 					return ret;
 			}
+
+			if (cap_waiting) {
+				ret = venus_helper_process_initial_cap_bufs(inst);
+				if (ret)
+					return ret;
+
+				inst->streamon_cap = 1;
+			}
 		}
 		goto done;
 	}
 
 	if (inst->codec_state == VENUS_DEC_STATE_INIT ||
 	    inst->codec_state == VENUS_DEC_STATE_CAPTURE_SETUP) {
 		ret = venus_helper_process_initial_out_bufs(inst);
 		goto done;

-- 
2.55.0

