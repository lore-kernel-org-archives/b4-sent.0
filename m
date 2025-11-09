From: Kairui Song <kasong@tencent.com>
Date: Mon, 10 Nov 2025 02:06:03 +0800
Subject: [PATCH] Revert "mm, swap: avoid redundant swap device pinning"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251110-revert-78524b05f1a3-v1-1-88313f2b9b20@tencent.com>
X-B4-Tracking: v=1; b=H4sIAArYEGkC/x2MQQqAIBAAvxJ7TnAtSftKdNBaay8WGhGEf086D
 szMC5kSU4axeSHRzZmPWAHbBpbdxY0Er5VBSaURpRVVonSJwWjVe6kDuk7I3qGy2lMwDmp5Jgr
 8/NdpLuUDy1WRSmUAAAA=
X-Change-ID: 20251109-revert-78524b05f1a3-04a1295bef8a
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Barry Song <baohua@kernel.org>, 
 Chris Li <chrisl@kernel.org>, Johannes Weiner <hannes@cmpxchg.org>, 
 Yosry Ahmed <yosry.ahmed@linux.dev>, 
 Chengming Zhou <chengming.zhou@linux.dev>, 
 Youngjun Park <youngjun.park@lge.com>, Kairui Song <ryncsn@gmail.com>, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762711563; l=4133;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=alE+X02rbk4jwNfT7auzmxmmmbItfQDo8i+kaNeAHjY=;
 b=y+ozs+sm7ni2QmqCYkgxfgsn49ITpx52INQ0Dq+5Kq9kcCBk7gA/JGdd6qZOmhRbyTjalAn2s
 R3zWuGKIM3zBS6pl2r1pQbcyZsst8HOxUqBN0/qrRpv0I1JrjRU40Ny
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This reverts commit 78524b05f1a3e16a5d00cc9c6259c41a9d6003ce.

While reviewing recent leaf entry changes, I noticed that commit
78524b05f1a3 ("mm, swap: avoid redundant swap device pinning") isn't
correct. It's true that most all callers of __read_swap_cache_async are
already holding a swap entry reference, so the repeated swap device
pinning isn't needed on the same swap device, but it is possible that
VMA readahead (swap_vma_readahead()) may encounter swap entries from a
different swap device when there are multiple swap devices, and call
__read_swap_cache_async without holding a reference to that swap device.

So it is possible to cause a UAF if swapoff of device A raced with
swapin on device B, and VMA readahead tries to read swap entries from
device A. It's not easy to trigger but in theory possible to cause real
issues. And besides, that commit made swap more vulnerable to issues
like corrupted page tables.

Just revert it. __read_swap_cache_async isn't that sensitive to
performance after all, as it's mostly used for SSD/HDD swap devices with
readahead. SYNCHRONOUS_IO devices may fallback onto it for swap count >
1 entries, but very soon we will have a new helper and routine for
such devices, so they will never touch this helper or have redundant
swap device reference overhead.

Fixes: 78524b05f1a3 ("mm, swap: avoid redundant swap device pinning")
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 mm/swap_state.c | 14 ++++++--------
 mm/zswap.c      |  8 +-------
 2 files changed, 7 insertions(+), 15 deletions(-)

diff --git a/mm/swap_state.c b/mm/swap_state.c
index 3f85a1c4cfd9..0c25675de977 100644
--- a/mm/swap_state.c
+++ b/mm/swap_state.c
@@ -406,13 +406,17 @@ struct folio *__read_swap_cache_async(swp_entry_t entry, gfp_t gfp_mask,
 		struct mempolicy *mpol, pgoff_t ilx, bool *new_page_allocated,
 		bool skip_if_exists)
 {
-	struct swap_info_struct *si = __swap_entry_to_info(entry);
+	struct swap_info_struct *si;
 	struct folio *folio;
 	struct folio *new_folio = NULL;
 	struct folio *result = NULL;
 	void *shadow = NULL;
 
 	*new_page_allocated = false;
+	si = get_swap_device(entry);
+	if (!si)
+		return NULL;
+
 	for (;;) {
 		int err;
 
@@ -499,6 +503,7 @@ struct folio *__read_swap_cache_async(swp_entry_t entry, gfp_t gfp_mask,
 	put_swap_folio(new_folio, entry);
 	folio_unlock(new_folio);
 put_and_return:
+	put_swap_device(si);
 	if (!(*new_page_allocated) && new_folio)
 		folio_put(new_folio);
 	return result;
@@ -518,16 +523,11 @@ struct folio *read_swap_cache_async(swp_entry_t entry, gfp_t gfp_mask,
 		struct vm_area_struct *vma, unsigned long addr,
 		struct swap_iocb **plug)
 {
-	struct swap_info_struct *si;
 	bool page_allocated;
 	struct mempolicy *mpol;
 	pgoff_t ilx;
 	struct folio *folio;
 
-	si = get_swap_device(entry);
-	if (!si)
-		return NULL;
-
 	mpol = get_vma_policy(vma, addr, 0, &ilx);
 	folio = __read_swap_cache_async(entry, gfp_mask, mpol, ilx,
 					&page_allocated, false);
@@ -535,8 +535,6 @@ struct folio *read_swap_cache_async(swp_entry_t entry, gfp_t gfp_mask,
 
 	if (page_allocated)
 		swap_read_folio(folio, plug);
-
-	put_swap_device(si);
 	return folio;
 }
 
diff --git a/mm/zswap.c b/mm/zswap.c
index 5d0f8b13a958..aefe71fd160c 100644
--- a/mm/zswap.c
+++ b/mm/zswap.c
@@ -1005,18 +1005,12 @@ static int zswap_writeback_entry(struct zswap_entry *entry,
 	struct folio *folio;
 	struct mempolicy *mpol;
 	bool folio_was_allocated;
-	struct swap_info_struct *si;
 	int ret = 0;
 
 	/* try to allocate swap cache folio */
-	si = get_swap_device(swpentry);
-	if (!si)
-		return -EEXIST;
-
 	mpol = get_task_policy(current);
 	folio = __read_swap_cache_async(swpentry, GFP_KERNEL, mpol,
-			NO_INTERLEAVE_INDEX, &folio_was_allocated, true);
-	put_swap_device(si);
+				NO_INTERLEAVE_INDEX, &folio_was_allocated, true);
 	if (!folio)
 		return -ENOMEM;
 

---
base-commit: 02dafa01ec9a00c3758c1c6478d82fe601f5f1ba
change-id: 20251109-revert-78524b05f1a3-04a1295bef8a

Best regards,
-- 
Kairui Song <kasong@tencent.com>

