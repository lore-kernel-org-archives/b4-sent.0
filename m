From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 09:02:59 +0000
Subject: [PATCH v3 07/14] drm/panfrost: Don't WARN for a heap folio a
 neighbouring chunk filled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-panfrost-long-jobs-v3-7-80ae78d38f6e@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794560572; l=2082;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=XXpcQcwG3g1fcEh8QcoBhKkfE7vf6D6K3x6svd1LylY=;
 b=h24WMmGbJQWEvkd4lNCwZUt2t6Na3VbsRTXSdti7GXlmt9LZFYiPro+0t5wBxGGJS1bEAyRs2
 MHqcW4O03xpCBr+GDDSAkt5QptP5kpvhzniqn1ZTH4Iq840G9/abmgn
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_mmu_map_fault_addr() fills the page array of a heap BO a whole
folio at a time and warns when a page of the folio is already filled in.
With 16K or 64K pages, the THP mount panfrost uses can return folios
larger than the 2 MB fault chunk (up to 32 MB and 128 MB). The first
fault in such a folio fills the entries of the neighbouring chunks too,
and every later fault in those chunks WARNs, although dropping the extra
folio reference, as it does, is all it has to do.

Warn only for a folio that fits in the chunk: only an earlier fault in
the same chunk can have filled its pages, which is a bug.

Not reproduced: with 4K pages, as here, a folio never crosses a chunk.

Fixes: b49c35ba0ce1 ("drm/panfrost: Fix a page leak in panfrost_mmu_map_fault_addr() when THP is on")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-210837@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_mmu.c | 10 ++++++----
 1 file changed, 6 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_mmu.c b/drivers/gpu/drm/panfrost/panfrost_mmu.c
index e1c4e57d0..2cf67d932 100644
--- a/drivers/gpu/drm/panfrost/panfrost_mmu.c
+++ b/drivers/gpu/drm/panfrost/panfrost_mmu.c
@@ -711,11 +711,13 @@ static int panfrost_mmu_map_fault_addr(struct panfrost_device *pfdev, int as,
 			pages[pg++] = folio_page(folio, i);
 		}
 
-		/* We always fill the page array at a folio granularity so
-		 * there's no valid reason for a folio range to be partially
-		 * populated.
+		/* We always fill the page array at a folio granularity, so a
+		 * folio is already owned only if it is larger than the chunk
+		 * and the fault of a neighbouring chunk filled it.
 		 */
-		if (drm_WARN_ON(&pfdev->base, already_owned)) {
+		if (already_owned) {
+			drm_WARN_ON(&pfdev->base,
+				    folio_nr_pages(folio) <= NUM_FAULT_PAGES);
 			folio_put(folio);
 		} else {
 			got_start = min(got_start, first);

-- 
2.55.0

