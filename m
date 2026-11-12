From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:48:40 +0000
Subject: [PATCH v2 07/11] drm/panfrost: Don't signal a job cancelled from
 _NEXT at a reset as done
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-panfrost-long-jobs-v2-7-a06830da3d99@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794473314; l=3871;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=gJ9MHP9WJHKJVhxNHkpa2xRnP84nJEjxexYJc8IDTCc=;
 b=/0fxxlblZoUiR4o6g+r0j1xdsNquO7AyYG5+0CkKLlg9l6VkQLdYMgP9kX4WmfXMyGCnCqZYP
 ZfYIRi5gS0zAmUapDsC5dZi46wUH5kUTnBn2w2047wppqlOfRsNlECJ
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_reset() cancels the job waiting in each slot's _NEXT registers
with JS_COMMAND_NOP and soft-stops the running one. If the running job
finishes instead of stopping, its DONE interrupt is handled by
panfrost_jm_handle_irqs() before the reset. panfrost_jm_handle_irq()
dequeues it, which moves the cancelled job to the head of the slot, then
finds both subslots inactive and takes that job for done as well: when
a job completes, the job manager starts the _NEXT one without waiting
for the interrupt, so a job left on an inactive slot is normally one
that has finished too. The cancelled job gets its jc cleared and its
done fence signalled without having run: drm_sched_resubmit_jobs() does
not run it again, and it completes with -ECANCELED although nothing was
wrong with it.

The Arm driver checks JS_HEAD_NEXT after writing the NOP: if it still
holds the job, the job has not started and is evicted; if it reads zero,
the job manager had already moved the job to the running subslot. Do the
same: take an evicted job off the slot while the remaining interrupts
are handled, and put it back afterwards, so that it is restarted with
the other jobs.

Found by code review (Sashiko) of the next patches, which make the
soft-stop wait longer and the window wider. Not reproduced.

Fixes: 030761e097b4 ("drm/panfrost: Queue jobs on the hardware")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-206581@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_job.c | 24 ++++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index 0c2fda80c..418a91a31 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.c
+++ b/drivers/gpu/drm/panfrost/panfrost_job.c
@@ -659,6 +659,7 @@ static void
 panfrost_reset(struct panfrost_device *pfdev,
 	       struct drm_sched_job *bad)
 {
+	struct panfrost_job *evicted[NUM_JOB_SLOTS] = {};
 	u32 js_state, js_state_mask = 0xffffffff;
 	unsigned int i, j;
 	bool cookie;
@@ -694,11 +695,28 @@ panfrost_reset(struct panfrost_device *pfdev,
 	job_write(pfdev, JOB_INT_MASK, 0);
 	synchronize_irq(pfdev->js->irq);
 
+	spin_lock(&pfdev->js->job_lock);
 	for (i = 0; i < NUM_JOB_SLOTS; i++) {
 		/* Cancel the next job and soft-stop the running job. */
 		job_write(pfdev, JS_COMMAND_NEXT(i), JS_COMMAND_NOP);
+
+		/* A job still in the _NEXT registers after the NOP has not
+		 * started and will not. Take it off the slot until the
+		 * remaining interrupts are handled: if the running job
+		 * finishes instead of stopping, panfrost_jm_handle_irq() finds
+		 * both subslots inactive and takes the job left on the slot
+		 * for done too, and it would be signalled without having run.
+		 */
+		if (pfdev->jobs[i][1] &&
+		    (job_read(pfdev, JS_HEAD_NEXT_LO(i)) ||
+		     job_read(pfdev, JS_HEAD_NEXT_HI(i)))) {
+			evicted[i] = pfdev->jobs[i][1];
+			pfdev->jobs[i][1] = NULL;
+		}
+
 		job_write(pfdev, JS_COMMAND(i), JS_COMMAND_SOFT_STOP);
 	}
+	spin_unlock(&pfdev->js->job_lock);
 
 	/* Wait at most 10ms for soft-stops to complete */
 	ret = readl_poll_timeout(pfdev->iomem + JOB_INT_JS_STATE, js_state,
@@ -720,6 +738,12 @@ panfrost_reset(struct panfrost_device *pfdev,
 	 */
 	spin_lock(&pfdev->js->job_lock);
 	for (i = 0; i < NUM_JOB_SLOTS; i++) {
+		/* Put the evicted jobs back, they are restarted like the
+		 * others.
+		 */
+		if (evicted[i])
+			pfdev->jobs[i][pfdev->jobs[i][0] ? 1 : 0] = evicted[i];
+
 		for (j = 0; j < ARRAY_SIZE(pfdev->jobs[0]) && pfdev->jobs[i][j]; j++) {
 			if (pfdev->jobs[i][j]->requirements & PANFROST_JD_REQ_CYCLE_COUNT ||
 			    pfdev->jobs[i][j]->is_profiled)

-- 
2.55.0

