From: Mani Tofigh <mt4022@columbia.edu>
Date: Mon, 26 Oct 2026 11:19:22 -0400
Subject: [PATCH] mm, swap: stop cluster list scans once swapoff clears
 SWP_WRITEOK
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-swapoff-writeok-v1-1-4f4cd420aa33@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDINYtLk8syE9L0y0vyixJzc/WTbEwSjNKTEk2SjQ1VgLqKihKTcusAJs
 YHQvhF5cmZaUml4CMUaqtBQDWLk8TcwAAAA==
X-Change-ID: 20261026-swapoff-writeok-d82f2adc2a53
To: Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <baoquan.he@linux.dev>, 
 Barry Song <baohua@kernel.org>, Youngjun Park <youngjun.park@lge.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, tz2294@columbia.edu, 
 stable@vger.kernel.org, Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793027962; l=4058;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=13fz6rqNh91gTcPzM8hXNMOTAxUdtQgWk+c7vws4zJ8=;
 b=vg9IYQzJgsesZ3/7DOx8iiu+UpwzJK/cT7keQ9ZTtaH4xqfxdkhcRRPeZI97Poq9QOz1X1L6b
 rOOceG7nTAZB9hJbL18eVW0RArdVG4aOyGUa783AMsl5Gc87b5so/gq
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SWP_WRITEOK is cleared under si->lock when swapoff starts so that no
new swap entries are allocated from the device, and try_to_unuse()
then waits for writeback of the folios that still use the device.

However, an order-0 allocation that chose the device can race with
swapoff clearing the flag and then loop forever.  It takes a cluster
from the fragment cluster list of a higher order with
isolate_lock_cluster(), the allocation from that cluster fails because
SWP_WRITEOK is clear, and relocate_cluster() puts the cluster back on
the same list, so the loop keeps finding clusters on it.

The looping task is in reclaim, and it may have set writeback on a
folio whose write has been queued but not yet submitted.  swapoff then
waits for that folio, while the reclaiming task, stuck in the loop,
never reaches the point where it submits the write:

  CPU0 (reclaim)                          CPU1 (swapoff)
  --------------                          --------------
  shrink_folio_list()
    pageout(F)
      /* F under writeback,
         write not submitted */
    folio_alloc_swap(G)  /* order 0 */
      swap_alloc_slow()
                                          del_from_avail_list(si, true)
                                            si->flags &= ~SWP_WRITEOK
                                          try_to_unuse()
                                            folio_wait_writeback(F)
        cluster_alloc_swap_entry()
          isolate_lock_cluster()
          /* allocation fails:
             !SWP_WRITEOK */
          relocate_cluster()
          /* repeats forever */
    swap_write_submit()
    /* never reached */

This results in a soft lockup on CPU0 and a swapoff that never returns.

isolate_lock_cluster() used to check SWP_WRITEOK under si->lock until
commit 07adc4cf1ecd ("mm, swap: implement dynamic allocation of swap
table") removed that check.  Restore the check.  Since swapoff clears
the flag under the same lock, isolate_lock_cluster() then returns NULL,
which ends the scan; the swap slot allocation for G fails, and reclaim
goes on to submit the write of F.

Given that this is a race, its reproducibility is non-deterministic.
We reproduce it by using a non-rotational swap device that is not
synchronous, with 64K mTHP enabled, where one CPU repeatedly pages out
two 64K folios and a 4K page with madvise(MADV_PAGEOUT), while other
CPUs run swapoff and swapon on the same device.  In my tests it
triggers within 20s in each run, and with the fix applied, it runs for
300s without any hang/kernel report.  This bug was found and
reproduced deterministically using a deterministic hypervisor that is
currently under development.

Fixes: 07adc4cf1ecd ("mm, swap: implement dynamic allocation of swap table")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Before commit dda8fb68b590 ("mm/swap: also use struct swap_iocb for
block I/O"), reclaim submitted the swap write right away, so on 6.18
to 7.2 the loop most likely ends once swapoff frees the slots instead
of hanging.

Reproducer: https://github.com/manitofigh/swapoff-repro/blob/main/swapoff.c
---
 mm/swapfile.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/mm/swapfile.c b/mm/swapfile.c
index 601979b97f95..2b03d14b5f52 100644
--- a/mm/swapfile.c
+++ b/mm/swapfile.c
@@ -627,6 +627,10 @@ static struct swap_cluster_info *isolate_lock_cluster(
 	u8 flags = CLUSTER_FLAG_NONE;
 
 	spin_lock(&si->lock);
+
+	if (unlikely(!(si->flags & SWP_WRITEOK)))
+		goto out;
+
 	list_for_each_entry(ci, list, list) {
 		if (!spin_trylock(&ci->lock))
 			continue;
@@ -642,6 +646,7 @@ static struct swap_cluster_info *isolate_lock_cluster(
 		found = ci;
 		break;
 	}
+out:
 	spin_unlock(&si->lock);
 
 	/* Cluster's table is freed when and only when it's on the free list. */

---
base-commit: e9011a65d78258901ba123c5f522bef26d29902f
change-id: 20261026-swapoff-writeok-d82f2adc2a53

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

