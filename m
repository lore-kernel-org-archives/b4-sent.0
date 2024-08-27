From: Dikshita Agarwal <quic_dikshita@quicinc.com>
Date: Tue, 27 Aug 2024 15:35:38 +0530
Subject: [PATCH v3 13/29] media: iris: implement g_selection ioctl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-iris_v3-v3-13-c5fdbbe65e70@quicinc.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724753190; l=2127;
 i=quic_dikshita@quicinc.com; s=20240826; h=from:subject:message-id;
 bh=p8lMxAQLIngNvbWVVTC34P+pqjWzrRVYcTab/Vl0ejY=;
 b=agEiI+HjFJi1eDip1iEXGl/3HSu6vIZykLsuSzjw9QBOLa1sg4rMAsEI+pEHAd72iSHnsCs9l
 +ePdAPDkFIMDIW5M2wLBeFfLeuukTmrsZ1Wxfl0BsGhz8ORg7dd30zS
X-Developer-Key: i=quic_dikshita@quicinc.com; a=ed25519;
 pk=+c7562uu1Y968VTv9z59ch2v3jmlO2Qv3uX7srN3LJY=
X-Endpoint-Received: by B4 Relay for quic_dikshita@quicinc.com/20240826 with auth_id=199
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Vedang Nagar <quic_vnagar@quicinc.com>

Implement g_selection ioctl in the driver with necessary hooks.

Signed-off-by: Vedang Nagar <quic_vnagar@quicinc.com>
Signed-off-by: Dikshita Agarwal <quic_dikshita@quicinc.com>
---
 drivers/media/platform/qcom/iris/iris_vidc.c | 40 ++++++++++++++++++++++++++++
 1 file changed, 40 insertions(+)

diff --git a/drivers/media/platform/qcom/iris/iris_vidc.c b/drivers/media/platform/qcom/iris/iris_vidc.c
index 7eafbbfd22e4..e09c0a156387 100644
--- a/drivers/media/platform/qcom/iris/iris_vidc.c
+++ b/drivers/media/platform/qcom/iris/iris_vidc.c
@@ -309,6 +309,45 @@ static int iris_g_fmt_vid_mplane(struct file *filp, void *fh, struct v4l2_format
 	return ret;
 }
 
+static int iris_g_selection(struct file *filp, void *fh, struct v4l2_selection *s)
+{
+	struct iris_inst *inst;
+	int ret = 0;
+
+	inst = iris_get_inst(filp, fh);
+	if (!inst || !s)
+		return -EINVAL;
+
+	mutex_lock(&inst->lock);
+	if (s->type != V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE &&
+	    s->type != V4L2_BUF_TYPE_VIDEO_CAPTURE) {
+		ret = -EINVAL;
+		goto unlock;
+	}
+
+	switch (s->target) {
+	case V4L2_SEL_TGT_CROP_BOUNDS:
+	case V4L2_SEL_TGT_CROP_DEFAULT:
+	case V4L2_SEL_TGT_CROP:
+	case V4L2_SEL_TGT_COMPOSE_BOUNDS:
+	case V4L2_SEL_TGT_COMPOSE_PADDED:
+	case V4L2_SEL_TGT_COMPOSE_DEFAULT:
+	case V4L2_SEL_TGT_COMPOSE:
+		s->r.left = inst->crop.left;
+		s->r.top = inst->crop.top;
+		s->r.width = inst->crop.width;
+		s->r.height = inst->crop.height;
+		break;
+	default:
+		ret = -EINVAL;
+	}
+
+unlock:
+	mutex_unlock(&inst->lock);
+
+	return ret;
+}
+
 static struct v4l2_file_operations iris_v4l2_file_ops = {
 	.owner                          = THIS_MODULE,
 	.open                           = iris_open,
@@ -330,6 +369,7 @@ static const struct v4l2_ioctl_ops iris_v4l2_ioctl_ops = {
 	.vidioc_g_fmt_vid_cap_mplane    = iris_g_fmt_vid_mplane,
 	.vidioc_g_fmt_vid_out_mplane    = iris_g_fmt_vid_mplane,
 	.vidioc_reqbufs                 = v4l2_m2m_ioctl_reqbufs,
+	.vidioc_g_selection             = iris_g_selection,
 };
 
 void iris_init_ops(struct iris_core *core)

-- 
2.34.1

