From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 03 Nov 2026 16:00:49 -0500
Subject: [PATCH v2 1/2] mm/memory-failure: don't unpoison a leaked
 raw_hwp_unreliable folio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-hugetlb-hwpoison-leak-v2-1-98085750c145@columbia.edu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793739649; l=1959;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=QKydKJ4ULQzr2TWbUaUZ31FxafHdsfMjukKm4+Y/tFQ=;
 b=SJLl5itZOXZdXocudWDHOPpqGm7WPscqvj34RDOCSjv1/dQqDbfcDehqvMdV2OWf4dkqSsplW
 3LJLVsPFS7OBgAZhQlhMVCsD6I7lz3GBvWfObDnz22fxvnZpxoyC9Ux
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If memory_failure() can't save the raw error page of a hugetlb folio,
it marks the folio raw_hwp_unreliable and unpoison_memory() refuses to
unpoison it, since we don't know which subpages are poisoned.  Once the
folio is freed, __update_and_free_hugetlb_folio() leaks it on purpose.
If its hugetlb flag is cleared by then, e.g., without vmemmap
optimization, unpoison_memory() doesn't see a hugetlb folio anymore.
It treats the leaked folio as a normal page and clears PG_hwpoison on
its head, while the poisoned subpages are still unknown.

The leaked folio is still a large folio and raw_hwp_unreliable stays set
in folio->private.  We now check it on any large folio before taking the
page, so unpoison_memory() refuses the folio whether it's still hugetlb
or not.  With the fix, it returns -EBUSY for the leaked folio as it did
before the folio was freed.

Fixes: ac5fcde0a96a ("mm, hwpoison: make unpoison aware of raw error info in hwpoisoned hugepage")
Reported-by: Miaohe Lin <linmiaohe@huawei.com>
Closes: https://lore.kernel.org/all/ae6058ae-3703-a1d5-d82f-4102b46f227b@huawei.com/
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 mm/memory-failure.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/mm/memory-failure.c b/mm/memory-failure.c
index b215312f261b..496eacbefdf2 100644
--- a/mm/memory-failure.c
+++ b/mm/memory-failure.c
@@ -2809,6 +2809,15 @@ int unpoison_memory(unsigned long pfn)
 		goto unlock_mutex;
 	}
 
+	/*
+	 * A hugetlb folio without reliable raw error info is leaked once it
+	 * is freed, and its hugetlb flag may be cleared by then.  Check the
+	 * flag in folio->private, which stays set on the leaked folio.
+	 */
+	if (folio_test_large(folio) &&
+	    folio_test_hugetlb_raw_hwp_unreliable(folio))
+		goto unlock_mutex;
+
 	ghp = get_hwpoison_page(p, MF_UNPOISON);
 	if (!ghp) {
 		if (folio_test_hugetlb(folio)) {

-- 
2.53.0

