From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 09:36:57 +0000
Subject: [PATCH v4 14/17] drm/panfrost: Keep the GPU powered in the job
 timeout handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-panfrost-long-jobs-v4-14-23579629ceca@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795685806; l=2141;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=N3/r0MPqmTfHMSYcrVUI3Gc8NQD6K3bi1B+vyvlqWHM=;
 b=OL4/UsTLn3B1yEJUUuAOAmbJzZUU5twXgF43YsktMQhY/iyWo88vh+aTgTTaqwK72+QTg/Z9y
 pouMrLM+5sxB1qo0EFwJBgkpSDZ0ADNQwj53ioFeOr2r2ZkQBKIxxYZ
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_job_timedout() accesses the GPU without a runtime PM reference
of its own. If the job completes after the fence check, the GPU can
autosuspend first (clocks off on GPU_PM_RT). Take a reference with
pm_runtime_get_noresume(): if the fence is still unsignalled after
that, the job's own reference was held.

Tested on an H616 with a test-only wait after the fence check: before,
the GPU suspended 50 ms after the fence; after, it stayed active.

Fixes: f3ba91228e8e ("drm/panfrost: Add initial panfrost driver")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-212575@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
v4: new.
---
 drivers/gpu/drm/panfrost/panfrost_job.c | 17 +++++++++++++++--
 1 file changed, 15 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index 722f87ebe..74cc3dd02 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.c
+++ b/drivers/gpu/drm/panfrost/panfrost_job.c
@@ -775,8 +775,8 @@ panfrost_reset(struct panfrost_device *pfdev,
 	dma_fence_end_signalling(cookie);
 }
 
-static enum drm_gpu_sched_stat panfrost_job_timedout(struct drm_sched_job
-						     *sched_job)
+static enum drm_gpu_sched_stat
+panfrost_job_handle_timeout(struct drm_sched_job *sched_job)
 {
 	struct panfrost_job *job = to_panfrost_job(sched_job);
 	struct panfrost_device *pfdev = job->pfdev;
@@ -821,6 +821,19 @@ static enum drm_gpu_sched_stat panfrost_job_timedout(struct drm_sched_job
 	return DRM_GPU_SCHED_STAT_RESET;
 }
 
+static enum drm_gpu_sched_stat panfrost_job_timedout(struct drm_sched_job
+						     *sched_job)
+{
+	struct panfrost_device *pfdev = to_panfrost_job(sched_job)->pfdev;
+	enum drm_gpu_sched_stat stat;
+
+	pm_runtime_get_noresume(pfdev->base.dev);
+	stat = panfrost_job_handle_timeout(sched_job);
+	pm_runtime_put_autosuspend(pfdev->base.dev);
+
+	return stat;
+}
+
 static void panfrost_reset_work(struct work_struct *work)
 {
 	struct panfrost_device *pfdev;

-- 
2.55.0

