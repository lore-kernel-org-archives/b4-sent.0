From: Samridh <samridh@modal.com>
Date: Tue, 17 Nov 2026 19:32:26 +0000
Subject: [PATCH] mm/shmem: avoid zeroing new folios twice with
 init_on_alloc=1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-samridh-shmem-send-v1-1-1b897ff562d9@modal.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yXMQQrCQAxG4auUrA2YEWz1KuKiNn87EWaUiYpQe
 nfHdvkt3pvJUQxO52amgo+5PXKF7BoaYp8nsGk1hX04ikjL3qdiGtljQmJHVj6NGrQLB0EHquG
 zYLTvOr1cN/v7dsfw+p9oWX7APPb8dgAAAA==
X-Change-ID: 20261117-samridh-shmem-send-9fd2d8231e8e
To: Hugh Dickins <hughd@google.com>, David Hildenbrand <david@kernel.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Samridh <samridh@modal.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794943947; l=3830;
 i=samridh@modal.com; s=20261117; h=from:subject:message-id;
 bh=a7F7GTEWjxL9C0nNEosbwVj6fkOjYCgTqLb1jXjkir0=;
 b=SGNqaUKOMECCXRZi1l9o3gcwAg9U87xEHWyCYMLVkCloKUFF9Ay+mQBIt7txWMP42l2ju4br2
 9H91UYwZTVYDSc8S3KqW5lzYfQHrgUjv3lPtjx9KAtzYUioODSdQRll
X-Developer-Key: i=samridh@modal.com; a=ed25519;
 pk=+V5ZaIpEMOLG1b2MsSHY0Nm20lIADx5ia//FZeuqVgk=
X-Endpoint-Received: by B4 Relay for samridh@modal.com/20261117 with auth_id=1554
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

shmem_get_folio_gfp() clears a new folio before marking it uptodate.
With init_on_alloc=1 the page allocator has already zeroed it, so the
folio ends up being zeroed twice.

For SGP_CACHE, the only mode that clears a new folio, ask the page
allocator for a zeroed folio with __GFP_ZERO. Folios that are already in
the page cache but not uptodate, such as those left by fallocate(), are
still cleared. With init_on_alloc=0 the zeroing moves into the
allocator, so a folio is zeroed for nothing when the memcg charge, the
page cache insert or the block accounting fails.

Time to write one byte to each page of a new 4 GiB memfd mapping, with
shmem_enabled=always and init_on_alloc=1 (median of 24 runs on 6.18.55,
x86_64 VMs):

                  before   after
  Xeon 6975P-C    0.620s   0.416s
  EPYC 9R14       0.216s   0.158s

With 4K folios, or with init_on_alloc=0, the times change by 3% or
less. We found this while running gVisor, which keeps sandbox memory in
a memfd.

I wrote this patch with help from an AI coding assistant (Claude Code),
then reviewed and tested it.

Signed-off-by: Samridh <samridh@modal.com>
---
Tested on 6.18.55 with this change backported, on Intel and AMD x86_64
VMs, and build-tested on mm/core for-next. I also wrote a simple test.
It fills memory with data, frees it, and then checks that new memfd
pages read as zero. It covers MADV_HUGEPAGE and MADV_NOHUGEPAGE on the
fault and fallocate paths. It passes on both machines with
init_on_alloc/init_on_free at 1/0, 0/0 and 1/1.

The idea came from David's comment on the __GFP_PREZEROED RFC [1].
One thing I'm not sure about is whether flush_dcache_folio() after the
allocator has zeroed the folio is enough on architectures with cache
aliasing, so a second look there would be welcome.

[1] https://lore.kernel.org/all/b258160c-5287-43dd-b56e-268c403b85ea@kernel.org/
---
 mm/shmem.c | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/mm/shmem.c b/mm/shmem.c
index 5cb628cc9c6b..d2c6781e86a5 100644
--- a/mm/shmem.c
+++ b/mm/shmem.c
@@ -2692,6 +2692,7 @@ static int shmem_get_folio_gfp(struct inode *inode, pgoff_t index,
 	int error;
 	bool alloced;
 	unsigned long orders = 0;
+	gfp_t zero_gfp = sgp == SGP_CACHE ? __GFP_ZERO : 0;
 
 	if (WARN_ON_ONCE(!shmem_mapping(inode->i_mapping)))
 		return -EINVAL;
@@ -2770,7 +2771,7 @@ static int shmem_get_folio_gfp(struct inode *inode, pgoff_t index,
 
 		huge_gfp = vma_thp_gfp_mask(vma);
 		huge_gfp = thp_shmem_limit_gfp_mask(huge_gfp, gfp);
-		folio = shmem_alloc_and_add_folio(vmf, huge_gfp,
+		folio = shmem_alloc_and_add_folio(vmf, huge_gfp | zero_gfp,
 				inode, index, fault_mm, orders);
 		if (!IS_ERR(folio)) {
 			if (folio_test_pmd_mappable(folio))
@@ -2782,7 +2783,8 @@ static int shmem_get_folio_gfp(struct inode *inode, pgoff_t index,
 			goto repeat;
 	}
 
-	folio = shmem_alloc_and_add_folio(vmf, gfp, inode, index, fault_mm, 0);
+	folio = shmem_alloc_and_add_folio(vmf, gfp | zero_gfp, inode, index,
+					  fault_mm, 0);
 	if (IS_ERR(folio)) {
 		error = PTR_ERR(folio);
 		if (error == -EEXIST)
@@ -2810,8 +2812,11 @@ static int shmem_get_folio_gfp(struct inode *inode, pgoff_t index,
 	if (sgp != SGP_WRITE && !folio_test_uptodate(folio)) {
 		long i, n = folio_nr_pages(folio);
 
-		for (i = 0; i < n; i++)
-			clear_highpage(folio_page(folio, i));
+		/* A folio allocated with __GFP_ZERO is already zeroed. */
+		if (!alloced || !zero_gfp) {
+			for (i = 0; i < n; i++)
+				clear_highpage(folio_page(folio, i));
+		}
 		flush_dcache_folio(folio);
 		folio_mark_uptodate(folio);
 	}

---
base-commit: 0c524518413094607a6178c53a65815762bc9c45
change-id: 20261117-samridh-shmem-send-9fd2d8231e8e

Best regards,
--  
Samridh <samridh@modal.com>

