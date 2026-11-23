From: Samridh <samridh@modal.com>
Date: Mon, 23 Nov 2026 19:54:44 +0000
Subject: [PATCH v3] mm/shmem: avoid zeroing new folios twice with
 init_on_alloc=1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-samridh-shmem-send-v3-1-afc6a40bc187@modal.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/32NQQ7CIBBFr9KwFlOmsaWuvIdxQWEQjBQDlWia3
 l2omy6MmdVL/rw3k4jBYiTHaiYBk43WjxmaXUWkEeMVqVWZCdTQMsY6GoULVhkajUNHI46K9lq
 B4tAw5Ejy4yOgtq9Ver58OT6HG8qpmMrC2Dj58F6riZXd30BiNN/A+07rQwuqPzmvxH0vvSMlk
 GCr4D8VkBUaUNRs0JJ1fKtYluUDWdpTfAkBAAA=
X-Change-ID: 20261117-samridh-shmem-send-9fd2d8231e8e
To: Hugh Dickins <hughd@google.com>, David Hildenbrand <david@kernel.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Samridh <samridh@modal.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795463691; l=2736;
 i=samridh@modal.com; s=20261117; h=from:subject:message-id;
 bh=cB/X49bEfE/YxcJEqpPRK906snRfTv9QZQXwDDpM5iE=;
 b=X7wVMmGKz2duhlMnJ04dtKau0IR8o6b1Ll9s74xW0fdxBH9twRT/0YfQ2a17/8K0DQ5WSQwi+
 YgdAKfD3sxwDryqlYQJ+siJqBn8QdQwCWuav/MgO5qy373b6KQmohSj
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

Reviewed-by: Baolin Wang <baolin.wang@linux.alibaba.com>
Signed-off-by: Samridh <samridh@modal.com>
---
Tested on 6.18.55 with this change backported, on Intel and AMD x86_64
VMs, and build-tested on mm/core for-next. A simple test fills memory
with data, frees it, and then checks that new memfd pages read as zero,
with MADV_HUGEPAGE and MADV_NOHUGEPAGE on the fault and fallocate paths.
It passes on both machines with init_on_alloc=1.
---
Changes in v3:
- Move flush_dcache_folio() into the clear branch (David).
- Link to v2: https://patch.msgid.link/20261118-samridh-shmem-send-v2-1-f2ea01bfc178@modal.com

Changes in v2:
- Use user_alloc_needs_zeroing() instead of __GFP_ZERO (Baolin).
- Link to v1: https://patch.msgid.link/20261117-samridh-shmem-send-v1-1-1b897ff562d9@modal.com
---
 mm/shmem.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/mm/shmem.c b/mm/shmem.c
index c769d0bc7df9..0ab3b9146141 100644
--- a/mm/shmem.c
+++ b/mm/shmem.c
@@ -2810,9 +2810,12 @@ static int shmem_get_folio_gfp(struct inode *inode, pgoff_t index,
 	if (sgp != SGP_WRITE && !folio_test_uptodate(folio)) {
 		long i, n = folio_nr_pages(folio);
 
-		for (i = 0; i < n; i++)
-			clear_highpage(folio_page(folio, i));
-		flush_dcache_folio(folio);
+		/* init_on_alloc already zeroed a new folio. */
+		if (!alloced || user_alloc_needs_zeroing()) {
+			for (i = 0; i < n; i++)
+				clear_highpage(folio_page(folio, i));
+			flush_dcache_folio(folio);
+		}
 		folio_mark_uptodate(folio);
 	}
 

---
base-commit: f7d95bf74091373fad7273db4557df9b5a902335
change-id: 20261117-samridh-shmem-send-9fd2d8231e8e

Best regards,
--  
Samridh <samridh@modal.com>

