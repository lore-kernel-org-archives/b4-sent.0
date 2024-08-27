From: Dikshita Agarwal <quic_dikshita@quicinc.com>
Date: Tue, 27 Aug 2024 15:35:39 +0530
Subject: [PATCH v3 14/29] media: iris: implement enum_fmt and
 enum_frameintervals ioctls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-iris_v3-v3-14-c5fdbbe65e70@quicinc.com>
References: <20240827-iris_v3-v3-0-c5fdbbe65e70@quicinc.com>
In-Reply-To: <20240827-iris_v3-v3-0-c5fdbbe65e70@quicinc.com>
To: Vikash Garodia <quic_vgarodia@quicinc.com>, 
 Abhinav Kumar <quic_abhinavk@quicinc.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dikshita Agarwal <quic_dikshita@quicinc.com>, 
 Vedang Nagar <quic_vnagar@quicinc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724753190; l=5098;
 i=quic_dikshita@quicinc.com; s=20240826; h=from:subject:message-id;
 bh=QCr6J53yyQB3qsIP/vgwzzl2dZykbmOi6iYbyLA24lI=;
 b=TM067bJniiwaBsNPc31rJbmpH4nB/LQsof15R0x7qq8i+yTXWjXGv6TSDB0ToyTSXfy+qkF3W
 uYUS1WzehRKDywV3eTS2T3GoIRoF4gBOmO7UR3J4AcUSENsDOZTIgDj
X-Developer-Key: i=quic_dikshita@quicinc.com; a=ed25519;
 pk=+c7562uu1Y968VTv9z59ch2v3jmlO2Qv3uX7srN3LJY=
X-Endpoint-Received: by B4 Relay for quic_dikshita@quicinc.com/20240826 with auth_id=199
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Vedang Nagar <quic_vnagar@quicinc.com>

Implement enum_fmt and enum_frameintervals ioctls in the
driver with necessary hooks.

Signed-off-by: Vedang Nagar <quic_vnagar@quicinc.com>
Signed-off-by: Dikshita Agarwal <quic_dikshita@quicinc.com>
---
 drivers/media/platform/qcom/iris/iris_vdec.c | 22 +++++++++++
 drivers/media/platform/qcom/iris/iris_vdec.h |  1 +
 drivers/media/platform/qcom/iris/iris_vidc.c | 57 ++++++++++++++++++++++++++++
 3 files changed, 80 insertions(+)

diff --git a/drivers/media/platform/qcom/iris/iris_vdec.c b/drivers/media/platform/qcom/iris/iris_vdec.c
index fd04f56b405d..a38903eefa1c 100644
--- a/drivers/media/platform/qcom/iris/iris_vdec.c
+++ b/drivers/media/platform/qcom/iris/iris_vdec.c
@@ -60,6 +60,28 @@ void iris_vdec_inst_deinit(struct iris_inst *inst)
 	kfree(inst->fmt_src);
 }
 
+int iris_vdec_enum_fmt(struct iris_inst *inst, struct v4l2_fmtdesc *f)
+{
+	if (f->index)
+		return -EINVAL;
+
+	if (V4L2_TYPE_IS_OUTPUT(f->type)) {
+		f->pixelformat = V4L2_PIX_FMT_H264;
+		f->flags = V4L2_FMT_FLAG_COMPRESSED | V4L2_FMT_FLAG_DYN_RESOLUTION;
+		strscpy(f->description, "codec", sizeof(f->description));
+	} else if (V4L2_TYPE_IS_CAPTURE(f->type)) {
+		f->pixelformat = V4L2_PIX_FMT_NV12;
+		strscpy(f->description, "colorformat", sizeof(f->description));
+	}
+
+	if (!f->pixelformat)
+		return -EINVAL;
+
+	memset(f->reserved, 0, sizeof(f->reserved));
+
+	return 0;
+}
+
 int iris_vdec_try_fmt(struct iris_inst *inst, struct v4l2_format *f)
 {
 	struct v4l2_pix_format_mplane *pixmp = &f->fmt.pix_mp;
diff --git a/drivers/media/platform/qcom/iris/iris_vdec.h b/drivers/media/platform/qcom/iris/iris_vdec.h
index 4f2557d15ca2..eb8a1121ae92 100644
--- a/drivers/media/platform/qcom/iris/iris_vdec.h
+++ b/drivers/media/platform/qcom/iris/iris_vdec.h
@@ -10,6 +10,7 @@ struct iris_inst;
 
 void iris_vdec_inst_init(struct iris_inst *inst);
 void iris_vdec_inst_deinit(struct iris_inst *inst);
+int iris_vdec_enum_fmt(struct iris_inst *inst, struct v4l2_fmtdesc *f);
 int iris_vdec_try_fmt(struct iris_inst *inst, struct v4l2_format *f);
 int iris_vdec_s_fmt(struct iris_inst *inst, struct v4l2_format *f);
 
diff --git a/drivers/media/platform/qcom/iris/iris_vidc.c b/drivers/media/platform/qcom/iris/iris_vidc.c
index e09c0a156387..488be6afd999 100644
--- a/drivers/media/platform/qcom/iris/iris_vidc.c
+++ b/drivers/media/platform/qcom/iris/iris_vidc.c
@@ -15,6 +15,10 @@
 
 #define IRIS_DRV_NAME "iris_driver"
 #define IRIS_BUS_NAME "platform:iris_icc"
+#define MIN_FRAME_WIDTH 128
+#define MAX_FRAME_WIDTH 8192
+#define MIN_FRAME_HEIGHT 128
+#define MAX_FRAME_HEIGHT 8192
 #define STEP_WIDTH 1
 #define STEP_HEIGHT 1
 
@@ -255,6 +259,22 @@ int iris_close(struct file *filp)
 	return 0;
 }
 
