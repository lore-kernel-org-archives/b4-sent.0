From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:44:58 +0000
Subject: [PATCH 3/7] drm/panfrost: Give back the pages of a heap chunk that
 failed to map
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-panfrost-long-jobs-v1-3-24508939ae8d@gmail.com>
References: <20261110-panfrost-long-jobs-v1-0-24508939ae8d@gmail.com>
In-Reply-To: <20261110-panfrost-long-jobs-v1-0-24508939ae8d@gmail.com>
To: David Airlie <airlied@gmail.com>, 
 Thomas Zimmermann <tzimmermann@suse.de>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Steven Price <steven.price@arm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Simona Vetter <simona@ffwll.ch>, 
 Maxime Ripard <mripard@kernel.org>, 
 Boris Brezillon <boris.brezillon@collabora.com>
Cc: linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794296695; l=3323;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=oQpWmLCqf1iAHBCQa+93x7LSuBekHjA6s9/N4mAhsDQ=;
 b=q8FxM+RVA8I02+Ov5R2YmLbImHVeteBSHQilAwpzNNl3kdGphbWOGLak3vslgyHAysQdOCuyP
 qafHNoVHmzECdLI1FfCNx6b0eBsKqBMZ0VgOtJ9nefilrj9qgUeY6uS
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
entries, so that a later fault in it starts from an empty range.

Fixes: b49c35ba0ce1 ("drm/panfrost: Fix a page leak in panfrost_mmu_map_fault_addr() when THP is on")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_mmu.c | 34 +++++++++++++++++++++++++++++++--
 1 file changed, 32 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_mmu.c b/drivers/gpu/drm/panfrost/panfrost_mmu.c
index ba37da499..13728b0c4 100644
--- a/drivers/gpu/drm/panfrost/panfrost_mmu.c
+++ b/drivers/gpu/drm/panfrost/panfrost_mmu.c
@@ -597,6 +597,28 @@ addr_to_mapping(struct panfrost_device *pfdev, int as, u64 addr)
 
 #define NUM_FAULT_PAGES (SZ_2M / PAGE_SIZE)
 
+static void panfrost_heap_put_chunk(struct page **pages, pgoff_t start,
+				    pgoff_t end)
+{
+	pgoff_t pg = start;
+
+	while (pg < end) {
+		struct folio *folio;
+		pgoff_t n;
+
+		if (!pages[pg]) {
+			pg++;
+			continue;
+		}
+
+		folio = page_folio(pages[pg]);
+		n = folio_nr_pages(folio);
+		for (pgoff_t i = 0; i < n && pg < end; i++)
+			pages[pg++] = NULL;
+		folio_put(folio);
+	}
+}
+
 static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 				       u64 addr)
 {
@@ -671,7 +693,7 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 		folio = shmem_read_folio(mapping, pg);
 		if (IS_ERR(folio)) {
 			ret = PTR_ERR(folio);
-			goto err_unlock;
+			goto err_put_chunk;
 		}
 
 		pg &= ~(folio_nr_pages(folio) - 1);
@@ -693,7 +715,7 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 	ret = sg_alloc_table_from_pages(sgt, pages + page_offset,
 					NUM_FAULT_PAGES, 0, SZ_2M, GFP_KERNEL);
 	if (ret)
-		goto err_unlock;
+		goto err_put_chunk;
 
 	ret = dma_map_sgtable(pfdev->base.dev, sgt, DMA_BIDIRECTIONAL, 0);
 	if (ret)
@@ -720,6 +742,14 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 	dma_unmap_sgtable(pfdev->base.dev, sgt, DMA_BIDIRECTIONAL, 0);
 err_map:
 	sg_free_table(sgt);
+err_put_chunk:
+	/*
+	 * Give back the folios read for this chunk, so that the next fault in
+	 * it (the chunk has no sg table yet) starts from an empty page range
+	 * instead of finding it partly owned.
+	 */
+	panfrost_heap_put_chunk(pages, page_offset,
+				min_t(pgoff_t, page_offset + NUM_FAULT_PAGES, nr_pages));
 err_unlock:
 	dma_resv_unlock(obj->resv);
 err_bo:

-- 
2.55.0

