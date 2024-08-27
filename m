From: Dikshita Agarwal <quic_dikshita@quicinc.com>
Date: Tue, 27 Aug 2024 15:35:42 +0530
Subject: [PATCH v3 17/29] media: iris: implement query_cap, query_ctrl and
 query_menu ioctls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-iris_v3-v3-17-c5fdbbe65e70@quicinc.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724753190; l=3331;
 i=quic_dikshita@quicinc.com; s=20240826; h=from:subject:message-id;
 bh=NYDzrot9plHMXRI9hRDmFqnK2WCrDqJ1PWcxNJaBut8=;
 b=bqp6YfioGmZgpf/dd6qIzyzqTSUxRkhxQCLhw+E/xHqnmBGupWizoKvcCw6xbrjsSS+EkCDm0
 IeRGLAZLuYsD0qwuG1Ki2Z/HzhrYRxD/KSIE+u8NQIFHvtJKTE4vp7u
X-Developer-Key: i=quic_dikshita@quicinc.com; a=ed25519;
 pk=+c7562uu1Y968VTv9z59ch2v3jmlO2Qv3uX7srN3LJY=
X-Endpoint-Received: by B4 Relay for quic_dikshita@quicinc.com/20240826 with auth_id=199
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Vedang Nagar <quic_vnagar@quicinc.com>

Implement query_cap, query_ctrl and query_menu ioctls in the
driver with necessary hooks.

Signed-off-by: Vedang Nagar <quic_vnagar@quicinc.com>
Signed-off-by: Dikshita Agarwal <quic_dikshita@quicinc.com>
---
 drivers/media/platform/qcom/iris/iris_vidc.c | 89 ++++++++++++++++++++++++++++
 1 file changed, 89 insertions(+)

diff --git a/drivers/media/platform/qcom/iris/iris_vidc.c b/drivers/media/platform/qcom/iris/iris_vidc.c
index 7d5da30cb1d1..1dd612b7cec5 100644
--- a/drivers/media/platform/qcom/iris/iris_vidc.c
+++ b/drivers/media/platform/qcom/iris/iris_vidc.c
@@ -362,6 +362,92 @@ static int iris_enum_framesizes(struct file *filp, void *fh,
 	return ret;
 }
 
+static int iris_querycap(struct file *filp, void *fh, struct v4l2_capability *cap)
+{
+	struct iris_inst *inst;
+	int ret = 0;
+
+	inst = iris_get_inst(filp, fh);
+	if (!inst)
+		return -EINVAL;
+
+	mutex_lock(&inst->lock);
+	strscpy(cap->driver, IRIS_DRV_NAME, sizeof(cap->driver));
+	strscpy(cap->bus_info, IRIS_BUS_NAME, sizeof(cap->bus_info));
+	memset(cap->reserved, 0, sizeof(cap->reserved));
+	strscpy(cap->card, "iris_decoder", sizeof(cap->card));
+	mutex_unlock(&inst->lock);
+
+	return ret;
+}
+
+static int iris_queryctrl(struct file *filp, void *fh, struct v4l2_queryctrl *q_ctrl)
+{
+	struct v4l2_ctrl *ctrl;
+	struct iris_inst *inst;
+	int ret = 0;
+
+	inst = iris_get_inst(filp, fh);
+	if (!inst || !q_ctrl)
+		return -EINVAL;
+
+	mutex_lock(&inst->lock);
+	ctrl = v4l2_ctrl_find(&inst->ctrl_handler, q_ctrl->id);
+	if (!ctrl) {
+		ret = -EINVAL;
+		goto unlock;
+	}
+
+	q_ctrl->minimum = ctrl->minimum;
+	q_ctrl->maximum = ctrl->maximum;
+	q_ctrl->default_value = ctrl->default_value;
+	q_ctrl->flags = 0;
+	q_ctrl->step = ctrl->step;
+
+unlock:
+	mutex_unlock(&inst->lock);
+
+	return ret;
+}
+
+static int iris_querymenu(struct file *filp, void *fh, struct v4l2_querymenu *qmenu)
+{
+	struct v4l2_ctrl *ctrl;
+	struct iris_inst *inst;
+	int ret = 0;
+
+	inst = iris_get_inst(filp, fh);
+	if (!inst || !qmenu)
+		return -EINVAL;
+
+	mutex_lock(&inst->lock);
+	ctrl = v4l2_ctrl_find(&inst->ctrl_handler, qmenu->id);
+	if (!ctrl) {
+		ret = -EINVAL;
+		goto unlock;
+	}
+
+	if (ctrl->type != V4L2_CTRL_TYPE_MENU) {
+		ret = -EINVAL;
+		goto unlock;
+	}
+
+	if (qmenu->index < ctrl->minimum || qmenu->index > ctrl->maximum) {
+		ret = -EINVAL;
+		goto unlock;
+	}
+
+	if (ctrl->menu_skip_mask & (1 << qmenu->index)) {
+		ret = -EINVAL;
+		goto unlock;
+	}
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
@@ -453,6 +539,9 @@ static const struct v4l2_ioctl_ops iris_v4l2_ioctl_ops = {
 	.vidioc_g_fmt_vid_out_mplane    = iris_g_fmt_vid_mplane,
 	.vidioc_enum_framesizes         = iris_enum_framesizes,
 	.vidioc_reqbufs                 = v4l2_m2m_ioctl_reqbufs,
+	.vidioc_querycap                = iris_querycap,
+	.vidioc_queryctrl               = iris_queryctrl,
+	.vidioc_querymenu               = iris_querymenu,
 	.vidioc_g_selection             = iris_g_selection,
 	.vidioc_subscribe_event         = iris_subscribe_event,
 	.vidioc_unsubscribe_event       = iris_unsubscribe_event,

-- 
2.34.1