+static int iris_enum_fmt(struct file *filp, void *fh, struct v4l2_fmtdesc *f)
+{
+	struct iris_inst *inst;
+	int ret;
+
+	inst = iris_get_inst(filp, fh);
+	if (!inst)
+		return -EINVAL;
+
+	mutex_lock(&inst->lock);
+	ret = iris_vdec_enum_fmt(inst, f);
+	mutex_unlock(&inst->lock);
+
+	return ret;
+}
+
 static int iris_try_fmt_vid_mplane(struct file *filp, void *fh, struct v4l2_format *f)
 {
 	struct iris_inst *inst;
@@ -309,6 +329,40 @@ static int iris_g_fmt_vid_mplane(struct file *filp, void *fh, struct v4l2_format
 	return ret;
 }
 
+static int iris_enum_framesizes(struct file *filp, void *fh,
+				struct v4l2_frmsizeenum *fsize)
+{
+	struct iris_inst *inst;
+	int ret = 0;
+
+	inst = iris_get_inst(filp, fh);
+	if (!inst || !fsize)
+		return -EINVAL;
+
+	if (fsize->index)
+		return -EINVAL;
+
+	mutex_lock(&inst->lock);
+	if (fsize->pixel_format != V4L2_PIX_FMT_H264 &&
+	    fsize->pixel_format != V4L2_PIX_FMT_NV12) {
+		ret = -EINVAL;
+		goto unlock;
+	}
+
+	fsize->type = V4L2_FRMSIZE_TYPE_STEPWISE;
+	fsize->stepwise.min_width = MIN_FRAME_WIDTH;
+	fsize->stepwise.max_width = MAX_FRAME_WIDTH;
+	fsize->stepwise.step_width = STEP_WIDTH;
+	fsize->stepwise.min_height = MIN_FRAME_HEIGHT;
+	fsize->stepwise.max_height = MAX_FRAME_HEIGHT;
+	fsize->stepwise.step_height = STEP_HEIGHT;
+
+unlock:
+	mutex_unlock(&inst->lock);
+
+	return ret;
+}
+
 static int iris_g_selection(struct file *filp, void *fh, struct v4l2_selection *s)
 {
 	struct iris_inst *inst;
@@ -362,12 +416,15 @@ static const struct vb2_ops iris_vb2_ops = {
 };
 
 static const struct v4l2_ioctl_ops iris_v4l2_ioctl_ops = {
+	.vidioc_enum_fmt_vid_cap        = iris_enum_fmt,
+	.vidioc_enum_fmt_vid_out        = iris_enum_fmt,
 	.vidioc_try_fmt_vid_cap_mplane  = iris_try_fmt_vid_mplane,
 	.vidioc_try_fmt_vid_out_mplane  = iris_try_fmt_vid_mplane,
 	.vidioc_s_fmt_vid_cap_mplane    = iris_s_fmt_vid_mplane,
 	.vidioc_s_fmt_vid_out_mplane    = iris_s_fmt_vid_mplane,
 	.vidioc_g_fmt_vid_cap_mplane    = iris_g_fmt_vid_mplane,
 	.vidioc_g_fmt_vid_out_mplane    = iris_g_fmt_vid_mplane,
+	.vidioc_enum_framesizes         = iris_enum_framesizes,
 	.vidioc_reqbufs                 = v4l2_m2m_ioctl_reqbufs,
 	.vidioc_g_selection             = iris_g_selection,
 };

-- 
2.34.1

