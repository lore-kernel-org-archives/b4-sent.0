From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:26:41 +0000
Subject: [PATCH v5 10/17] drm/panfrost: Don't cancel a job that completed
 during a reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-panfrost-long-jobs-v5-10-e7d62045a676@gmail.com>
References: <20261128-panfrost-long-jobs-v5-0-e7d62045a676@gmail.com>
In-Reply-To: <20261128-panfrost-long-jobs-v5-0-e7d62045a676@gmail.com>
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795886791; l=1339;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=3lUBnktZkSvOacj1VqiKAjZOrqk7CYYBcx6fKO/61xk=;
 b=ZV1U1A/Ko7Q9Ki5j0p0ijKB4bJlUvHH+CnN/C7YOEeSU7aAnpKKudbdsuVUgm/XCaYVXurJDW
 2uxYsF/o/EuATaHRG0QzaKEtOFS/G66dyuakaOKjPTtafDsXbN0mZZ7
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A job that completes during panfrost_reset() has its jc cleared, so
drm_sched_start() cancels it. Return its done fence instead. Depends
on the previous patch. Not reproduced.

Fixes: 03877d621db0 ("drm/scheduler: mark jobs without fence as canceled")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-206581@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
v4: shorter commit message.
---
 drivers/gpu/drm/panfrost/panfrost_job.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index c9bd3555f..a64c33047 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.c
+++ b/drivers/gpu/drm/panfrost/panfrost_job.c
@@ -409,11 +409,9 @@ static struct dma_fence *panfrost_job_run(struct drm_sched_job *sched_job)
 	if (unlikely(job->base.s_fence->finished.error))
 		return NULL;
 
-	/* Nothing to execute: can happen if the job has finished while
-	 * we were resetting the GPU.
-	 */
+	/* Done in the reset: drm_sched_start() cancels it without a fence */
 	if (!job->jc)
-		return NULL;
+		return dma_fence_get(job->done_fence);
 
 	fence = panfrost_fence_create(pfdev, slot);
 	if (IS_ERR(fence))

-- 
2.55.0

