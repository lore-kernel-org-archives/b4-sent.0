From: Chia-I Wu <olvaffe@gmail.com>
Date: Tue, 19 May 2026 21:31:46 -0700
Subject: [PATCH RFC v2] mm/shmem: set __GFP_SKIP_KASAN for
 swap_cluster_readahead
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-panthor-kasan-v2-1-b7384458f076@gmail.com>
X-B4-Tracking: v=1; b=H4sIADE5DWoC/3WNwQ6CMBBEf4Xs2Rq2iFVPJiZ+gFfDodAVVqUlL
 RIN6b8LePY4kzdvRgjkmQIckhE8DRzY2SnIVQJVo21Ngs2UQaZym+YoRadt3zgvHjpoKzDdKCW
 zfakNwrTpPN34vfiucDmfoPiV4VXeqepn04w1HHrnP8vrgAv852BAgcLsTEZS5UZheaxbzc915
 VooYoxfOcyRsMEAAAA=
X-Change-ID: 20260512-panthor-kasan-10477239bad1
To: Andrey Ryabinin <ryabinin.a.a@gmail.com>, 
 Alexander Potapenko <glider@google.com>, 
 Andrey Konovalov <andreyknvl@gmail.com>, Dmitry Vyukov <dvyukov@google.com>, 
 Vincenzo Frascino <vincenzo.frascino@arm.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Hugh Dickins <hughd@google.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>
Cc: kasan-dev@googlegroups.com, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Chia-I Wu <olvaffe@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1682; i=olvaffe@gmail.com;
 h=from:subject:message-id; bh=BTF9Nk+Dq+n2u4+GJl/PHmatAgLww9uk/603AjD4oqQ=;
 b=owGbwMvMwCV2uuv6dHcvAWnG02pJDFm8lp4vXjMX63DYH6zfsNFHOsppbc8JFS9DxY9Le/sfM
 L7/lvKmo5SFQYyLQVZMkWWn0uevgRmFl+8IN66DmcPKBDKEgYtTACYSVs3I8CN5rcGd7Bo1GbMP
 j3PDu149qa8q4PfaPDvyv3hNoNv3DEaG128X/zofue3/qnvlgc4pdk+3TCn7nRI0YelNKaaP7Mk
 3mQA=
X-Developer-Key: i=olvaffe@gmail.com; a=openpgp;
 fpr=8C8F791802BBB330399230F27CB6CD58BE1B6831
X-Endpoint-Received: by B4 Relay for olvaffe@gmail.com/default with auth_id=776
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

swap_cluster_readahead can allocate folios for other mappings. If the
gfp flags do not have __GFP_SKIP_KASAN, but the other mappings have
PROT_MTE, we can end up with false KASAN errors such as

  BUG: KASAN: invalid-access in swap_writepage+0xb0/0x21c
  Read at addr f5ffff81aa71dff8 by task WM.task-4/6956
  Pointer tag: [f5], memory tag: [f9]

In the above example, because __GFP_SKIP_KASAN was missing, KASAN set
both pointer tag and memory tag to 0xf5 when swap_cluster_readahead
allocated the folio. But the userspace had already set the memory tag to
0xf9 before swapped out. arch_swap_restore restored the memory tag back
to 0xf9, leading to the mismatch.

Signed-off-by: Chia-I Wu <olvaffe@gmail.com>
---
Changes in v2:
- set __GFP_SKIP_KASAN for shmem instead of drm/panthor
- Link to v1: https://patch.msgid.link/20260512-panthor-kasan-v1-1-d8d3e275d71b@gmail.com
---
 mm/shmem.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/mm/shmem.c b/mm/shmem.c
index 3b5dc21b323c2..db9130a8c5b76 100644
--- a/mm/shmem.c
+++ b/mm/shmem.c
@@ -1784,6 +1784,11 @@ static struct folio *shmem_swapin_cluster(swp_entry_t swap, gfp_t gfp,
 	pgoff_t ilx;
 	struct folio *folio;
 
+	/* swap_cluster_readahead might cross the mapping boundary and
+	 * allocate pages for other mappings. We have to skip KASAN.
+	 */
+	gfp |= __GFP_SKIP_KASAN;
+
 	mpol = shmem_get_pgoff_policy(info, index, 0, &ilx);
 	folio = swap_cluster_readahead(swap, gfp, mpol, ilx);
 	mpol_cond_put(mpol);

---
base-commit: 5200f5f493f79f14bbdc349e402a40dfb32f23c8
change-id: 20260512-panthor-kasan-10477239bad1

Best regards,
--  
Chia-I Wu <olvaffe@gmail.com>

