From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 09:36:50 +0000
Subject: [PATCH v4 07/17] drm/panfrost: Give back the pages of a heap chunk
 that failed to map
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-panfrost-long-jobs-v4-7-23579629ceca@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795685806; l=3977;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Fy4hIaYtMsYqP1o6pifRn+AqW6XSoeC4gWPuvrzKAb8=;
 b=l3a+kl2lRde1uNeVfvl4CkCvf4V9oB0C0SgeOOCGcsddIEJ2OrJKdG/zxWGeRZyjESLUPuFhQ
 SuMtsAIxIh4Dw2qjUhHcROCdi31J3OsBeWUi3WFZG1EjOuqegVLqVCB
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If growing a heap BO by a 2 MB chunk fails after the chunk's folios
were read, they stay in bo->base.pages without an sg table. The next
fault in the chunk finds them owned and hits the drm_WARN_ON() that
commit b49c35ba0ce1 added.

On those error paths, put the folios read and clear their entries:
whole folios, as the fill loop wrote them, except those a neighbouring
chunk owns.

Tested with a test-only failure after the read: before, the next fault
WARNed for each of the 512 pages; after, none. Folios larger than a
chunk (16K/64K pages) are from reading the code.

Fixes: b49c35ba0ce1 ("drm/panfrost: Fix a page leak in panfrost_mmu_map_fault_addr() when THP is on")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
v4: test result added; no code change.
---
 drivers/gpu/drm/panfrost/panfrost_mmu.c | 40 +++++++++++++++++++++++++++++----
 1 file changed, 36 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_mmu.c b/drivers/gpu/drm/panfrost/panfrost_mmu.c
index e59a16b68..9edf66f6e 100644
--- a/drivers/gpu/drm/panfrost/panfrost_mmu.c
+++ b/drivers/gpu/drm/panfrost/panfrost_mmu.c
@@ -592,6 +592,27 @@ addr_to_mapping(struct panfrost_device *pfdev, int as, u64 addr)
 
 #define NUM_FAULT_PAGES (SZ_2M / PAGE_SIZE)
 
+/* [start, end) is whole folios: it can reach past the 2 MB chunk. */
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
@@ -600,7 +621,7 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 	struct panfrost_gem_object *bo;
 	struct address_space *mapping;
 	struct drm_gem_object *obj;
-	pgoff_t page_offset, nr_pages;
+	pgoff_t page_offset, nr_pages, got_start, got_end;
 	struct sg_table *sgt;
 	struct page **pages;
 
@@ -659,17 +680,22 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 	mapping = bo->base.base.filp->f_mapping;
 	mapping_set_unevictable(mapping);
 
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
@@ -681,14 +707,18 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
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
@@ -715,6 +745,8 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 	dma_unmap_sgtable(pfdev->base.dev, sgt, DMA_BIDIRECTIONAL, 0);
 err_map:
 	sg_free_table(sgt);
+err_put_chunk:
+	panfrost_heap_put_pages(pages, got_start, got_end);
 err_unlock:
 	dma_resv_unlock(obj->resv);
 err_bo:

-- 
2.55.0

