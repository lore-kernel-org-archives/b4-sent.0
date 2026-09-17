From: David Heidelberg <david@ixit.cz>
Date: Thu, 17 Sep 2026 16:08:23 +0200
Subject: [PATCH] media: v4l2: Clear subdev devnode before calling release()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260917-v4l2-release-fix-v1-1-acbac7f9b78e@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMUQqDMBCE4avIPrsQg2i3Vyk+xDhtt4iWrEpBv
 Htj+/gNzL+TISmMrsVOCZuazlNGVRYUn2F6gHXIJu9846RqeatHzwkjgoHv+uGLOKmlafsoA+X
 bOyHPv+St+9vW/oW4nB06ji/x4DysdAAAAA==
X-Change-ID: 20260917-v4l2-release-fix-89094967bc9d
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Dafna Hirschfeld <dafna.hirschfeld@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1729; i=david@ixit.cz;
 h=from:subject:message-id; bh=5slSMYxuBgDGXyuAtqR9ZCxY1A7kKnqQ6WHaKf7aEdE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqq/RcWM2WD6KyRB8+zjxUZYzmG1/C75BD4j7aY
 9ZhxW9qKxyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaqv0XAAKCRBgAj/E00kg
 cklTD/9No50I3OOiXFPmYckznONdpAqdchnb4ZchY8TRvZGvSVtYUw/GO21RGfsGS0eyb6iLiJe
 yIxkY/XIuajzv1rkjJFZMyfjukXYMIt0xnX+R6ImsnGazF5jD1CEQrilNtve4tkqARsdPEfeUTR
 okvTSAS9fWuQsxeOR5NmgKSc2a/sC10NmiSuU9yicYt84IoA5DXqw2qNLa1FM42qZIPDQQe6XEK
 lWXDiWhJnu+fxiAz+Jb4Ce0I646WA7Qyukp4PTrzAOiWjZuD2tNuKl8mqWrns+AYevzpY6xzBbJ
 AnWU/F1Dls8AMTVmwBPnDwlYX7u1fAlFLgSdUdQRSdwq00XG7soww6JKcNQtzENye6c5O1ndIeT
 psO37LfoWqSMGCNv+suTcuQS5Zfhko/gbkzgmtLMRZ8Fi4/h0F/Z1yUKYp5ZuyGKg4kILJgjhEy
 RQpfXNJYPO/H+3b1UjwaOa65K1BsWC1OJZD92RdzfycqI4I8sab+DpmkOiZDMEHAb/45FPFDj54
 6gEWIcEr0o0Ql2N/oPrJnn1SDfi/Uxzw4MO8IylEZbqna8d+CWphxcsLhEiJpqCvSi5dg0nRYN0
 wUg/5/ayTN1Uh5vZY4o99/8DWc4IJV5ucRXSuUMQnbcCdVglC7ULRJYQgY0QkuuMiicUECVGAMt
 PYpmPka09zkrzEg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The subdevice release callback frees the memory that contains the
v4l2_subdev structure itself, but v4l2_subdev_release() wrote
sd->devnode = NULL after invoking the callback. Any driver implementing
the release callback to free its state would leave that write targeting
already-freed memory.

Clear sd->devnode before calling the release callback so the callback
runs last, matching its documented purpose of freeing the subdevice
memory.

Fixes: 6990570f7e0a ("media: v4l2-core: fix a use-after-free bug of sd->devnode")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/v4l2-core/v4l2-device.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/v4l2-core/v4l2-device.c b/drivers/media/v4l2-core/v4l2-device.c
index 67e3073de1321..b4036105c2d1a 100644
--- a/drivers/media/v4l2-core/v4l2-device.c
+++ b/drivers/media/v4l2-core/v4l2-device.c
@@ -171,19 +171,19 @@ int __v4l2_device_register_subdev(struct v4l2_device *v4l2_dev,
 	return err;
 }
 EXPORT_SYMBOL_GPL(__v4l2_device_register_subdev);
 
 static void v4l2_subdev_release(struct v4l2_subdev *sd)
 {
 	struct module *owner = !sd->owner_v4l2_dev ? sd->owner : NULL;
 
+	sd->devnode = NULL;
 	if (sd->internal_ops && sd->internal_ops->release)
 		sd->internal_ops->release(sd);
-	sd->devnode = NULL;
 	module_put(owner);
 }
 
 static void v4l2_device_release_subdev_node(struct video_device *vdev)
 {
 	v4l2_subdev_release(video_get_drvdata(vdev));
 	kfree(vdev);
 }

---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260917-v4l2-release-fix-89094967bc9d

Best regards,
--  
David Heidelberg <david@ixit.cz>

