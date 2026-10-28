From: Mani Tofigh <mt4022@columbia.edu>
Date: Wed, 28 Oct 2026 11:43:19 -0400
Subject: [PATCH] mm/hugetlb: clear the hugetlb flag before leaking a
 hwpoisoned folio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-hugetlb-hwpoison-leak-v1-1-77ce56002523@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDMBBA4avIrDtgfhDpVUoXRkczKolktC2Id
 2/U5bd4bwehxCTwLHZI9GHhGDLUo4DWN2Eg5C4bdKkrVeoa/TbQOjv03yWyxIAzNRO6ujPWmkp
 ZZSC3S6Kef9f39b4tmxupXc8ZHMcfructq3kAAAA=
X-Change-ID: 20261028-hugetlb-hwpoison-leak-b8d344361413
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, Miaohe Lin <linmiaohe@huawei.com>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: Naoya Horiguchi <nao.horiguchi@gmail.com>, 
 Matthew Wilcox <willy@infradead.org>, Jane Chu <jane.chu@oracle.com>, 
 linux-mm@kvack.org, linux-kernel@vger.kernel.org, tz2294@columbia.edu, 
 stable@vger.kernel.org, Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793202199; l=3284;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=cR+00jv6nY1jeTNTofLkwvXHeYkHwgr3Q37wQeBJJMc=;
 b=7irmncB/MpzPKA+QIZm3X8VvaXcSQlPwA5I1tfMDuVathOhu4bTIGXc1RMBaZ0+e8m0O4VpxI
 n/xTBuSAbwMD8aRZrhG/rRQ2efGKNk1aNOuGkEjCtXgDCpu0FheUsHv
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
memory block then never completes:

  [    3.271255] Memory failure: 0x20007: recovery action for free huge page: Failed
  [   41.729695] INFO: task hugeoffline:77 blocked for more than 20 seconds.
  ...
  [   41.733014]  get_online_mems+0xc1/0xd0
  [   41.733026]  soft_offline_page+0xfd/0x9b0

alloc_and_dissolve_hugetlb_folio() loops on it the same way.

Check raw_hwp_unreliable after the hugetlb flag is cleared so that the
folio is leaked as a non-hugetlb folio, as without vmemmap
optimization.  With the fix, no task hangs.

This bug was identified and confirmed with the help of fault-injection
testing on a deterministic hypervisor currently under development.  The
C reproducer below however chains the specific events that trigger it.

Fixes: 32c877191e02 ("hugetlb: do not clear hugetlb dtor until allocating vmemmap")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
This changes the same lines as patch 07/15 of Matthew's "Use
generic_file_read_iter() in hugetlbfs" series [1].  On top of that
series, the check goes right after the folio_clear_hugetlb() call.

[1] https://lore.kernel.org/all/20260805210557.1118966-8-willy@infradead.org/

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/hugeoffline.c
---
 mm/hugetlb.c | 15 ++++++++-------
 1 file changed, 8 insertions(+), 7 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 4a008afaedf9..4d6b7ab49502 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -1472,13 +1472,6 @@ static void __update_and_free_hugetlb_folio(struct hstate *h,
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
@@ -1506,6 +1499,14 @@ static void __update_and_free_hugetlb_folio(struct hstate *h,
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

---
base-commit: bae9a042b03b27924c6fd5bdc00a20d6a44d6041
change-id: 20261028-hugetlb-hwpoison-leak-b8d344361413

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

