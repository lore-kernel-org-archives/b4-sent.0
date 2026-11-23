From: Mani Tofigh <mt4022@columbia.edu>
Date: Mon, 23 Nov 2026 12:21:34 -0500
Subject: [PATCH] mm/shmem: don't drop a folio whose swap write failed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-shmem-swap-write-failed-v1-1-41a0115dfbf1@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTuJHQMhXsW4KO2PjBEkHRASw
 t2puvwW721kSAqja7FRwkdN30OGOxUUOj88wBqzSc5SOScXtq5Hz7b4kZekE7j1+kLkJiBKXaI
 upaJcjwmtrr/z7f63zc0TYfruaN8PouPc8XsAAAA=
X-Change-ID: 20261123-shmem-swap-write-failed-bced285e8526
To: Andrew Morton <akpm@linux-foundation.org>, 
 Hugh Dickins <hughd@google.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 David Hildenbrand <david@kernel.org>, Kairui Song <kasong@tencent.com>
Cc: Chris Mason <mason@kernel.org>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <baoquan.he@linux.dev>, Barry Song <baohua@kernel.org>, 
 Youngjun Park <youngjun.park@lge.com>, Tal Zussman <tz2294@columbia.edu>, 
 linux-mm@kvack.org, linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795454494; l=2695;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=YZkS8z4nKi2wuUKuI1w38QEIWGBn1hka4U2KKfBBdd8=;
 b=d1A2Jbz2YdcvzAkeX34oY+L/eDQiZJwjs+Ba8yDMxbqQPOWBbjimDgjlrMGcsx8rIoPhofk6v
 r+eHSy/2jevAy45EgB0WGi0sTG14AtoEENRVU7lykD94wVL2tH1oNET
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

shmem_swapin_folio() drops a large folio that does not fit the mapping
from the swap cache if the folio is neither dirty nor under writeback.
The folio can belong to another file and be under swap writeback, when
the swap entry was freed and reused before the swap cache lookup.

Swap write completion does not take the folio lock.  On a failed write,
swap_write_end() marks the folio dirty and then ends writeback.  Since
dirty is tested first, the folio can look clean and written:

  CPU0 (swapin of file Y)             CPU1 (swapout of file X)
  -----------------------             ------------------------
  shmem_swapin_folio()
    folio_test_dirty() == false
                                      swap_write_end(), failed write
                                        folio_mark_dirty()
                                        folio_end_writeback()
    folio_test_writeback() == false
    swap_cache_del_folio()
    /* X's data is lost */

The next swapin of X reads the slot whose write failed.

Test writeback first.  Both flags are in folio->flags.  If the
writeback test sees the write ended, the dirty test then sees the dirty
bit set before it.

With the fix, a folio whose swap write failed stays in the swap cache.

Fixes: fc2c19648d68 ("mm/shmem: fix swapin livelock on a mismatched large swap cache folio")
Suggested-by: Chris Mason <mason@kernel.org>
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Managed to hit this by forcing the order in a VM, and it's gone with the fix.
---
 mm/shmem.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/mm/shmem.c b/mm/shmem.c
index e351cd425d69..867f43315af1 100644
--- a/mm/shmem.c
+++ b/mm/shmem.c
@@ -2664,10 +2664,12 @@ static int shmem_swapin_folio(struct inode *inode, pgoff_t index,
 	 * A large folio that does not fit the mapping, e.g. because its swap
 	 * entries were freed and reused, would be found again on every retry.
 	 * Drop it from the swap cache so the retry can swap in a fitting one.
+	 * A failed swap write sets dirty and then ends writeback without the
+	 * folio lock, so test writeback before dirty.
 	 */
 	if (error == -EEXIST && folio && folio_test_large(folio) &&
-	    !folio_test_anon(folio) && !folio_test_dirty(folio) &&
-	    !folio_test_writeback(folio))
+	    !folio_test_anon(folio) && !folio_test_writeback(folio) &&
+	    !folio_test_dirty(folio))
 		swap_cache_del_folio(folio);
 unlock:
 	if (folio)

---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-shmem-swap-write-failed-bced285e8526

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

