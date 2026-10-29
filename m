From: Kairui Song <kasong@tencent.com>
Date: Fri, 30 Oct 2026 02:31:43 +0800
Subject: [PATCH 3/3] mm, swap: fix large swap-in across swap file extents
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-swap-fixes-v1-3-73f73a59f2fc@tencent.com>
References: <20261030-swap-fixes-v1-0-73f73a59f2fc@tencent.com>
In-Reply-To: <20261030-swap-fixes-v1-0-73f73a59f2fc@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <baoquan.he@linux.dev>, Barry Song <baohua@kernel.org>, 
 Youngjun Park <youngjun.park@lge.com>, Yosry Ahmed <yosry@kernel.org>, 
 Chengming Zhou <chengming.zhou@linux.dev>, 
 Usama Arif <usamaarif642@gmail.com>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Chuanhua Han <hanchuanhua@oppo.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 Mani Tofigh <mt4022@columbia.edu>, linux-kernel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>, Chris Mason <mason@kernel.org>, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793298765; l=4381;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=noZdScpFxNIQJGtkMJULE0ZL5MZND/LDKx/hvQROY0Y=;
 b=oR1vrkIjkjtg6R0rp3bKtmAM+V55cCGputUBDJNxtY6bYlA7dwVCqz/UH34NKd2/yGd9DtfFF
 JOvSxwQeHjTC1hZnmX/wUVYYbQ8H7WbL5/OrEGauUS/BuOGwua+7L8K
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chris Mason <mason@kernel.org>

A page fault can give an unprivileged process blocks of other users'
files instead of its own swapped-out data. This affects systems with a
swap file on a synchronous block device, such as brd or zram. For an
anonymous mapping it also takes a huge page size below the PMD size
(mTHP), such as 64 KiB, that is enabled for anonymous memory.

A swap area is divided into slots of one page each. A swap file is a
regular file, so adjacent swap slots can lie in two extents, far apart
on disk. A folio is read from swap with a single bio that starts at the
sector of the folio's first slot. So all slots of a large folio must be
contiguous on disk.

The swap allocator knows this: it only hands out a run of slots for a
large folio if the swap area is a block device (SWP_BLKDEV).

The swap-in path does not. On a synchronous device (SWP_SYNCHRONOUS_IO),
one that always completes I/O in the submitter's context, do_swap_page()
can read several swapped-out pages as one large folio (a large swap-in).
thp_swapin_suitable_orders() makes that decision, and looks only at the
swap offsets (the slot numbers) in the page table.

Pages that were swapped out one at a time can end up in consecutive,
aligned slots, and are then read as one large folio. If the extent of
the first slot ends inside that folio, the rest of the folio is filled
from the blocks that follow the extent on disk. These blocks can belong
to other files.

Reproduced with a fragmented swap file on brd and 64 KiB folios enabled.
After single pages were swapped out, a fault returned blocks of a
root-owned file with mode 0600.

Fix this by allowing a large swap-in only when SWP_BLKDEV is set.

Known gaps:
- A swap file on zram, brd, pmem or btt is now read one page at a time,
  even where its slots lie in one extent. Its swpin counters in
  /sys/kernel/mm/transparent_hugepage/hugepages-*/stats stay at 0.
- With the posted "mm, swap: enable THP swapin for xswap entries"
  applied as well, the large swap-in that it adds never happens. That
  patch gives its swap device SWP_SYNCHRONOUS_IO but not SWP_BLKDEV, so
  the new check would have to let that device pass.

Fixes: 242d12c98174 ("mm: support large folios swap-in for sync io devices")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Chris Mason <mason@kernel.org>
Signed-off-by: David Hildenbrand (Arm) <david@kernel.org>
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/memory.c | 16 +++++++++++++---
 1 file changed, 13 insertions(+), 3 deletions(-)

diff --git a/mm/memory.c b/mm/memory.c
index b65b56fe9714..944f57153c89 100644
--- a/mm/memory.c
+++ b/mm/memory.c
@@ -4863,7 +4863,8 @@ static inline unsigned long thp_swap_suitable_orders(pgoff_t swp_offset,
 	return orders;
 }
 
-static unsigned long thp_swapin_suitable_orders(struct vm_fault *vmf)
+static unsigned long thp_swapin_suitable_orders(struct swap_info_struct *si,
+						struct vm_fault *vmf)
 {
 	struct vm_area_struct *vma = vmf->vma;
 	unsigned long orders;
@@ -4888,6 +4889,14 @@ static unsigned long thp_swapin_suitable_orders(struct vm_fault *vmf)
 	if (!zswap_never_enabled())
 		return 0;
 
+	/*
+	 * Neighbouring slots of a swap file can lie in two extents, and a folio
+	 * is read with one bio. The flag is set in swapon() and stays, so the
+	 * race is benign.
+	 */
+	if (!data_race(si->flags & SWP_BLKDEV))
+		return 0;
+
 	entry = softleaf_from_pte(vmf->orig_pte);
 	/*
 	 * Get a list of all the (large) orders below PMD_ORDER that are enabled
@@ -4924,7 +4933,8 @@ static unsigned long thp_swapin_suitable_orders(struct vm_fault *vmf)
 	return orders;
 }
 #else /* !CONFIG_TRANSPARENT_HUGEPAGE */
-static unsigned long thp_swapin_suitable_orders(struct vm_fault *vmf)
+static unsigned long thp_swapin_suitable_orders(struct swap_info_struct *si,
+						struct vm_fault *vmf)
 {
 	return 0;
 }
@@ -5070,7 +5080,7 @@ vm_fault_t do_swap_page(struct vm_fault *vmf)
 		/* Swapin bypasses readahead for SWP_SYNCHRONOUS_IO devices */
 		if (data_race(si->flags & SWP_SYNCHRONOUS_IO))
 			folio = swapin_sync(entry, GFP_HIGHUSER_MOVABLE,
-					    thp_swapin_suitable_orders(vmf) | BIT(0),
+					    thp_swapin_suitable_orders(si, vmf) | BIT(0),
 					    vmf, NULL, 0);
 		else
 			folio = swapin_readahead(entry, GFP_HIGHUSER_MOVABLE, vmf);

-- 
2.56.0

