From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:44:59 +0000
Subject: [PATCH 4/7] drm/panfrost: Don't resume a soft-stopped job after a
 GPU reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-panfrost-long-jobs-v1-4-24508939ae8d@gmail.com>
References: <20261110-panfrost-long-jobs-v1-0-24508939ae8d@gmail.com>
In-Reply-To: <20261110-panfrost-long-jobs-v1-0-24508939ae8d@gmail.com>
To: David Airlie <airlied@gmail.com>, 
 Thomas Zimmermann <tzimmermann@suse.de>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Steven Price <steven.price@arm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Simona Vetter <simona@ffwll.ch>, 
 Maxime Ripard <mripard@kernel.org>, 
 Boris Brezillon <boris.brezillon@collabora.com>
Cc: linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794296695; l=4502;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=sJRCfYMhcu7W/ZVl5OGR38ES1rET54iNOnklZ5mu/GA=;
 b=/C0xY7B+EovC+0kW921heLsw/z/8wgoT3kU1W+aVRbElpdVtfkhIFH2zJEITPxEjB1VEQ4Jpx
 bTcT5UJUCOJAYC2BzRwTac0+MncJnF08IGOwmXgpJlygdKkBx0cDQTJ
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_reset() soft-stops every slot before it resets the GPU. A job
that reaches a task boundary in time reports STOPPED,
panfrost_job_handle_err() moves its jc to JS_TAIL, and
drm_sched_resubmit_jobs() runs it again from there once the GPU has
been reset. But the progress of a stopped job lives in the GPU: the
hardware's update of the job header and the results of the tasks that
completed since the last cache write-back sit in the L2, and
panfrost_device_reset() soft-resets the GPU without cleaning it first.
The resumed job then completes with stale data in the buffers it still
had to write, and no error is reported.

Count the GPU resets and record the count when a job is stopped. A job
that was stopped before the last reset is failed with -ECANCELED in
panfrost_job_run() instead of being resumed, as the Arm driver fails
every atom that was on the hardware when the GPU was reset. A job that
is soft-stopped and resumed without a reset in between is unaffected.

Today the window is small, since panfrost_reset() hardly waits for the
soft-stops (see the next patch), but the next patches make every
soft-stopped job reach STOPPED.

Fixes: 030761e097b4 ("drm/panfrost: Queue jobs on the hardware")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_device.h |  5 +++++
 drivers/gpu/drm/panfrost/panfrost_job.c    | 14 ++++++++++++++
 drivers/gpu/drm/panfrost/panfrost_job.h    |  8 ++++++++
 3 files changed, 27 insertions(+)

diff --git a/drivers/gpu/drm/panfrost/panfrost_device.h b/drivers/gpu/drm/panfrost/panfrost_device.h
index 63452febb..fd960a436 100644
--- a/drivers/gpu/drm/panfrost/panfrost_device.h
+++ b/drivers/gpu/drm/panfrost/panfrost_device.h
@@ -167,6 +167,11 @@ struct panfrost_device {
 		struct work_struct work;
 		struct rw_semaphore lock;
 		atomic_t pending;
+		/* Bumped by every GPU reset. A soft-stopped job may only be
+		 * resumed while this still reads what it did when the job was
+		 * stopped (see panfrost_job_run()).
+		 */
+		unsigned int count;
 	} reset;
 
 	struct mutex shrinker_lock;
diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index 3a46dd61c..e1f3e5d71 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.c
+++ b/drivers/gpu/drm/panfrost/panfrost_job.c
@@ -415,6 +415,17 @@ static struct dma_fence *panfrost_job_run(struct drm_sched_job *sched_job)
 	if (!job->jc)
 		return NULL;
 
+	/* A soft-stopped job carries its progress in the job header and the
+	 * GPU caches, which a GPU reset throws away. Resumed from JS_TAIL after
+	 * a reset it would complete with the results of the tasks since the
+	 * last cache write-back missing, and no error. Fail it instead, as the
+	 * Arm driver fails every atom that was on the hardware at a reset.
+	 */
+	if (job->stopped && job->stop_reset_count != pfdev->reset.count) {
+		dma_fence_set_error(&job->base.s_fence->finished, -ECANCELED);
+		return NULL;
+	}
+
 	fence = panfrost_fence_create(pfdev, slot);
 	if (IS_ERR(fence))
 		return fence;
@@ -475,6 +486,8 @@ static void panfrost_job_handle_err(struct panfrost_device *pfdev,
 		/* Update the job head so we can resume */
 		job->jc = job_read(pfdev, JS_TAIL_LO(js)) |
 			  ((u64)job_read(pfdev, JS_TAIL_HI(js)) << 32);
+		job->stopped = true;
+		job->stop_reset_count = pfdev->reset.count;
 
 		/* The job will be resumed, don't signal the fence */
 		signal_fence = false;
@@ -728,6 +741,7 @@ panfrost_reset(struct panfrost_device *pfdev,
 			panfrost_devfreq_record_idle(&pfdev->pfdevfreq);
 		}
 	}
+	pfdev->reset.count++;
 	memset(pfdev->jobs, 0, sizeof(pfdev->jobs));
 	spin_unlock(&pfdev->js->job_lock);
 
diff --git a/drivers/gpu/drm/panfrost/panfrost_job.h b/drivers/gpu/drm/panfrost/panfrost_job.h
index 3e3b97178..9bbc0c262 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.h
+++ b/drivers/gpu/drm/panfrost/panfrost_job.h
@@ -27,6 +27,14 @@ struct panfrost_job {
 	__u32 requirements;
 	__u32 flush_id;
 
+	/* Set once the job has been soft-stopped: jc then points into a partly
+	 * executed chain whose progress lives in the job header and the GPU
+	 * caches, and is only valid while the GPU has not been reset since
+	 * (pfdev->reset.count at the time of the stop).
+	 */
+	bool stopped;
+	unsigned int stop_reset_count;
+
 	struct panfrost_gem_mapping **mappings;
 	struct drm_gem_object **bos;
 	u32 bo_count;

-- 
2.55.0

