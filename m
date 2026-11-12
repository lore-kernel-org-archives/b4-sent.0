From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:48:41 +0000
Subject: [PATCH v2 08/11] drm/panfrost: Don't cancel a job that completed
 during a reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-panfrost-long-jobs-v2-8-a06830da3d99@gmail.com>
References: <20261112-panfrost-long-jobs-v2-0-a06830da3d99@gmail.com>
In-Reply-To: <20261112-panfrost-long-jobs-v2-0-a06830da3d99@gmail.com>
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794473314; l=2617;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=iMJelzj8KqIiUIEwuJi9ZCg/13D5VG22D+zXxoQOWxs=;
 b=+h01gW76bjx47nnrrwEyagNXsWayE1TGc1O/lWLhxtLBC5hOMJixs/5We18jeovD/WDoz6EYs
 NPwcKrnIEYZC/MYMsA74BPpy+w3omlmmrO+2ox6l1OAG0PNLGSH+SkM
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_reset() stops the schedulers, which detaches them from the done
fences of the jobs on the GPU, then soft-stops the slots and handles the
interrupts that are still pending. A job that finishes in that window
instead of stopping is completed by panfrost_jm_handle_done(): its done
fence is signalled and its jc cleared. drm_sched_resubmit_jobs() then
calls panfrost_job_run(), which returns NULL for a job with no jc, and
since commit 03877d621db0 ("drm/scheduler: mark jobs without fence as
canceled") drm_sched_start() completes a pending job without a hardware
fence with -ECANCELED. The job did complete, but userspace is told it
did not.

Return the job's done fence instead: drm_sched_start() finds it
signalled and completes the job with the fence's status, which is 0 for
a job that finished and the error panfrost_job_handle_err() set for one
that was hard-stopped or faulted.

This depends on the previous patch: before it, a job cancelled from
_NEXT could be taken for done in the same window, and would now be
reported as completed without having run.

Found by code review (Sashiko) of the next patches, which make the
soft-stop wait longer and the window wider. Not reproduced.

Fixes: 03877d621db0 ("drm/scheduler: mark jobs without fence as canceled")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-206581@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_job.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index 418a91a31..7561de67c 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.c
+++ b/drivers/gpu/drm/panfrost/panfrost_job.c
@@ -409,11 +409,14 @@ static struct dma_fence *panfrost_job_run(struct drm_sched_job *sched_job)
 	if (unlikely(job->base.s_fence->finished.error))
 		return NULL;
 
-	/* Nothing to execute: can happen if the job has finished while
-	 * we were resetting the GPU.
+	/* Nothing to execute: the job has finished (or failed) on the GPU
+	 * while we were resetting it, after drm_sched_stop() had detached the
+	 * scheduler from its done fence. Hand that fence back, so that the job
+	 * completes with the status the GPU gave it: with no fence,
+	 * drm_sched_start() would complete it as cancelled.
 	 */
 	if (!job->jc)
-		return NULL;
+		return dma_fence_get(job->done_fence);
 
 	fence = panfrost_fence_create(pfdev, slot);
 	if (IS_ERR(fence))

-- 
2.55.0

