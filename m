From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:48:34 +0000
Subject: [PATCH v2 01/11] drm/panfrost: Power the GPU up for a reset queued
 from the MMU code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-panfrost-long-jobs-v2-1-a06830da3d99@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794473314; l=2612;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=3Nwfj5PjtSEDNrdV40YewE7S010LHXjG4GEcXIttwyU=;
 b=0ryBwxlYAwCmZkVAh7K+YyhyJgkV5eo4lx5zT8nt16/VZPa84kdzHsOr1c/ufAt9CWA/boFco
 dNMp9BI+aEeDpLRe9IHtJnI1DlLh5dvyibxixzOEuNV0jLs5xz9Xlka
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_reset_work() calls panfrost_reset() without a runtime PM
reference. The work is queued by panfrost_device_schedule_reset(), which
wait_ready() calls when the AS_ACTIVE bit is stuck, from MMU operations
whose callers drop their own runtime PM reference right after. The work
shares the ordered reset workqueue with the scheduler timeout handlers, so
it can run well after it was queued. If the GPU has gone idle and been
runtime suspended in between, panfrost_reset() writes JOB_INT_MASK and the
job slot registers of a powered-off GPU, which is a synchronous external
abort on arm64.

Take a runtime PM reference in the work, resuming the GPU if needed, and
drop it after the reset. If the GPU cannot be resumed (runtime PM is
disabled during system sleep), no job is running on it and
panfrost_device_runtime_resume() resets it on the way back up, so just
clear the pending flag. Resuming instead of skipping the reset when the
GPU is suspended keeps jobs that a concurrent resume queued behind the
pending flag from waiting for a reset that never comes.

Found by code review only (Sashiko); not reproduced.

Fixes: f9ab9c66f080 ("drm/panfrost: Reset the GPU when the AS_ACTIVE bit is stuck")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-206548@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_job.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index 3a46dd61c..0c2fda80c 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.c
+++ b/drivers/gpu/drm/panfrost/panfrost_job.c
@@ -810,7 +810,21 @@ static void panfrost_reset_work(struct work_struct *work)
 	struct panfrost_device *pfdev;
 
 	pfdev = container_of(work, struct panfrost_device, reset.work);
+
+	/* The work can run long after it was queued, when the GPU has gone
+	 * idle and been runtime suspended. Power it up for the reset: its
+	 * registers are not accessible while it is suspended. If it cannot
+	 * be resumed (runtime PM is disabled during system sleep), there is
+	 * no job on it, and panfrost_device_runtime_resume() resets it when
+	 * it comes back up.
+	 */
+	if (pm_runtime_resume_and_get(pfdev->base.dev)) {
+		atomic_set(&pfdev->reset.pending, 0);
+		return;
+	}
+
 	panfrost_reset(pfdev, NULL);
+	pm_runtime_put_autosuspend(pfdev->base.dev);
 }
 
 static const struct drm_sched_backend_ops panfrost_sched_ops = {

-- 
2.55.0

