From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 27 Oct 2026 16:33:32 -0400
Subject: [PATCH] mm/shmem: fix swapin livelock on a mismatched large swap
 cache folio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-shmem-swapin-mismatch-v1-1-84e30aa3b9e5@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBCF4avIrDvQBFToVYqLMY7NFJJKxqoQv
 LtRF2/xLd6fQTkJK7yqDIkXUfnFAvOowHmKH0YZisE+bWPKUH3ggLrSJBGDaKDZeRyHloi4NbX
 toXynxKNsV/fd3dZ//2U3nzHY9wOS/mNzeQAAAA==
X-Change-ID: 20261026-shmem-swapin-mismatch-fd7aaae7152b
To: Hugh Dickins <hughd@google.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Kairui Song <kasong@tencent.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, tz2294@columbia.edu, 
 Chris Li <chrisl@kernel.org>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <baoquan.he@linux.dev>, 
 Barry Song <baohua@kernel.org>, Youngjun Park <youngjun.park@lge.com>, 
 David Hildenbrand <david@kernel.org>, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793133211; l=4725;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=Vdl4OKyE80c+N/UAG+bYXzpu0HL0y5evYFJyEcYjtvw=;
 b=7uEcFzFrWSSemDyMXBbHWaNW+OuNxmh1qJi8M4WhwJ60XkoJkAc5+eqGMXNjzw5vbCxDuDjY9
 HBoa2eD2w2CDUcUk64WjB98n/hFWwztLwUaIG5XzUTnR44iklMkG7ET
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a SWP_SYNCHRONOUS_IO swap device, a large shmem folio can be left in
the swap cache over swap slots that another file now uses.  Reading
that other file then loops forever in shmem_get_folio_gfp():
shmem_swapin_folio() finds the large folio, rounds the index and the
swap entry down to the folio's size, finds no matching entry in the
file and returns -EEXIST, and the retry finds the same folio again.
Since the task keeps the mapping locked, a munmap() of the same mapping
waits forever.

The folio is left behind when the slots are freed and reused while the
swapin is still allocating it:

  Task A (reads X)                      Task B
  ----------------                      ------
  shmem_swapin_folio()
    allocate a large folio
    for X's slots
                                        punch a hole in X
                                        /* X's slots freed */
                                        swap out file Y
                                        /* Y reuses those slots */
    add the folio to the swap
    cache over those slots
    shmem_confirm_swap() fails
    /* -EEXIST, the folio stays
       in the swap cache */

  Task C (reads Y)
  ----------------
  shmem_swapin_folio()
    finds the large folio
    rounds down to its start,
    where Y has no entry
    /* -EEXIST, retried forever */

Before commit c246d236b18b ("mm/shmem: never bypass the swap cache for
SWP_SYNCHRONOUS_IO"), a direct swapin that failed this way freed its
folio instead of leaving it in the swap cache.

do_swap_page() already drops a large swap cache folio that does not
fit for anonymous memory.  Do the same in shmem_swapin_folio() and on
a -EEXIST, remove a large folio that is not
anonymous/dirty/under-writeback from the swap cache so that the retry
swaps in a folio that fits.

The reproducer below fills a small brd swap device so that a 64K shmem
folio and the 4K pages of another file land in the same slots, and races
a read of the first file with a hole punch and a swapout of the second.
This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development, but the non-deterministic C
reproducer can typically trigger it in the 2-4s time range.  With the
fix, nothing is triggered after 600 seconds.

Fixes: c246d236b18b ("mm/shmem: never bypass the swap cache for SWP_SYNCHRONOUS_IO")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Two patches in David Hildenbrand's v2 shmem fixes series are related
to this one.  "mm/shmem: fix truncate hang in large swap entry" [1]
makes truncation retry -EEXIST directly, so it can also loop on such a
folio.  "mm/shmem: preserve allocation errors when swapping in large
entries" [2] fixes a different -EEXIST loop, where a failed allocation
is reported as -EEXIST.

[1] https://lore.kernel.org/all/20261027-fixes_shmem-v2-10-86a00952acb9@kernel.org/
[2] https://lore.kernel.org/all/20261027-fixes_shmem-v2-11-86a00952acb9@kernel.org/

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/shmemloop.c
---
 mm/shmem.c | 16 ++++++++++++++--
 1 file changed, 14 insertions(+), 2 deletions(-)

diff --git a/mm/shmem.c b/mm/shmem.c
index 13e0786436cd..f1da8432d55c 100644
--- a/mm/shmem.c
+++ b/mm/shmem.c
@@ -2568,11 +2568,14 @@ static int shmem_swapin_folio(struct inode *inode, pgoff_t index,
 	 * and swap cache folios are never partially freed.
 	 */
 	folio_lock(folio);
-	if (!folio_matches_swap_entry(folio, swap) ||
-	    shmem_confirm_swap(mapping, index, swap) < 0) {
+	if (!folio_matches_swap_entry(folio, swap)) {
 		error = -EEXIST;
 		goto unlock;
 	}
+	if (shmem_confirm_swap(mapping, index, swap) < 0) {
+		error = -EEXIST;
+		goto failed;
+	}
 	if (!folio_test_uptodate(folio)) {
 		error = -EIO;
 		goto failed;
@@ -2613,6 +2616,15 @@ static int shmem_swapin_folio(struct inode *inode, pgoff_t index,
 		error = -EEXIST;
 	if (error == -EIO)
 		shmem_set_folio_swapin_error(inode, index, folio, swap);
+	/*
+	 * A large folio that does not fit the mapping, e.g. because its swap
+	 * entries were freed and reused, would be found again on every retry.
+	 * Drop it from the swap cache so the retry can swap in a fitting one.
+	 */
+	if (error == -EEXIST && folio && folio_test_large(folio) &&
+	    !folio_test_anon(folio) && !folio_test_dirty(folio) &&
+	    !folio_test_writeback(folio))
+		swap_cache_del_folio(folio);
 unlock:
 	if (folio)
 		folio_unlock(folio);

---
base-commit: bae9a042b03b27924c6fd5bdc00a20d6a44d6041
change-id: 20261026-shmem-swapin-mismatch-fd7aaae7152b

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

