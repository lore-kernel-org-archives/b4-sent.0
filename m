From: Kairui Song <kasong@tencent.com>
Date: Fri, 21 Aug 2026 02:55:20 +0800
Subject: [PATCH v3 07/18] mm/huge_memory: move EOF trimming into the file
 split helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-swap-thp-cleanup-v3-7-9b43f5163238@tencent.com>
References: <20260821-swap-thp-cleanup-v3-0-9b43f5163238@tencent.com>
In-Reply-To: <20260821-swap-thp-cleanup-v3-0-9b43f5163238@tencent.com>
To: linux-mm@kvack.org
Cc: linux-kernel@vger.kernel.org, Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Zi Yan <ziy@nvidia.com>, Baolin Wang <baolin.wang@linux.alibaba.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Nico Pache <nico.pache@linux.dev>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Lance Yang <lance.yang@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Chris Li <chrisl@kernel.org>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <baoquan.he@linux.dev>, 
 Barry Song <baohua@kernel.org>, Youngjun Park <youngjun.park@lge.com>, 
 Shivam Kalra <shivamkalra98@zohomail.in>, Kairui Song <kasong@tencent.com>, 
 Kairui Song <ryncsn@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787252124; l=4165;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=iHc7pAaIWrvecdrYUZp632jxrrl7JCpaJ3/M1UaVKXM=;
 b=SSoVa7oBxRV5XNOTEkWS5QvNz8DmMOLpNiHcpSpatLmWJ2BgTT8vxBo1owQndnsF1GBNZS3PT
 H4ECfhrdcmICJ5mWGv51TZGUXGuzoZX1tVVARrbzwXTEMIpX34esKVJ
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of receiving @end and @nr_shmem_dropped from the caller, the
file split helper now computes the EOF boundary and trims pages beyond
it itself, as this is only needed for file split.  This drops the
redundant parameter passing and sanity check.

Reviewed-by: Zi Yan <ziy@nvidia.com>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 42 +++++++++++++++++++-----------------------
 1 file changed, 19 insertions(+), 23 deletions(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 69d3a6889f9e..01c8cf428595 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -4029,14 +4029,26 @@ static int __folio_freeze_split_unmapped_anon(struct folio *folio, unsigned int
 static int __folio_freeze_split_unmapped_file(struct folio *folio, unsigned int new_order,
 					      struct page *split_at, struct xa_state *xas,
 					      struct address_space *mapping, bool do_lru,
-					      struct list_head *list, enum split_type split_type,
-					      pgoff_t end, int *nr_shmem_dropped)
+					      struct list_head *list, enum split_type split_type)
 {
 	struct folio *end_folio = folio_next(folio);
 	struct folio *new_folio, *next;
+	int nr_shmem_dropped = 0;
 	struct lruvec *lruvec;
+	pgoff_t end = 0;
 	int ret;
 
+	/*
+	 * __split_frozen_folio() may need to trim off pages beyond
+	 * EOF: but on 32-bit, i_size_read() takes an irq-unsafe
+	 * seqlock, which cannot be nested inside the page tree lock.
+	 * So note end now: i_size itself may be changed at any moment,
+	 * but folio lock is good enough to serialize the trimming.
+	 */
+	end = DIV_ROUND_UP(i_size_read(mapping->host), PAGE_SIZE);
+	if (shmem_mapping(mapping))
+		end = shmem_fallocend(mapping->host, end);
+
 	xas_lock_irq(xas);
 
 	/*
@@ -4101,10 +4113,9 @@ static int __folio_freeze_split_unmapped_file(struct folio *folio, unsigned int
 			continue;
 		}
 
-		VM_WARN_ON_ONCE(!nr_shmem_dropped);
 		/* Drop folio beyond EOF: ->index >= end */
-		if (shmem_mapping(mapping) && nr_shmem_dropped)
-			*nr_shmem_dropped += nr_pages;
+		if (shmem_mapping(mapping))
+			nr_shmem_dropped += nr_pages;
 		else if (folio_test_clear_dirty(new_folio))
 			folio_account_cleaned(new_folio,
 					      inode_to_wb(mapping->host));
@@ -4125,6 +4136,8 @@ static int __folio_freeze_split_unmapped_file(struct folio *folio, unsigned int
 
 fail:
 	xas_unlock_irq(xas);
+	if (nr_shmem_dropped)
+		shmem_uncharge(mapping->host, nr_shmem_dropped);
 	return ret;
 }
 
@@ -4161,9 +4174,7 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 	struct anon_vma *anon_vma = NULL;
 	int old_order = folio_order(folio);
 	struct folio *new_folio, *next;
-	int nr_shmem_dropped = 0;
 	enum ttu_flags ttu_flags = 0;
-	pgoff_t end = 0;
 	int ret;
 
 	VM_WARN_ON_ONCE_FOLIO(!folio_test_locked(folio), folio);
@@ -4240,17 +4251,6 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 
 		anon_vma = NULL;
 		i_mmap_lock_read(mapping);
-
-		/*
-		 * __split_frozen_folio() may need to trim off pages beyond
-		 * EOF: but on 32-bit, i_size_read() takes an irq-unsafe
-		 * seqlock, which cannot be nested inside the page tree lock.
-		 * So note end now: i_size itself may be changed at any moment,
-		 * but folio lock is good enough to serialize the trimming.
-		 */
-		end = DIV_ROUND_UP(i_size_read(mapping->host), PAGE_SIZE);
-		if (shmem_mapping(mapping))
-			end = shmem_fallocend(mapping->host, end);
 	}
 
 	/*
@@ -4266,16 +4266,12 @@ static int __folio_split(struct folio *folio, unsigned int new_order,
 
 	if (!is_anon) {
 		ret = __folio_freeze_split_unmapped_file(folio, new_order, split_at, &xas, mapping,
-							 true, list, split_type, end,
-							 &nr_shmem_dropped);
+							 true, list, split_type);
 	} else {
 		ret = __folio_freeze_split_unmapped_anon(folio, new_order, split_at, true,
 							 list, split_type);
 	}
 
-	if (nr_shmem_dropped)
-		shmem_uncharge(mapping->host, nr_shmem_dropped);
-
 	if (!ret && is_anon && !folio_is_device_private(folio))
 		ttu_flags = TTU_USE_SHARED_ZEROPAGE;
 

-- 
2.55.0

