From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Tue, 24 Nov 2026 00:43:57 +0100
Subject: [PATCH v2 5/5] media: qcom: camss: video: factor pipeline stream
 start/stop into helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-camss-fixes-v2-5-231a5523cd59@gmail.com>
References: <20261124-camss-fixes-v2-0-231a5523cd59@gmail.com>
In-Reply-To: <20261124-camss-fixes-v2-0-231a5523cd59@gmail.com>
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795477434; l=6145;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=cw2sebxPTgI0BsRX0snuOY9H/0VCCimk2e0LvMdO0cQ=;
 b=+0vCu/P7GyPM1uHh0QIJfEc12tA0odd9DKfOstDWl4/FVFA+rCQC51JqPB2vO8eSWWImxS9OD
 vrgirMv01MdBD0ETmZxNkti4cblZ4CWywK0jhsADYIpY6nsD5yNe69a
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If a subdevice fails to start partway through video_start_streaming(),
previously started subdevices earlier in the pipeline (such as the VFE
and CSID) are never stopped, leaking VFE stream counts and write master
reservations. Conversely, video_stop_streaming() returns early on the
first subdevice stop error, leaving remaining upstream subdevices
running and skipping media pipeline teardown and buffer flushing.

Factor pipeline stream state changes into a shared helper,
camss_subdev_pipeline_set_stream(), using v4l2_subdev_enable_streams()
and v4l2_subdev_disable_streams(). Unwind partial start failures by
disabling the pipeline (-EALREADY skips subdevices that were never
enabled), and continue stopping remaining subdevices if an error occurs
during teardown.

Iterate over each entity's sink pads with media_pad_remote_pad_first()
rather than media_entity_remote_source_pad_unique() so entities with
multiple active sink links (such as a VFE fed by both a CSID subdevice
and a parameters video device) do not fail uniqueness checks.

Fixes: 0ac2586c410f ("media: camss: Add files which handle the video device nodes")
Suggested-by: Loic Poulain <loic.poulain@oss.qualcomm.com>
Link: https://lore.kernel.org/r/20261031041154.308030-3-xiaqinghuan@mail.ustc.edu.cn
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-video.c | 116 +++++++++++++++---------
 1 file changed, 72 insertions(+), 44 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-video.c b/drivers/media/platform/qcom/camss/camss-video.c
index 0852eb6..c19b0d1 100644
--- a/drivers/media/platform/qcom/camss/camss-video.c
+++ b/drivers/media/platform/qcom/camss/camss-video.c
@@ -7,12 +7,14 @@
  * Copyright (c) 2013-2015, The Linux Foundation. All rights reserved.
  * Copyright (C) 2015-2018 Linaro Ltd.
  */
+#include <linux/bits.h>
 #include <linux/slab.h>
 #include <media/media-entity.h>
 #include <media/v4l2-dev.h>
 #include <media/v4l2-device.h>
 #include <media/v4l2-ioctl.h>
 #include <media/v4l2-mc.h>
+#include <media/v4l2-subdev.h>
 #include <media/videobuf2-dma-sg.h>
 
 #include "camss-video.h"
@@ -249,13 +251,73 @@ static int video_prepare_streaming(struct vb2_queue *q)
 	return ret;
 }
 
