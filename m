From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 09:03:01 +0000
Subject: [PATCH v3 09/14] drm/panfrost: Don't cancel a job that completed
 during a reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-panfrost-long-jobs-v3-9-80ae78d38f6e@gmail.com>
References: <20261113-panfrost-long-jobs-v3-0-80ae78d38f6e@gmail.com>
In-Reply-To: <20261113-panfrost-long-jobs-v3-0-80ae78d38f6e@gmail.com>
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794560572; l=2187;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=hhguDU6dUN4EClF9T/THCI2uXCXcschD/PT+h4s0NtU=;
 b=zHYfn9q8MOwjSlbANdJbWdAckGdgiktwBAROwiPPeAvamcaz7HyTmrQydaC3gnBKJ1YEsbZLl
 RmRtiAeGenDAC5ZqzLT2d03iTbkN70ahXlxK2pTAZUhCAH40m508svI
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_reset() stops the schedulers, which detaches them from the done
fences of the jobs on the GPU, then soft-stops the slots and handles the
pending interrupts. A job that completes in that window gets its done
fence signalled and its jc cleared. drm_sched_resubmit_jobs() then calls
panfrost_job_run(), which returns NULL for a job with no jc, and since
commit 03877d621db0 ("drm/scheduler: mark jobs without fence as
canceled") drm_sched_start() completes it with -ECANCELED, although it
did complete.

Return the job's done fence instead: drm_sched_start() finds it
signalled and completes the job with its status, 0 or the error
panfrost_job_handle_err() set for a job that was hard-stopped or
faulted.

This depends on the previous patch: without it, a job cancelled from
_NEXT and taken for done would now be reported as completed.

Found by code review (Sashiko) of "Soft-stop and resume a job that
outlives the timeout", which widens the window. Not reproduced.

Fixes: 03877d621db0 ("drm/scheduler: mark jobs without fence as canceled")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-206581@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_job.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index 1bb70b07d..897743cb8 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.c
+++ b/drivers/gpu/drm/panfrost/panfrost_job.c
@@ -409,11 +409,11 @@ static struct dma_fence *panfrost_job_run(struct drm_sched_job *sched_job)
 	if (unlikely(job->base.s_fence->finished.error))
 		return NULL;
 
-	/* Nothing to execute: can happen if the job has finished while
-	 * we were resetting the GPU.
+	/* The job has finished while we were resetting the GPU. Return its
+	 * done fence: with no fence, drm_sched_start() cancels the job.
 	 */
 	if (!job->jc)
-		return NULL;
+		return dma_fence_get(job->done_fence);
 
 	fence = panfrost_fence_create(pfdev, slot);
 	if (IS_ERR(fence))

-- 
2.55.0

