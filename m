From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:48:38 +0000
Subject: [PATCH v2 05/11] drm/panfrost: Unwind a failed GPU mapping without
 dropping its pages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-panfrost-long-jobs-v2-5-a06830da3d99@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794473314; l=3059;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=cXmdq7u+D1jQoUrPnQYz4g1arOg/4riZ6jjCd0tgiX0=;
 b=mBwghWTfu7WsN0fYkW2YkvYAv5kRJjyOPIe4wMbT5UFf/oUbjjT51kg2JyYZtwLB+OQEHYSdi
 7mlmu6CWHdICiTrFpkEQfJoaV+hlnzdsMt0uNtWioBH7JTjbBiPQ7eI
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two error paths of a BO mapping leave the wrong state behind when an
allocation fails part-way (memory cgroup at its limit, io-pgtable
running out of memory):

- When mmu_map_sg() fails, panfrost_mmu_map() calls
  drm_gem_shmem_put_pages_locked(). The only page reference
  drm_gem_shmem_get_pages_sgt() took belongs to the sg table cached in
  shmem->sgt, which the object releases when it is freed, so this drops
  pages that shmem->sgt still maps (for an imported BO it underflows
  pages_use_count). It also runs without the reservation lock that
  helper asserts. Keep the pages and just return the error.

- When ops->map_pages() fails, mmu_map_sg() unmaps what the earlier
  calls mapped, but not the part the failing call itself had mapped
  before it failed (map_pages() reports it in @mapped). Those PTEs stay
  behind in a VA range that drm_mm hands out again, and the next mapping
  there finds them. Unmap that part too, and flush the unmapped range.

Fixes: 4da352cf8fb1 ("drm/panfrost: Handle page mapping failure")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_mmu.c | 22 +++++++++++++++-------
 1 file changed, 15 insertions(+), 7 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_mmu.c b/drivers/gpu/drm/panfrost/panfrost_mmu.c
index 971552c42..35fb86b6b 100644
--- a/drivers/gpu/drm/panfrost/panfrost_mmu.c
+++ b/drivers/gpu/drm/panfrost/panfrost_mmu.c
@@ -442,8 +442,11 @@ static int mmu_map_sg(struct panfrost_device *pfdev, struct panfrost_mmu *mmu,
 
 			ret = ops->map_pages(ops, iova, paddr, pgsize, pgcount, prot,
 				       GFP_KERNEL, &mapped);
-			if (ret)
+			if (ret) {
+				/* Unwind the pages this call mapped too. */
+				total_mapped += mapped;
 				goto err_unmap_pages;
+			}
 
 			/* Don't get stuck if things have gone wrong */
 			mapped = max(mapped, pgsize);
@@ -459,7 +462,10 @@ static int mmu_map_sg(struct panfrost_device *pfdev, struct panfrost_mmu *mmu,
 	return 0;
 
 err_unmap_pages:
-	mmu_unmap_range(mmu, start_iova, total_mapped);
+	if (total_mapped) {
+		mmu_unmap_range(mmu, start_iova, total_mapped);
+		panfrost_mmu_flush_range(pfdev, mmu, start_iova, total_mapped);
+	}
 	return ret;
 }
 
@@ -483,18 +489,20 @@ int panfrost_mmu_map(struct panfrost_gem_mapping *mapping)
 	if (IS_ERR(sgt))
 		return PTR_ERR(sgt);
 
+	/*
+	 * On failure keep the pages: the sg table cached in the shmem object
+	 * owns the only page reference drm_gem_shmem_get_pages_sgt() took,
+	 * and the object frees both. Dropping it here (without the reservation
+	 * lock) released pages that shmem->sgt still maps.
+	 */
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

