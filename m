From: Samridh <samridh@modal.com>
Date: Wed, 18 Nov 2026 20:28:49 +0000
Subject: [PATCH v2] mm/shmem: avoid zeroing new folios twice with
 init_on_alloc=1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-samridh-shmem-send-v2-1-f2ea01bfc178@modal.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/32NzQrCMBCEX6Xs2YiJ2B9Pvof00HY3ZsU0kq1FK
 Xl303qXOX0wM98CQpFJ4FwsEGlm4TBmMLsCBteNN1KMmcEcTKm1rpR0PjI6Jc6TV0Ijqsaiwdo
 cNdUEefiMZPm9nV7bH8urv9MwrU9rw7FMIX4266zX3l/BrFVOXzeVtafSYHPxAbvHfgge2pTSF
 2SIYJnGAAAA
X-Change-ID: 20261117-samridh-shmem-send-9fd2d8231e8e
To: Hugh Dickins <hughd@google.com>, David Hildenbrand <david@kernel.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Samridh <samridh@modal.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795033736; l=2467;
 i=samridh@modal.com; s=20261117; h=from:subject:message-id;
 bh=+TIZt89c6fPFtjTdzvaMfsLmhIUPC+6pbbVMTGgDYV4=;
 b=igkKsRBXifpqSlPGt8MqjeyP+wyHxMr7aac5YwvrqjKI+QWIAvd2E2nkRUZ3pMYuOpGgp0asb
 6X2llXHSRtoAcgb4nlN/NqqYHCfBn/kDjcDnf/E3XZh08nNqJZ3w7cL
X-Developer-Key: i=samridh@modal.com; a=ed25519;
 pk=+V5ZaIpEMOLG1b2MsSHY0Nm20lIADx5ia//FZeuqVgk=
X-Endpoint-Received: by B4 Relay for samridh@modal.com/20261117 with auth_id=1554
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

shmem_get_folio_gfp() clears a new folio before marking it uptodate.
With init_on_alloc=1 the page allocator has already zeroed it, so the
folio ends up being zeroed twice.

Skip the clear for a folio that was just allocated when
user_alloc_needs_zeroing() says it is not needed, like anonymous memory
does. Folios that are already in the page cache but not uptodate, such
as those left by fallocate(), are still cleared, and so is every folio
on CPUs with cache aliasing.

Time to write one byte to each page of a new 4 GiB memfd mapping, with
shmem_enabled=always and init_on_alloc=1 (median of 24 runs on 6.18.55,
x86_64 VMs):

                  before   after
  Xeon 6975P-C    0.625s   0.420s
  EPYC 9R14       0.216s   0.160s

With 4K folios the times change by 3% or less, and init_on_alloc=0 is
not affected. We found this while running gVisor, which keeps sandbox
memory in a memfd.

I wrote this patch with help from an AI coding assistant (Claude Code),
then reviewed and tested it.

Signed-off-by: Samridh <samridh@modal.com>
---
Tested on 6.18.55 with this change backported, on Intel and AMD x86_64
VMs, and build-tested on mm/core for-next. A simple test fills memory
with data, frees it, and then checks that new memfd pages read as zero,
with MADV_HUGEPAGE and MADV_NOHUGEPAGE on the fault and fallocate paths.
It passes on both machines with init_on_alloc=1.
---
Changes in v2:
- Use user_alloc_needs_zeroing() instead of __GFP_ZERO (Baolin).
- Link to v1: https://patch.msgid.link/20261117-samridh-shmem-send-v1-1-1b897ff562d9@modal.com
---
 mm/shmem.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/mm/shmem.c b/mm/shmem.c
index c769d0bc7df9..1a78d15a768e 100644
--- a/mm/shmem.c
+++ b/mm/shmem.c
@@ -2810,8 +2810,11 @@ static int shmem_get_folio_gfp(struct inode *inode, pgoff_t index,
 	if (sgp != SGP_WRITE && !folio_test_uptodate(folio)) {
 		long i, n = folio_nr_pages(folio);
 
-		for (i = 0; i < n; i++)
-			clear_highpage(folio_page(folio, i));
+		/* init_on_alloc already zeroed a new folio. */
+		if (!alloced || user_alloc_needs_zeroing()) {
+			for (i = 0; i < n; i++)
+				clear_highpage(folio_page(folio, i));
+		}
 		flush_dcache_folio(folio);
 		folio_mark_uptodate(folio);
 	}

---
base-commit: f7d95bf74091373fad7273db4557df9b5a902335
change-id: 20261117-samridh-shmem-send-9fd2d8231e8e

Best regards,
--  
Samridh <samridh@modal.com>

