From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 09:02:58 +0000
Subject: [PATCH v3 06/14] drm/panfrost: Give back the pages of a heap chunk
 that failed to map
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-panfrost-long-jobs-v3-6-80ae78d38f6e@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794560572; l=4609;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=+lmAZxQZit8zdJMjwassqRxoaR3AdIthnK1l+a4bwh4=;
 b=YMbMjKnbI4Gaw+kuWWyM6SFMp69LUNafm8+0Rd/bUIo6U+nJTrVOPQ9nntFZksoPzSbXunlpN
 irgB5RDBn1KC2K8OT+sI+g+PSmubeztg/yTCXsX8q97t0JcfytU93UP
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_mmu_map_fault_addr() grows a heap BO by one 2 MB chunk per
fault. If reading the chunk's folios, building its sg table, DMA mapping
it or mapping it on the GPU fails, the folios already read stay in
bo->base.pages while the chunk has no sg table. The next fault in the
chunk reads them again, finds their pages owned and hits

  if (drm_WARN_ON(&pfdev->base, already_owned))
          folio_put(folio);

which commit b49c35ba0ce1 ("drm/panfrost: Fix a page leak in
panfrost_mmu_map_fault_addr() when THP is on") added; before it, pages
already filled in were skipped.

On those error paths, put the folios read and clear their entries. The
range to clear is what the fill loop wrote, whole folios: a folio larger
than 2 MB (possible with 16K or 64K pages) also fills entries of the
neighbouring chunks, and a folio the loop found already owned (by such a
neighbour) is not ours to put.

Tested with 4K pages, where a folio never crosses a chunk; the
larger-folio case is from reading the code.

Fixes: b49c35ba0ce1 ("drm/panfrost: Fix a page leak in panfrost_mmu_map_fault_addr() when THP is on")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_mmu.c | 45 ++++++++++++++++++++++++++++++---
 1 file changed, 41 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_mmu.c b/drivers/gpu/drm/panfrost/panfrost_mmu.c
index efa4a3bb1..e1c4e57d0 100644
--- a/drivers/gpu/drm/panfrost/panfrost_mmu.c
+++ b/drivers/gpu/drm/panfrost/panfrost_mmu.c
@@ -596,6 +596,30 @@ addr_to_mapping(struct panfrost_device *pfdev, int as, u64 addr)
 
 #define NUM_FAULT_PAGES (SZ_2M / PAGE_SIZE)
 
+/*
+ * Put the folios a failed heap fault took and clear their page array entries.
+ * [start, end) covers whole folios, so it can reach past the 2 MB chunk.
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
@@ -604,7 +628,7 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 	struct panfrost_gem_object *bo;
 	struct address_space *mapping;
 	struct drm_gem_object *obj;
-	pgoff_t page_offset, nr_pages;
+	pgoff_t page_offset, nr_pages, got_start, got_end;
 	struct sg_table *sgt;
 	struct page **pages;
 
@@ -663,17 +687,23 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
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
@@ -685,14 +715,18 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
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
@@ -719,6 +753,9 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 	dma_unmap_sgtable(pfdev->base.dev, sgt, DMA_BIDIRECTIONAL, 0);
 err_map:
 	sg_free_table(sgt);
+err_put_chunk:
+	/* The next fault in this chunk must find its page range empty. */
+	panfrost_heap_put_pages(pages, got_start, got_end);
 err_unlock:
 	dma_resv_unlock(obj->resv);
 err_bo:

-- 
2.55.0

