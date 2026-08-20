From: Kairui Song <kasong@tencent.com>
Date: Fri, 21 Aug 2026 02:55:25 +0800
Subject: [PATCH v3 12/18] mm/huge_memory: add kerneldoc for the split
 helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-swap-thp-cleanup-v3-12-9b43f5163238@tencent.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787252124; l=3229;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=kkYICD6QbWqRFssjOxU44lo2ZuCNOXywu0Ctt6XQNZg=;
 b=iTb0ckBN6dHmAPctrV4Br62LLWX6ZAgNv/UeyxZEBzV+MXrW6V5bKZvdnEYS4etaaE7oZcsiQ
 Tnhy+6ivET2AtWL0LL710cO5ulJmEpy4gR0CElo5+/xpitRNlIxHA6b
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document __folio_split_unmap_and_freeze() and
__folio_split_unmap_and_freeze_file(), and rename the file split
helper's definition to match its call site.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/huge_memory.c | 38 ++++++++++++++++++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 0186238e0d1e..72b364a90062 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -3928,6 +3928,25 @@ static unsigned int folio_cache_ref_count(const struct folio *folio)
 	return folio_nr_pages(folio);
 }
 
+/**
+ * __folio_split_unmap_and_freeze() - split an anon or swap cache folio
+ * @folio: folio to split, must be locked
+ * @new_order: the order of the after-split folios (uniform split), or the
+ *             smallest order of the after-split folios (non-uniform split)
+ * @split_at: in non-uniform split, the folio containing @split_at is split
+ *            until its order becomes @new_order
+ * @do_lru: if true, add after-split folios to @list if non NULL, otherwise to
+ *          the LRU list
+ * @anon_unmap: if true, unmap @folio before the split and remap it after
+ * @list: after-split folios will be put on it if non NULL
+ * @split_type: perform uniform split or not (non-uniform split)
+ *
+ * Helper for splitting an anon or swap cache folio. It unmaps @folio (unless
+ * @anon_unmap is false), freezes its refcount, and performs the split, updates
+ * the swap cache entries. Split folios are unfrozen and remapped.
+ *
+ * Return: 0 on success, otherwise an error number is returned.
+ */
 static int __folio_split_unmap_and_freeze(struct folio *folio, unsigned int new_order,
 					  struct page *split_at, bool do_lru, bool anon_unmap,
 					  struct list_head *list, enum split_type split_type)
@@ -4061,6 +4080,25 @@ static int __folio_split_unmap_and_freeze(struct folio *folio, unsigned int new_
 	return ret;
 }
 
+/**
+ * __folio_split_unmap_and_freeze_file() - split a file-backed folio
+ * @folio: folio to split, must be locked and file-backed
+ * @new_order: the order of the after-split folios (uniform split), or the
+ *             smallest order of the after-split folios (non-uniform split)
+ * @split_at: in non-uniform split, the folio containing @split_at is split
+ *            until its order becomes @new_order
+ * @do_lru: if true, add after-split folios to @list if non NULL, otherwise to
+ *          the LRU list
+ * @list: after-split folios will be put on it if non NULL
+ * @split_type: perform uniform split or not (non-uniform split)
+ *
+ * Helper for splitting a file-backed folio. It unmaps @folio, freezes its
+ * refcount, and perform the split, updates the page cache entries. Split
+ * folios are unfrozen but not remapped, they are faulted back in on demand.
+ *
+ * Return: 0 on success, otherwise an error number is returned. (if -ENOMEM
+ * is returned, @folio might be split but not to @new_order)
+ */
 static int __folio_split_unmap_and_freeze_file(struct folio *folio, unsigned int new_order,
 					       struct page *split_at, bool do_lru,
 					       struct list_head *list, enum split_type split_type)

-- 
2.55.0

