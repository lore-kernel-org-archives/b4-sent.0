From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 09:36:44 +0000
Subject: [PATCH v4 01/17] drm/panfrost: Freeze the reset workqueue during
 system sleep
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-panfrost-long-jobs-v4-1-23579629ceca@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795685806; l=1382;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=6c2Dpu03JGJeqBmpPCQQMuKsg5qJDVUkSb2yqZ0AwZ8=;
 b=kcxN7jyStNOcc+0ERAgPsFBQOcBb441MSYfRB7xv1nj7A4SOYGIzHgZWGnCgiMnfJyZ7ALQ5H
 V0YvcIVTlj3C7puqcE7Pss/PPS7n/+/8oBP2Xdsmi034hh0QWny1NjP
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pm_runtime_force_suspend() can power the GPU off under the timeout
handler or the reset work. Make their workqueue freezable.

Fixes: f3ba91228e8e ("drm/panfrost: Add initial panfrost driver")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-210830@kernel.org/
Closes: https://sashiko.dev/#/patchset/20261113-panfrost-long-jobs-v3-0-80ae78d38f6e@gmail.com?part=13
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
v4: new (Sashiko on v3 01/14 and 13/14). Tested with s2idle entered in
a test-only 8 s hold in both: before, the GPU was runtime suspended
inside panfrost_reset(); after, the freezer waited for the work.
---
 drivers/gpu/drm/panfrost/panfrost_job.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_job.c b/drivers/gpu/drm/panfrost/panfrost_job.c
index 6a604b5da..79b302fef 100644
--- a/drivers/gpu/drm/panfrost/panfrost_job.c
+++ b/drivers/gpu/drm/panfrost/panfrost_job.c
@@ -893,7 +893,7 @@ int panfrost_jm_init(struct panfrost_device *pfdev)
 		return ret;
 	}
 
-	pfdev->reset.wq = alloc_ordered_workqueue("panfrost-reset", 0);
+	pfdev->reset.wq = alloc_ordered_workqueue("panfrost-reset", WQ_FREEZABLE);
 	if (!pfdev->reset.wq)
 		return -ENOMEM;
 	args.timeout_wq = pfdev->reset.wq;

-- 
2.55.0

