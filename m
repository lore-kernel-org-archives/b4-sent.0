From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 09:02:53 +0000
Subject: [PATCH v3 01/14] drm/panfrost: Power the GPU up for a reset queued
 from the MMU code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-panfrost-long-jobs-v3-1-80ae78d38f6e@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794560572; l=3976;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=BH2Iap6Du+xzEbuzT73XcwV5IKrRxeZY/aiArdm7A40=;
 b=XCIY3gcj+fK+XvOK25+9FKZ3Q4s+XSdMKjzm+h5v5SwKNn2XttAhQvEjlD+C0r6vZNUvXGzQG
 q2z5gJytxgtCeTy+1NGCzCLjuuBW6beJJmPtbKuMQ0xwVdF52DnXghm
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_reset_work() calls panfrost_reset() without a runtime PM
reference. wait_ready() queues it when AS_ACTIVE is stuck, from MMU
operations whose callers drop their PM reference right after, and it
shares the ordered reset workqueue with the scheduler timeout handlers,
so it can run late. If the GPU was runtime suspended in between,
panfrost_reset() writes the registers of a powered-off GPU: a
synchronous external abort on arm64.

Take a runtime PM reference in the work. pm_runtime_force_suspend()
ignores the usage count, so also disable the work across system sleep
and queue it again on resume if a reset is still pending. If the GPU
cannot be resumed, no job is running on it and
panfrost_device_runtime_resume() resets it later, so just clear the
pending flag. Skipping the reset on a suspended GPU instead would leave
jobs that a concurrent resume queued behind the pending flag waiting.

Found by code review (Sashiko). Not reproduced.

Fixes: f9ab9c66f080 ("drm/panfrost: Reset the GPU when the AS_ACTIVE bit is stuck")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-206548@kernel.org/
Closes: https://lore.kernel.org/all/sashiko-outbox-210830@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_device.c | 26 ++++++++++++++++++++++++--
 drivers/gpu/drm/panfrost/panfrost_job.c    | 11 +++++++++++
 2 files changed, 35 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_device.c b/drivers/gpu/drm/panfrost/panfrost_device.c
index 40eda3612..2c11a6721 100644
--- a/drivers/gpu/drm/panfrost/panfrost_device.c
+++ b/drivers/gpu/drm/panfrost/panfrost_device.c
@@ -567,7 +567,7 @@ static int panfrost_device_runtime_suspend(struct device *dev)
 	return 0;
 }
 
-static int panfrost_device_resume(struct device *dev)
+static int panfrost_device_power_up(struct device *dev)
 {
 	struct panfrost_device *pfdev = dev_get_drvdata(dev);
 	int ret;
@@ -604,14 +604,36 @@ static int panfrost_device_resume(struct device *dev)
 	return ret;
 }
 
+static void panfrost_device_enable_reset(struct panfrost_device *pfdev)
+{
+	enable_work(&pfdev->reset.work);
+	if (atomic_read(&pfdev->reset.pending))
+		queue_work(pfdev->reset.wq, &pfdev->reset.work);
+}
+
+static int panfrost_device_resume(struct device *dev)
+{
+	int ret = panfrost_device_power_up(dev);
+
+	panfrost_device_enable_reset(dev_get_drvdata(dev));
+	return ret;
+}
+
 static int panfrost_device_suspend(struct device *dev)
 {
 	struct panfrost_device *pfdev = dev_get_drvdata(dev);
 	int ret;
 
+	/* pm_runtime_force_suspend() ignores the reset work's runtime PM
+	 * reference: keep the work off the GPU until resume.
+	 */
+	disable_work_sync(&pfdev->reset.work);
+
 	ret = pm_runtime_force_suspend(dev);
-	if (ret)
+	if (ret) {
+		panfrost_device_enable_reset(pfdev);
 		return ret;
+	}
 
 	if (pfdev->comp->pm_features & BIT(GPU_PM_CLK_DIS))
 		panfrost_clks_disable(pfdev, false);
diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index 3a46dd61c..7319511db 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.c
+++ b/drivers/gpu/drm/panfrost/panfrost_job.c
@@ -810,7 +810,18 @@ static void panfrost_reset_work(struct work_struct *work)
 	struct panfrost_device *pfdev;
 
 	pfdev = container_of(work, struct panfrost_device, reset.work);
+
+	/* The GPU may have been runtime suspended since the work was queued.
+	 * If it cannot be resumed, no job is on it, and
+	 * panfrost_device_runtime_resume() resets it later.
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

