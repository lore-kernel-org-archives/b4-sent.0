From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Sun, 22 Nov 2026 14:35:53 +0100
Subject: [PATCH 5/5] media: qcom: camss: video: stop started subdevs on
 start_streaming failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-camss-fixes-v1-5-9df4deb87ea2@gmail.com>
References: <20261122-camss-fixes-v1-0-9df4deb87ea2@gmail.com>
In-Reply-To: <20261122-camss-fixes-v1-0-9df4deb87ea2@gmail.com>
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795354550; l=2265;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=zjyMBn6isM42TnzTEXtc7218B+PYUv1D1B/tQpAVb48=;
 b=WK0zgaho3jzMyUm75TRBIphefHd5XIXgDPDwglBrpJG4eGbOUZsBgj+nfpDpPrcLIR5nRz9cA
 pnhHrqHJPWzBxmqWfils8z3Pu33//w29tBvdMy6IxM1fT81VWSOiEaZ
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If a subdevice fails s_stream(1) partway through video_start_streaming(),
previously started subdevices earlier in the pipeline (such as the VFE
and CSID) are never stopped. This leaks VFE stream counts and write
master reservations, leaving the pipeline stuck on subsequent stream
attempts.

Walk the pipeline from the video device up to the failing entity and
call s_stream(0) on each already-started subdevice before stopping the
media pipeline and flushing buffers.

Fixes: 0ac2586c410f ("media: camss: Add files which handle the video device nodes")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-video.c | 27 ++++++++++++++++++++++---
 1 file changed, 24 insertions(+), 3 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-video.c b/drivers/media/platform/qcom/camss/camss-video.c
index 0852eb6..6f7b9f3 100644
--- a/drivers/media/platform/qcom/camss/camss-video.c
+++ b/drivers/media/platform/qcom/camss/camss-video.c
@@ -253,7 +253,7 @@ static int video_start_streaming(struct vb2_queue *q, unsigned int count)
 {
 	struct camss_video *video = vb2_get_drv_priv(q);
 	struct video_device *vdev = &video->vdev;
-	struct media_entity *entity;
+	struct media_entity *entity, *failed_entity;
 	struct media_pad *pad;
 	struct v4l2_subdev *subdev;
 	int ret;
@@ -282,12 +282,33 @@ static int video_start_streaming(struct vb2_queue *q, unsigned int count)
 		subdev = media_entity_to_v4l2_subdev(entity);
 
 		ret = v4l2_subdev_call(subdev, video, s_stream, 1);
-		if (ret < 0 && ret != -ENOIOCTLCMD)
-			goto error;
+		if (ret < 0 && ret != -ENOIOCTLCMD) {
+			failed_entity = entity;
+			goto error_stop_subdevs;
+		}
 	}
 
 	return 0;
 
+error_stop_subdevs:
+	entity = &vdev->entity;
+	while (1) {
+		pad = &entity->pads[0];
+		if (!(pad->flags & MEDIA_PAD_FL_SINK))
+			break;
+
+		pad = media_pad_remote_pad_first(pad);
+		if (!pad || !is_media_entity_v4l2_subdev(pad->entity))
+			break;
+
+		entity = pad->entity;
+		if (entity == failed_entity)
+			break;
+
+		subdev = media_entity_to_v4l2_subdev(entity);
+		v4l2_subdev_call(subdev, video, s_stream, 0);
+	}
+
 error:
 	video_device_pipeline_stop(vdev);
 

-- 
2.56.0

