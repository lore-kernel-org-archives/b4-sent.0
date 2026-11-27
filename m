From: Jerome Berclaz <jerome.berclaz@proton.me>
Date: Thu, 26 Nov 2026 16:55:48 -0800
Subject: [PATCH 4/4] media: tegra-vde: reject CABAC in the H.264 PPS
 control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-tegra-vde-fixes-v1-4-fa4a7c1d24cc@proton.me>
References: <20261126-tegra-vde-fixes-v1-0-fa4a7c1d24cc@proton.me>
In-Reply-To: <20261126-tegra-vde-fixes-v1-0-fa4a7c1d24cc@proton.me>
To: Dmitry Osipenko <digetx@gmail.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-media@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jerome Berclaz <jerome.berclaz@proton.me>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2068;
 i=jerome.berclaz@proton.me; s=2026-11; h=from:subject:message-id;
 bh=NZ+kTJWfPnT6RQwMaC2cHK5fnvyB/x7ZJqxE5rk0RxU=;
 b=owGbwMvMwCVmvC9341tRgSLG02pJDNkcV4XTLu15nvkyJMj9wvMPH2b+3f9DXK/EasM75il3l
 083z1x5s6OUhUGMi0FWTJGFtcEwdf4JtoBC/XmHYOawMoEMYeDiFICJXPFj+O9xnq0t3uz8h45V
 s3zXWv40bzxvcbr8aV97gp5pcjzviumMDOfD7tt1uvfsllmpHG1n8FdMt8tp9asc1fv/XszK3x7
 GxgwA
X-Developer-Key: i=jerome.berclaz@proton.me; a=openpgp;
 fpr=058031659FC80650712F9EC233BE6DB1ED151072
X-Endpoint-Received: by B4 Relay for jerome.berclaz@proton.me/2026-11 with auth_id=1658
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The hardware cannot decode CABAC. tegra-vde notices only when the decode
job runs, and then completes the buffers with an error. Stateless
decoders in userspace (FFmpeg's V4L2 request hwaccel, for one) queue the
job asynchronously and do not look at the buffer error flag, so a CABAC
stream plays as broken frames.

Validate the PPS in a try_ctrl handler, as other stateless drivers do for
features they lack, so that setting the controls fails right away. Players
that handle that error fall back to software decoding (mpv does after a
few frames).

Signed-off-by: Jerome Berclaz <jerome.berclaz@proton.me>
---
 drivers/media/platform/nvidia/tegra-vde/v4l2.c | 30 +++++++++++++++++++++++++-
 1 file changed, 29 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/nvidia/tegra-vde/v4l2.c b/drivers/media/platform/nvidia/tegra-vde/v4l2.c
index 3269ca75593f..e59172d27b94 100644
--- a/drivers/media/platform/nvidia/tegra-vde/v4l2.c
+++ b/drivers/media/platform/nvidia/tegra-vde/v4l2.c
@@ -18,10 +18,38 @@
 
 #include "vde.h"
 
+static int tegra_try_ctrl(struct v4l2_ctrl *ctrl)
+{
+	const struct v4l2_ctrl_h264_pps *pps;
+
+	switch (ctrl->id) {
+	case V4L2_CID_STATELESS_H264_PPS:
+		pps = ctrl->p_new.p_h264_pps;
+
+		/*
+		 * CABAC is not supported by the hardware. Reject it here
+		 * rather than failing the decode job later, so that
+		 * userspace gets an error and can fall back to software.
+		 */
+		if (pps->flags & V4L2_H264_PPS_FLAG_ENTROPY_CODING_MODE)
+			return -EINVAL;
+		break;
+	}
+
+	return 0;
+}
+
+static const struct v4l2_ctrl_ops tegra_ctrl_ops = {
+	.try_ctrl = tegra_try_ctrl,
+};
+
 static const struct v4l2_ctrl_config ctrl_cfgs[] = {
 	{	.id = V4L2_CID_STATELESS_H264_DECODE_PARAMS,	},
 	{	.id = V4L2_CID_STATELESS_H264_SPS,		},
-	{	.id = V4L2_CID_STATELESS_H264_PPS,		},
+	{
+		.id = V4L2_CID_STATELESS_H264_PPS,
+		.ops = &tegra_ctrl_ops,
+	},
 	{
 		.id = V4L2_CID_STATELESS_H264_DECODE_MODE,
 		.min = V4L2_STATELESS_H264_DECODE_MODE_FRAME_BASED,

-- 
2.53.0

