From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 09:36:58 +0000
Subject: [PATCH v4 15/17] drm/panfrost: Keep the job interrupts masked
 during a reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-panfrost-long-jobs-v4-15-23579629ceca@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795685806; l=1694;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=6YqPIH+zOU03hye/YOaqcl9r7BbJ+n1uwdvcsqhKcTY=;
 b=o2LHgilBuUxSuZE91SSgqBhGXilMU246E48lGDIfGUWbyBe8W13i1lgiLkptMtxUsc1za1FMc
 bt/uQyVddFGAYTpsj4d2171fPfw3z3+jPVyk1295WapQwfxIPWR/fSx
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_reset() masks the job interrupts without setting
PANFROST_COMP_BIT_JOB, so a running IRQ thread unmasks them. Use
panfrost_jm_suspend_irq(), and mask again after its synchronize_irq()
for a thread that tested the bit just before.

Fixes: 1d0cab5461d7 ("drm/panfrost: Make sure job interrupts are masked before resetting")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://sashiko.dev/#/patchset/20261113-panfrost-long-jobs-v3-0-80ae78d38f6e@gmail.com?part=8
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
v4: new (Sashiko on v3 08/14 and 13/14). Tested with a test-only hold
in the IRQ thread: JOB_INT_MASK read 0x70007 before, 0 after.
---
 drivers/gpu/drm/panfrost/panfrost_job.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index 74cc3dd02..7a2503f4e 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.c
+++ b/drivers/gpu/drm/panfrost/panfrost_job.c
@@ -459,6 +459,7 @@ void panfrost_jm_suspend_irq(struct panfrost_device *pfdev)
 
 	job_write(pfdev, JOB_INT_MASK, 0);
 	synchronize_irq(pfdev->js->irq);
+	job_write(pfdev, JOB_INT_MASK, 0);
 }
 
 static void panfrost_job_handle_err(struct panfrost_device *pfdev,
@@ -696,8 +697,7 @@ panfrost_reset(struct panfrost_device *pfdev,
 	/* Mask job interrupts and synchronize to make sure we won't be
 	 * interrupted during our reset.
 	 */
-	job_write(pfdev, JOB_INT_MASK, 0);
-	synchronize_irq(pfdev->js->irq);
+	panfrost_jm_suspend_irq(pfdev);
 
 	spin_lock(&pfdev->js->job_lock);
 	for (i = 0; i < NUM_JOB_SLOTS; i++) {

-- 
2.55.0

