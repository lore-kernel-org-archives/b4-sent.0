From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:48:39 +0000
Subject: [PATCH v2 06/11] drm/panfrost: Give back the pages of a heap chunk
 that failed to map
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-panfrost-long-jobs-v2-6-a06830da3d99@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794473314; l=5223;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=GiYBojJEk+AerOOD5A3CeTX5sdW5+aVhVP91wLrsHZ0=;
 b=SqmKe/QDpdPcA2LHOYhq+Qw2NBDL+UFa9BasxWAG4b6ow0ePlb0TBj4RPgef8f/Av2MMot4r4
 n1zBWxzq4CqCjdf7NAtl5Kes67FpT8IxF5ZqigR8pcyFIoNGo24KxT6
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_mmu_map_fault_addr() grows a heap BO by one 2 MB chunk per
fault. If reading the chunk's folios, building its sg table, DMA mapping
it or mapping it on the GPU fails, the folios that were already read stay
in bo->base.pages, while the chunk's sg table stays empty. The next fault
in that chunk reads the same folios again and finds their pages already
owned:

  if (drm_WARN_ON(&pfdev->base, already_owned))
          folio_put(folio);

Before commit b49c35ba0ce1 ("drm/panfrost: Fix a page leak in
panfrost_mmu_map_fault_addr() when THP is on") the fault path skipped
pages that were already filled in; since then the array is filled a
folio at a time and an already filled page is treated as a bug.

On those error paths, put the folios read for the chunk and clear their
entries, so that a later fault in it starts from an empty range. The
range to clear is the one the fill loop wrote, which is not always the
chunk: the loop aligns down to the start of each folio and fills the
whole folio, so a folio larger than 2 MB (PMD-sized folios with 16K or
64K pages) also fills entries of the neighbouring chunks, and a folio
whose pages the loop found already owned (by such a neighbour) is not
ours to put.

Tested with 4K pages, where the folios are at most 2 MB and never cross
a chunk; the larger-folio case is from reading the code.

Fixes: b49c35ba0ce1 ("drm/panfrost: Fix a page leak in panfrost_mmu_map_fault_addr() when THP is on")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_mmu.c | 51 ++++++++++++++++++++++++++++++---
 1 file changed, 47 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_mmu.c b/drivers/gpu/drm/panfrost/panfrost_mmu.c
index 35fb86b6b..684735937 100644
--- a/drivers/gpu/drm/panfrost/panfrost_mmu.c
+++ b/drivers/gpu/drm/panfrost/panfrost_mmu.c
@@ -603,6 +603,32 @@ addr_to_mapping(struct panfrost_device *pfdev, int as, u64 addr)
 
 #define NUM_FAULT_PAGES (SZ_2M / PAGE_SIZE)
 
+/*
+ * Put the folios that a failed heap fault took and clear the page array
+ * entries it filled for them. [start, end) is what the fault filled: whole
+ * folios, since it fills the array a folio at a time, which can reach past
+ * the 2 MB chunk when a folio is larger than the chunk.
+ */
+static void panfrost_heap_put_pages(struct page **pages, pgoff_t start,
+				    pgoff_t end)
+{
+	while (start < end) {
+		struct folio *folio;
+
+		if (!pages[start]) {
+			start++;
+			continue;
+		}
+
+		folio = page_folio(pages[start]);
+		do {
+			pages[start++] = NULL;
+		} while (start < end && pages[start] &&
+			 page_folio(pages[start]) == folio);
+		folio_put(folio);
+	}
+}
+
 static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 				       u64 addr)
 {
@@ -611,7 +637,7 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 	struct panfrost_gem_object *bo;
 	struct address_space *mapping;
 	struct drm_gem_object *obj;
-	pgoff_t page_offset, nr_pages;
+	pgoff_t page_offset, nr_pages, got_start, got_end;
 	struct sg_table *sgt;
 	struct page **pages;
 
@@ -670,17 +696,23 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 	mapping = bo->base.base.filp->f_mapping;
 	mapping_set_unevictable(mapping);
 
+	/* The page array range whose folio references this fault takes. */
+	got_start = page_offset;
+	got_end = page_offset;
+
 	for (pgoff_t pg = page_offset; pg < page_offset + NUM_FAULT_PAGES;) {
 		bool already_owned = false;
 		struct folio *folio;
+		pgoff_t first;
 
 		folio = shmem_read_folio(mapping, pg);
 		if (IS_ERR(folio)) {
 			ret = PTR_ERR(folio);
-			goto err_unlock;
+			goto err_put_chunk;
 		}
 
 		pg &= ~(folio_nr_pages(folio) - 1);
+		first = pg;
 		for (u32 i = 0; i < folio_nr_pages(folio) && pg < nr_pages; i++) {
 			if (pages[pg])
 				already_owned = true;
@@ -692,14 +724,18 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 		 * there's no valid reason for a folio range to be partially
 		 * populated.
 		 */
-		if (drm_WARN_ON(&pfdev->base, already_owned))
+		if (drm_WARN_ON(&pfdev->base, already_owned)) {
 			folio_put(folio);
+		} else {
+			got_start = min(got_start, first);
+			got_end = max(got_end, pg);
+		}
 	}
 
 	ret = sg_alloc_table_from_pages(sgt, pages + page_offset,
 					NUM_FAULT_PAGES, 0, SZ_2M, GFP_KERNEL);
 	if (ret)
-		goto err_unlock;
+		goto err_put_chunk;
 
 	ret = dma_map_sgtable(pfdev->base.dev, sgt, DMA_BIDIRECTIONAL, 0);
 	if (ret)
@@ -726,6 +762,13 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 	dma_unmap_sgtable(pfdev->base.dev, sgt, DMA_BIDIRECTIONAL, 0);
 err_map:
 	sg_free_table(sgt);
+err_put_chunk:
+	/*
+	 * Give back the folios read for this chunk, so that the next fault in
+	 * it (the chunk has no sg table yet) starts from an empty page range
+	 * instead of finding it partly owned.
+	 */
+	panfrost_heap_put_pages(pages, got_start, got_end);
 err_unlock:
 	dma_resv_unlock(obj->resv);
 err_bo:

-- 
2.55.0

