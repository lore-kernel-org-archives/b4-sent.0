From: Brendan King <Brendan.King@imgtec.com>
Date: Tue, 18 Mar 2025 14:53:13 +0000
Subject: [PATCH] drm/imagination: take paired job reference
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250318-ddkopsrc-1337-use-after-free-in-pvr_queue_prepare_job-v1-1-80fb30d044a6@imgtec.com>
X-B4-Tracking: v=1; b=H4sIANiI2WcC/x2N2wrCMBAFf6Xsswu5qBV/RSTkstEoJOnGFKH03
 w0+Dmc4s0EjTtTgOm3AtKaWSh4gDxP4p80PwhQGgxLqJLS8YAjvUht7lFrP2BuhjR9ijEzDzVh
 XNkunTqYyVctkXsWhPEfn56MTXgkY32OL6fvv3u77/gOewIWDhwAAAA==
X-Change-ID: 20250318-ddkopsrc-1337-use-after-free-in-pvr_queue_prepare_job-16fbc74b0c20
To: Frank Binns <frank.binns@imgtec.com>, 
 Matt Coster <matt.coster@imgtec.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Boris Brezillon <boris.brezillon@collabora.com>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Brendan King <brendan.king@imgtec.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742309603; l=2606;
 i=Brendan.King@imgtec.com; s=20250203; h=from:subject:message-id;
 bh=iRO8TwqpOWn8X5jFM/tEN7yZ9E4/c1t772uWrRZbV/s=;
 b=6U0jpX6Ay9Wdn4uPme1Lovgv3I7RKQNnlFylAxRR64RsGqneC6U92TnG6vnE11fCuimMPMq/2
 lGiXF8TO8xmAGhsqXIJIL204XFaee2fLAqQRPg5/R2StCJjyjKGC7v3
X-Developer-Key: i=Brendan.King@imgtec.com; a=ed25519;
 pk=i3JvC3unEBLW+4r5s/aEWQZFsRCWaCBrWdFbMXIXCqg=
X-Endpoint-Received: by B4 Relay for Brendan.King@imgtec.com/20250203 with auth_id=335
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For paired jobs, have the fragment job take a reference on the
geometry job, so that the geometry job cannot be freed until
the fragment job has finished with it.

The geometry job structure is accessed when the fragment job is being
prepared by the GPU scheduler. Taking the reference prevents the
geometry job being freed until the fragment job no longer requires it.

Fixes a use after free bug detected by KASAN:

[  124.256386] BUG: KASAN: slab-use-after-free in pvr_queue_prepare_job+0x108/0x868 [powervr]
[  124.264893] Read of size 1 at addr ffff0000084cb960 by task kworker/u16:4/63

Cc: stable@vger.kernel.org
Fixes: eaf01ee5ba28 ("drm/imagination: Implement job submission and scheduling")
Signed-off-by: Brendan King <brendan.king@imgtec.com>
---
 drivers/gpu/drm/imagination/pvr_job.c   | 7 +++++++
 drivers/gpu/drm/imagination/pvr_queue.c | 4 ++++
 2 files changed, 11 insertions(+)

diff --git a/drivers/gpu/drm/imagination/pvr_job.c b/drivers/gpu/drm/imagination/pvr_job.c
index 1cdb3cfd058d7db573337a2b4f6895ee4922f9a9..59b334d094fa826f26668d98561e956ec9c51428 100644
--- a/drivers/gpu/drm/imagination/pvr_job.c
+++ b/drivers/gpu/drm/imagination/pvr_job.c
@@ -671,6 +671,13 @@ pvr_jobs_link_geom_frag(struct pvr_job_data *job_data, u32 *job_count)
 		geom_job->paired_job = frag_job;
 		frag_job->paired_job = geom_job;
 
+		/* The geometry job pvr_job structure is used when the fragment
+		 * job is being prepared by the GPU scheduler. Have the fragment
+		 * job hold a reference on the geometry job to prevent it being
+		 * freed until the fragment job has finished with it.
+		 */
+		pvr_job_get(geom_job);
+
 		/* Skip the fragment job we just paired to the geometry job. */
 		i++;
 	}
diff --git a/drivers/gpu/drm/imagination/pvr_queue.c b/drivers/gpu/drm/imagination/pvr_queue.c
index 21c185d18bb2e0569bd6e12832a74e38137bd48a..6431f6b654a2e60b86a46bd8571eb9f8133c4b53 100644
--- a/drivers/gpu/drm/imagination/pvr_queue.c
+++ b/drivers/gpu/drm/imagination/pvr_queue.c
@@ -856,6 +856,10 @@ static void pvr_queue_free_job(struct drm_sched_job *sched_job)
 	struct pvr_job *job = container_of(sched_job, struct pvr_job, base);
 
 	drm_sched_job_cleanup(sched_job);
+
+	if (job->type == DRM_PVR_JOB_TYPE_FRAGMENT && job->paired_job)
+		pvr_job_put(job->paired_job);
+
 	job->paired_job = NULL;
 	pvr_job_put(job);
 }

---
base-commit: 96c85e428ebaeacd2c640eba075479ab92072ccd
change-id: 20250318-ddkopsrc-1337-use-after-free-in-pvr_queue_prepare_job-16fbc74b0c20

Best regards,
-- 
Brendan King <Brendan.King@imgtec.com>

