From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:26:37 +0000
Subject: [PATCH v5 06/17] drm/panfrost: Unwind a failed GPU mapping without
 dropping its pages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-panfrost-long-jobs-v5-6-e7d62045a676@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795886791; l=2423;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=B/OG9Mi1gxkvCDAJITmI6/1lXQ/Ts4PcA1q80c3wpeo=;
 b=uGS/2O8n4GD7GdIWgz7cpX3VADEu/wEUcqoi/DGC2SPMWnZsxkkBxoVBmb5kMEoLK8CcuBR2u
 Tfqy4x6Mf4UDa18p3Q4gEohJSBnYci2xMNiFANMD2uTdtiJXxgSI8mp
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two error paths leave wrong state when a BO mapping fails part-way:
- If mmu_map_sg() fails, panfrost_mmu_map() calls
  drm_gem_shmem_put_pages_locked() without the reservation lock and
  drops pages that shmem->sgt still maps (an imported BO underflows
  pages_use_count). Keep the pages.
- If ops->map_pages() fails, the PTEs that call mapped stay in a VA
  range drm_mm hands out again. Unmap and flush them too.

Tested with a test-only map_pages() failure: before, the pages were
freed under the cached sg table and an imported BO kept 512 PTEs;
after, neither.

Fixes: 4da352cf8fb1 ("drm/panfrost: Handle page mapping failure")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
v4: test result added; no code change.
---
 drivers/gpu/drm/panfrost/panfrost_mmu.c | 16 +++++++++-------
 1 file changed, 9 insertions(+), 7 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_mmu.c b/drivers/gpu/drm/panfrost/panfrost_mmu.c
index e70ae393e..e59a16b68 100644
--- a/drivers/gpu/drm/panfrost/panfrost_mmu.c
+++ b/drivers/gpu/drm/panfrost/panfrost_mmu.c
@@ -442,8 +442,10 @@ static int mmu_map_sg(struct panfrost_device *pfdev, struct panfrost_mmu *mmu,
 
 			ret = ops->map_pages(ops, iova, paddr, pgsize, pgcount, prot,
 				       GFP_KERNEL, &mapped);
-			if (ret)
+			if (ret) {
+				total_mapped += mapped;
 				goto err_unmap_pages;
+			}
 
 			/* Don't get stuck if things have gone wrong */
 			mapped = max(mapped, pgsize);
@@ -459,7 +461,10 @@ static int mmu_map_sg(struct panfrost_device *pfdev, struct panfrost_mmu *mmu,
 	return 0;
 
 err_unmap_pages:
-	mmu_unmap_range(mmu, start_iova, total_mapped);
+	if (total_mapped) {
+		mmu_unmap_range(mmu, start_iova, total_mapped);
+		panfrost_mmu_flush_range(pfdev, mmu, start_iova, total_mapped);
+	}
 	return ret;
 }
 
@@ -483,18 +488,15 @@ int panfrost_mmu_map(struct panfrost_gem_mapping *mapping)
 	if (IS_ERR(sgt))
 		return PTR_ERR(sgt);
 
+	/* shmem->sgt holds the only page reference: keep the pages. */
 	ret = mmu_map_sg(pfdev, mapping->mmu, mapping->mmnode.start << PAGE_SHIFT,
 			 prot, sgt);
 	if (ret)
-		goto err_put_pages;
+		return ret;
 
 	mapping->active = true;
 
 	return 0;
-
-err_put_pages:
-	drm_gem_shmem_put_pages_locked(shmem);
-	return ret;
 }
 
 void panfrost_mmu_unmap(struct panfrost_gem_mapping *mapping)

-- 
2.55.0

