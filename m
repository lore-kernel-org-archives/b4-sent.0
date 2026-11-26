From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 09:36:45 +0000
Subject: [PATCH v4 02/17] drm/panfrost: Power the GPU up for a reset queued
 from the MMU code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-panfrost-long-jobs-v4-2-23579629ceca@gmail.com>
References: <20261126-panfrost-long-jobs-v4-0-23579629ceca@gmail.com>
In-Reply-To: <20261126-panfrost-long-jobs-v4-0-23579629ceca@gmail.com>
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795685806; l=1987;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=d/LITLeB5gWoIeqZGfkGbg6ByVPkBB9Gpn71KK4MPNA=;
 b=uEKQ91G95F/NA/31wcwx4FVEeEN7PvxKJeh9ZuTGICjxezqW54y6zSE+riDHf2UhCjhY+HmNr
 dwEYjl9aCYoA+JPhzQEs9n4z30MzjQqRNgbBIoWyKYsIIKBr+5kX9gw
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_reset_work() calls panfrost_reset() without a runtime PM
reference, and the MMU code that queues it drops its own right after.
Take a reference in the work. A GPU that cannot be resumed is reset by
its next runtime resume, so clear reset.pending there. Not reproduced.

Fixes: f9ab9c66f080 ("drm/panfrost: Reset the GPU when the AS_ACTIVE bit is stuck")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-206548@kernel.org/
Closes: https://lore.kernel.org/all/sashiko-outbox-212557@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
v4: clear reset.pending in runtime resume (Sashiko 212557); system
sleep is left to patch 1.
---
 drivers/gpu/drm/panfrost/panfrost_device.c | 1 +
 drivers/gpu/drm/panfrost/panfrost_job.c    | 5 +++++
 2 files changed, 6 insertions(+)

diff --git a/drivers/gpu/drm/panfrost/panfrost_device.c b/drivers/gpu/drm/panfrost/panfrost_device.c
index 40eda3612..3c5f077db 100644
--- a/drivers/gpu/drm/panfrost/panfrost_device.c
+++ b/drivers/gpu/drm/panfrost/panfrost_device.c
@@ -540,6 +540,7 @@ static int panfrost_device_runtime_resume(struct device *dev)
 		}
 	}
 
+	atomic_set(&pfdev->reset.pending, 0);
 	panfrost_device_reset(pfdev, true);
 	panfrost_devfreq_resume(pfdev);
 
diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index 79b302fef..b5b523cb2 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.c
+++ b/drivers/gpu/drm/panfrost/panfrost_job.c
@@ -810,7 +810,12 @@ static void panfrost_reset_work(struct work_struct *work)
 	struct panfrost_device *pfdev;
 
 	pfdev = container_of(work, struct panfrost_device, reset.work);
+
+	if (pm_runtime_resume_and_get(pfdev->base.dev))
+		return;
+
 	panfrost_reset(pfdev, NULL);
+	pm_runtime_put_autosuspend(pfdev->base.dev);
 }
 
 static const struct drm_sched_backend_ops panfrost_sched_ops = {

-- 
2.55.0

