From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 03 Nov 2026 16:00:50 -0500
Subject: [PATCH v2 2/2] mm/hugetlb: clear the hugetlb flag before leaking a
 hwpoisoned folio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-hugetlb-hwpoison-leak-v2-2-98085750c145@columbia.edu>
References: <20261103-hugetlb-hwpoison-leak-v2-0-98085750c145@columbia.edu>
In-Reply-To: <20261103-hugetlb-hwpoison-leak-v2-0-98085750c145@columbia.edu>
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, Miaohe Lin <linmiaohe@huawei.com>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: Naoya Horiguchi <nao.horiguchi@gmail.com>, 
 Matthew Wilcox <willy@infradead.org>, Jane Chu <jane.chu@oracle.com>, 
 Zi Yan <ziy@nvidia.com>, Kaitao Cheng <kaitao.cheng@linux.dev>, 
 Mike Rapoport <rppt@kernel.org>, Mike Kravetz <mike.kravetz@oracle.com>, 
 Yu Zhao <yuzhao@google.com>, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793739649; l=3741;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=p3cGeIhEss5lhmQM33p4Lp9XHqkwwMIQoTW5yzc7mbM=;
 b=PGA1VtdllP0dw4XcQ0InOdQX6BI+3QMcqOt1iWyGu2HdO7JdQSgJa7wvu5TUQOhX7H0SM+agA
 32NCczq4qtNBwO7Lc2Rr5EVpRvJxUGwC1a8+OzEyFhLN8OhDW/zKXeg
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If hugetlb_update_hwpoison() fails to allocate a raw_hwp_page, the folio
is marked raw_hwp_unreliable and __update_and_free_hugetlb_folio() leaks
it intentionally.  With hugetlb_free_vmemmap=on, it's leaked before the
hugetlb flag is cleared, since commit 32c877191e02 ("hugetlb: do not
clear hugetlb dtor until allocating vmemmap") doesn't remove the flag
until the vmemmap is restored.  The leaked folio is then a hugetlb folio
with refcount 0 and on no list (the same state as a hugetlb folio that
is being freed), but nothing is freeing it, and
dissolve_free_hugetlb_folio() keeps retrying on it.  Offlining its
memory block then never completes, even on SIGKILL, and other tasks
block on the memory hotplug lock:

  [    3.271255] Memory failure: 0x20007: recovery action for free huge page: Failed
  [   41.729695] INFO: task hugeoffline:77 blocked for more than 20 seconds.
  ...
  [   41.733014]  get_online_mems+0xc1/0xd0
  [   41.733026]  soft_offline_page+0xfd/0x9b0

alloc_and_dissolve_hugetlb_folio() loops on it the same way.  The
refcount is 0 since commit bd225530a4c7 ("mm/hugetlb_vmemmap: fix race
with speculative PFN walkers").  Before that these paths failed with
-EBUSY.

Check raw_hwp_unreliable after the hugetlb flag is cleared so that the
folio is leaked as a non-hugetlb folio, as without vmemmap
optimization.  unpoison_memory() keeps refusing to unpoison it.  With
the fix, offlining retries as it does for any page it can't isolate,
and stops on a signal.

Fixes: 32c877191e02 ("hugetlb: do not clear hugetlb dtor until allocating vmemmap")
Fixes: bd225530a4c7 ("mm/hugetlb_vmemmap: fix race with speculative PFN walkers")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
This relies on Kaitao's "mm/hugetlb: preserve persistent flags when
returning folios to the pool" [1] (673b553e2bba in mm-new).  The check
now comes after hugetlb_vmemmap_restore_folio(), so on a restore failure
add_hugetlb_folio() must keep raw_hwp_unreliable.  It would be good to
take [1] to stable along with this one.

This changes the same lines as patch 07/15 of Matthew's "Use
generic_file_read_iter() in hugetlbfs" series [2].  On top of that
series, the check goes right after the folio_clear_hugetlb() call.

[1] https://lore.kernel.org/all/20261102024910.31486-3-kaitao.cheng@linux.dev/
[2] https://lore.kernel.org/all/20260805210557.1118966-8-willy@infradead.org/

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/hugeoffline.c
---
 mm/hugetlb.c | 15 ++++++++-------
 1 file changed, 8 insertions(+), 7 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 779b1de33c78..cdeb8923083f 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -1480,13 +1480,6 @@ static void __update_and_free_hugetlb_folio(struct hstate *h,
 		return;
 	}
 
-	/*
-	 * If we don't know which subpages are hwpoisoned, we can't free
-	 * the hugepage, so it's leaked intentionally.
-	 */
-	if (folio_test_hugetlb_raw_hwp_unreliable(folio))
-		return;
-
 	/*
 	 * If folio is not vmemmap optimized (!clear_flag), then the folio
 	 * is no longer identified as a hugetlb page.  hugetlb_vmemmap_restore_folio
@@ -1514,6 +1507,14 @@ static void __update_and_free_hugetlb_folio(struct hstate *h,
 		spin_unlock_irq(&hugetlb_lock);
 	}
 
+	/*
+	 * If we don't know which subpages are hwpoisoned, we can't free
+	 * the hugepage, so it's leaked intentionally, but only once it is
+	 * no longer a hugetlb folio.
+	 */
+	if (folio_test_hugetlb_raw_hwp_unreliable(folio))
+		return;
+
 	/*
 	 * Move PageHWPoison flag from head page to the raw error pages,
 	 * which makes any healthy subpages reusable.

-- 
2.53.0

