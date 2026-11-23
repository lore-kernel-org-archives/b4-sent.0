From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Tue, 24 Nov 2026 00:43:56 +0100
Subject: [PATCH v2 4/5] media: qcom: camss: vfe: destroy mutexes after
 unregistering entities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-camss-fixes-v2-4-231a5523cd59@gmail.com>
References: <20261124-camss-fixes-v2-0-231a5523cd59@gmail.com>
In-Reply-To: <20261124-camss-fixes-v2-0-231a5523cd59@gmail.com>
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795477434; l=1597;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=UM8AcPmLNuPVw+MKiC+h7fTqIkZrDa+p+xj0aLmSxTA=;
 b=J6l4XvMfpSqm0HfOgBsu3D75SmFKfMOolH3iLOnOwMY8ogzTX/yrdglmbkN88Ex+HPn0xxFK5
 Rsoqc6joTbpA2exy/cFvNjXoytsMKA8J2+mWVz5kxjPsWDKkCpzmMrs
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

msm_vfe_unregister_entities() destroys vfe->power_lock and
vfe->stream_lock before unregistering the VFE video devices and V4L2
subdevices. Active userspace handles or concurrent teardown callbacks
can still acquire these mutexes until the entities are unregistered.

Destroy power_lock and stream_lock after all VFE entities have been
unregistered and cleaned up.

Fixes: 4c98a5f57f90 ("media: camss: Add VFE files")
Reviewed-by: Loic Poulain <loic.poulain@oss.qualcomm.com>
Reviewed-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-vfe.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-vfe.c b/drivers/media/platform/qcom/camss/camss-vfe.c
index ad09593..fe6b7ef 100644
--- a/drivers/media/platform/qcom/camss/camss-vfe.c
+++ b/drivers/media/platform/qcom/camss/camss-vfe.c
@@ -2168,9 +2168,6 @@ void msm_vfe_unregister_entities(struct vfe_device *vfe)
 {
 	int i;
 
-	mutex_destroy(&vfe->power_lock);
-	mutex_destroy(&vfe->stream_lock);
-
 	for (i = 0; i < vfe->res->line_num; i++) {
 		struct v4l2_subdev *sd = &vfe->line[i].subdev;
 		struct camss_video *video_out = &vfe->line[i].video_out;
@@ -2179,6 +2176,9 @@ void msm_vfe_unregister_entities(struct vfe_device *vfe)
 		v4l2_device_unregister_subdev(sd);
 		media_entity_cleanup(&sd->entity);
 	}
+
+	mutex_destroy(&vfe->power_lock);
+	mutex_destroy(&vfe->stream_lock);
 }
 
 bool vfe_is_lite(struct vfe_device *vfe)

-- 
2.56.0

