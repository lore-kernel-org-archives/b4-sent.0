From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 22 Jul 2026 16:41:15 -0700
Subject: [PATCH v4 07/16] mm: hugetlb: Fix Use-After-Free in
 unlock_or_release_subpool()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-hugetlb-alloc-failure-fixes-v4-7-88e8b81970dc@google.com>
References: <20260722-hugetlb-alloc-failure-fixes-v4-0-88e8b81970dc@google.com>
In-Reply-To: <20260722-hugetlb-alloc-failure-fixes-v4-0-88e8b81970dc@google.com>
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Nhat Pham <nphamcs@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Peter Xu <peterx@redhat.com>, 
 Wupeng Ma <mawupeng1@huawei.com>, fvdl@google.com, rientjes@google.com, 
 jthoughton@google.com, Mike Kravetz <mike.kravetz@oracle.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Alex Shi <alexs@kernel.org>, 
 Yanteng Si <si.yanteng@linux.dev>, Dongliang Mu <dzm91@hust.edu.cn>, 
 Hongxiang Lou <louhongxiang@huawei.com>, Miaohe Lin <linmiaohe@huawei.com>
Cc: vannapurve@google.com, erdemaktas@google.com, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 linux-doc@vger.kernel.org, Ackerley Tng <ackerleytng@google.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784763678; l=1786;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=+8BKlqcw0osweyRZX4DVMuCuKwenNXcfBjXVW5HQiFI=;
 b=1QJ1v6HnKCN4SUgfZ0zCwSM1fabe4JN3I0E4aRntYBp8Vk2QcabaSyeAnsKBGGeTC3Y76lQen
 YmRVqUCR2SyD0f88goOEuJb9brctkXRJonc3/dbLVzTo9GlGyTpg6do
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In unlock_or_release_subpool(), spool->lock was released before calling
subpool_is_free(spool). Because subpool_is_free() accesses spool->count and
spool->used_hpages locklessly, concurrent threads calling
hugepage_subpool_put_pages() or hugepage_put_subpool() could race when
spool->count is 0.

If Thread 1 drops spool->lock and is preempted before subpool_is_free(),
Thread 2 can acquire spool->lock, decrement spool->used_hpages to 0,
evaluate subpool_is_free() as true, and free spool via kfree(). When Thread
1 resumes, subpool_is_free() dereferences the freed spool pointer, causing
a Use-After-Free (UAF) or double free.

Fix this race by evaluating subpool_is_free() while holding spool->lock
prior to unlocking.

Fixes: 1d88433bb0085 ("mm/hugetlb: fix use after free when subpool max_hpages accounting is not enabled")
Cc: stable@vger.kernel.org
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 mm/hugetlb.c | 7 +++----
 1 file changed, 3 insertions(+), 4 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 8431c00d48267..b759748468734 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -137,12 +137,11 @@ static inline bool subpool_is_free(struct hugepage_subpool *spool)
 static inline void unlock_or_release_subpool(struct hugepage_subpool *spool,
 						unsigned long irq_flags)
 {
+	bool is_free = subpool_is_free(spool);
+
 	spin_unlock_irqrestore(&spool->lock, irq_flags);
 
-	/* If no pages are used, and no other handles to the subpool
-	 * remain, give up any reservations based on minimum size and
-	 * free the subpool */
-	if (subpool_is_free(spool)) {
+	if (is_free) {
 		if (spool->min_hpages != -1)
 			hugetlb_acct_memory(spool->hstate,
 						-spool->min_hpages);

-- 
2.55.0.229.g6434b31f56-goog