+/*
+ * camss_subdev_pipeline_set_stream - Enable or disable subdevices in pipeline
+ * @video: CAMSS video device
+ * @entity: Media entity whose upstream subdevices are toggled
+ * @enable: true to enable streams, false to disable streams
+ *
+ * Walk upstream across all sink pads of @entity so entities with multiple
+ * active sink links (such as a VFE fed by both a CSID subdevice and a
+ * parameters video output node) do not fail uniqueness checks.
+ *
+ * Return: 0 on success, or the error code of the first subdevice that failed.
+ */
+static int camss_subdev_pipeline_set_stream(struct camss_video *video,
+					    struct media_entity *entity,
+					    bool enable)
+{
+	struct media_pad *sink_pad;
+	int ret = 0;
+
+	media_entity_for_each_pad(entity, sink_pad) {
+		struct v4l2_subdev *subdev;
+		struct media_pad *pad;
+		int err;
+
+		if (!(sink_pad->flags & MEDIA_PAD_FL_SINK))
+			continue;
+
+		pad = media_pad_remote_pad_first(sink_pad);
+		if (!pad || !is_media_entity_v4l2_subdev(pad->entity))
+			continue;
+
+		subdev = media_entity_to_v4l2_subdev(pad->entity);
+		if (enable)
+			err = v4l2_subdev_enable_streams(subdev, pad->index,
+							 BIT_ULL(0));
+		else
+			err = v4l2_subdev_disable_streams(subdev, pad->index,
+							  BIT_ULL(0));
+
+		if (err && err != -EALREADY && err != -ENOIOCTLCMD) {
+			if (enable)
+				return err;
+
+			dev_err(video->camss->dev,
+				"Failed to stop %s pad %u: %d\n",
+				pad->entity->name, pad->index, err);
+			if (!ret)
+				ret = err;
+		}
+
+		err = camss_subdev_pipeline_set_stream(video, pad->entity,
+						       enable);
+		if (err) {
+			if (enable)
+				return err;
+			if (!ret)
+				ret = err;
+		}
+	}
+
+	return ret;
+}
+
 static int video_start_streaming(struct vb2_queue *q, unsigned int count)
 {
 	struct camss_video *video = vb2_get_drv_priv(q);
 	struct video_device *vdev = &video->vdev;
-	struct media_entity *entity;
-	struct media_pad *pad;
-	struct v4l2_subdev *subdev;
 	int ret;
 
 	ret = video_device_pipeline_alloc_start(vdev);
@@ -268,26 +330,15 @@ static int video_start_streaming(struct vb2_queue *q, unsigned int count)
 	if (ret < 0)
 		goto error;
 
-	entity = &vdev->entity;
-	while (1) {
-		pad = &entity->pads[0];
-		if (!(pad->flags & MEDIA_PAD_FL_SINK))
-			break;
-
-		pad = media_pad_remote_pad_first(pad);
-		if (!pad || !is_media_entity_v4l2_subdev(pad->entity))
-			break;
-
-		entity = pad->entity;
-		subdev = media_entity_to_v4l2_subdev(entity);
-
-		ret = v4l2_subdev_call(subdev, video, s_stream, 1);
-		if (ret < 0 && ret != -ENOIOCTLCMD)
-			goto error;
-	}
+	ret = camss_subdev_pipeline_set_stream(video, &vdev->entity, true);
+	if (ret < 0)
+		goto error_stop_subdevs;
 
 	return 0;
 
+error_stop_subdevs:
+	camss_subdev_pipeline_set_stream(video, &vdev->entity, false);
+
 error:
 	video_device_pipeline_stop(vdev);
 
@@ -301,31 +352,8 @@ static void video_stop_streaming(struct vb2_queue *q)
 {
 	struct camss_video *video = vb2_get_drv_priv(q);
 	struct video_device *vdev = &video->vdev;
-	struct media_entity *entity;
-	struct media_pad *pad;
-	struct v4l2_subdev *subdev;
-	int ret;
-
-	entity = &vdev->entity;
-	while (1) {
-		pad = &entity->pads[0];
-		if (!(pad->flags & MEDIA_PAD_FL_SINK))
-			break;
-
-		pad = media_pad_remote_pad_first(pad);
-		if (!pad || !is_media_entity_v4l2_subdev(pad->entity))
-			break;
-
-		entity = pad->entity;
-		subdev = media_entity_to_v4l2_subdev(entity);
-
-		ret = v4l2_subdev_call(subdev, video, s_stream, 0);
 
-		if (ret) {
-			dev_err(video->camss->dev, "Video pipeline stop failed: %d\n", ret);
-			return;
-		}
-	}
+	camss_subdev_pipeline_set_stream(video, &vdev->entity, false);
 
 	video_device_pipeline_stop(vdev);
 

-- 
2.56.0

