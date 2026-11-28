From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:26:46 +0000
Subject: [PATCH v5 15/17] drm/panfrost: Keep the job interrupts masked
 during a reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-panfrost-long-jobs-v5-15-e7d62045a676@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795886791; l=2619;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=MmcXjqwywSypeIS6dJaP2eZDGN/CFfrEz6TGp2P6oUg=;
 b=/GxLkQAysmG9mjRZN/4C16ImOFWnEPLI/bxF3k+PKAL5gZTRIhmkcbuswGqADh2LiwcDv7OTx
 m/WzZRrmIxSBT3LRh/i+gv+64qQ6R2wzCZZtg8Q3TG/6TOHMj550dvY
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_reset() masks the job interrupts without setting
PANFROST_COMP_BIT_JOB, so a running IRQ thread unmasks them. Use
panfrost_jm_suspend_irq() there.

Take job_lock around its mask and set_bit, and around the IRQ
thread's bit test and unmask: a thread that tested the bit before
could otherwise unmask after it, and the hard IRQ handler returns
IRQ_NONE without masking while the bit is set.

Fixes: 1d0cab5461d7 ("drm/panfrost: Make sure job interrupts are masked before resetting")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://sashiko.dev/#/patchset/20261113-panfrost-long-jobs-v3-0-80ae78d38f6e@gmail.com?part=8
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
v5: job_lock instead of a second mask write (Sashiko on v4). With a
test-only hold in the IRQ thread after its bit test and a job
interrupt pending, v4 unmasked after the reset's mask (100005
IRQ_NONE, IRQ disabled); v5 did not in 8 of 8 resets (3 IRQ_NONE in
all, at most one per reset).
v4: new (Sashiko on v3 08/14 and 13/14).
---
 drivers/gpu/drm/panfrost/panfrost_job.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index 74cc3dd02..ebdf16968 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.c
+++ b/drivers/gpu/drm/panfrost/panfrost_job.c
@@ -455,9 +455,11 @@ void panfrost_jm_enable_interrupts(struct panfrost_device *pfdev)
 
 void panfrost_jm_suspend_irq(struct panfrost_device *pfdev)
 {
+	spin_lock(&pfdev->js->job_lock);
+	job_write(pfdev, JOB_INT_MASK, 0);
 	set_bit(PANFROST_COMP_BIT_JOB, pfdev->is_suspended);
+	spin_unlock(&pfdev->js->job_lock);
 
-	job_write(pfdev, JOB_INT_MASK, 0);
 	synchronize_irq(pfdev->js->irq);
 }
 
@@ -696,8 +698,7 @@ panfrost_reset(struct panfrost_device *pfdev,
 	/* Mask job interrupts and synchronize to make sure we won't be
 	 * interrupted during our reset.
 	 */
-	job_write(pfdev, JOB_INT_MASK, 0);
-	synchronize_irq(pfdev->js->irq);
+	panfrost_jm_suspend_irq(pfdev);
 
 	spin_lock(&pfdev->js->job_lock);
 	for (i = 0; i < NUM_JOB_SLOTS; i++) {
@@ -860,8 +861,10 @@ static irqreturn_t panfrost_jm_irq_handler_thread(int irq, void *data)
 	panfrost_jm_handle_irqs(pfdev);
 
 	/* Enable interrupts only if we're not about to get suspended */
+	spin_lock(&pfdev->js->job_lock);
 	if (!test_bit(PANFROST_COMP_BIT_JOB, pfdev->is_suspended))
 		job_write(pfdev, JOB_INT_MASK, ALL_JS_INT_MASK);
+	spin_unlock(&pfdev->js->job_lock);
 
 	return IRQ_HANDLED;
 }

-- 
2.55.0

