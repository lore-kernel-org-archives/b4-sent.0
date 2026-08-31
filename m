From: Ackerley Tng <ackerleytng@google.com>
Date: Sun, 30 Aug 2026 17:25:19 -0700
Subject: [PATCH v12 18/45] KVM: guest_memfd: Handle lru_add fbatch
 refcounts during conversion safety check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-gmem-inplace-conversion-v12-18-85e5fd25252a@google.com>
References: <20260830-gmem-inplace-conversion-v12-0-85e5fd25252a@google.com>
In-Reply-To: <20260830-gmem-inplace-conversion-v12-0-85e5fd25252a@google.com>
To: aik@amd.com, andrew.jones@linux.dev, binbin.wu@linux.intel.com, 
 brauner@kernel.org, chao.p.peng@linux.intel.com, david@kernel.org, 
 jmattson@google.com, jthoughton@google.com, michael.roth@amd.com, 
 oupton@kernel.org, pankaj.gupta@amd.com, qperret@google.com, 
 rick.p.edgecombe@intel.com, rientjes@google.com, shivankg@amd.com, 
 steven.price@arm.com, willy@infradead.org, wyihan@google.com, 
 yan.y.zhao@intel.com, forkloop@google.com, pratyush@kernel.org, 
 suzuki.poulose@arm.com, aneesh.kumar@kernel.org, liam@infradead.org, 
 Paolo Bonzini <pbonzini@redhat.com>, 
 Sean Christopherson <seanjc@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Shuah Khan <shuah@kernel.org>, Vishal Annapurve <vannapurve@google.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Youngjun Park <youngjun.park@lge.com>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Kiryl Shutsemau <kas@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Jason Gunthorpe <jgg@ziepe.ca>, John Hubbard <jhubbard@nvidia.com>, 
 Peter Xu <peterx@redhat.com>, tarunsahu@google.com, 
 Randy Dunlap <rdunlap@infradead.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Fuad Tabba <fuad.tabba@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Baoquan He <baoquan.he@linux.dev>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>, 
 Fuad Tabba <fuad.tabba@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788135915; l=4735;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=Ty5BgQhIGN1xkSlbhdIOV4bbPZLbusnibdr1eTvGdlc=;
 b=91swEloDGQUbfYBsHAl/7syD81mtjIP2F0V0Ab45bJ3IEkR1Q5bwBtEL76LfwbU26GezrPCHL
 XT0wJWHs3EeBheGTp9WnqG2e2q+vGU7johvpQZYqq79+7IhHv7ZWqRu
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A guest_memfd folio has no outstanding references if guest_memfd holds the
only references on it. Any other references on the folio may indicate
another user, and guest_memfd cannot convert it to private if there may be
an existing host user.

A folio will have outstanding references if it is present in a per-CPU
lru_add fbatch. guest_memfd does not actually participate in LRU, but
freshly-allocated folios are still added to the lru_add fbatch for batch
LRU statistics processing.

A folio may also have extra refcounts if it is on the mlock fbatch.

These two known "usages" of the folio are handled by calling
lru_cache_drain_for_folio, which drains both the lru_add and mlock
fbatches. After draining, if the refcount is still elevated, then there are
truly outstanding references.

If the page may be dma pinned, DMA is using it and hence there are
outstanding references. folio_maybe_dma_pinned() can have false positives,
but that's only with a significant number of refcounts, at which point
draining LRU is not going to move the needle - it can still be concluded
that the folio has outstanding references.

If the page is still mapped after guest_memfd tried to unmap it earlier in
the conversion process, it also has outstanding references.

Return true and exit early to avoid unnecessary draining in these 2 cases.

Provide a drain status to only drain once ever while processing a batch of
folios.

Acked-by: Vlastimil Babka (SUSE) <vbabka@kernel.org>
Suggested-by: David Hildenbrand <david@kernel.org>
Reviewed-by: Fuad Tabba <fuad.tabba@linux.dev>
Reviewed-by: Binbin Wu <binbin.wu@linux.intel.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 mm/folio.c             |  2 ++
 virt/kvm/guest_memfd.c | 30 ++++++++++++++++++++++--------
 2 files changed, 24 insertions(+), 8 deletions(-)

diff --git a/mm/folio.c b/mm/folio.c
index c02dcea9c03c2..50a6dbe55998e 100644
--- a/mm/folio.c
+++ b/mm/folio.c
@@ -33,6 +33,7 @@
 #include <linux/page_idle.h>
 #include <linux/local_lock.h>
 #include <linux/buffer_head.h>
+#include <linux/kvm_types.h>
 
 #include "internal.h"
 #include "page_alloc.h"
@@ -926,6 +927,7 @@ void lru_cache_drain_for_folio(const struct folio *folio,
 			*drained = LRU_CACHE_DRAINED_ALL;
 	}
 }
+EXPORT_SYMBOL_FOR_KVM(lru_cache_drain_for_folio);
 
 atomic_t lru_disable_count = ATOMIC_INIT(0);
 
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index ac8e0c6d6e942..1fe935aaef36f 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -8,6 +8,7 @@
 #include <linux/mempolicy.h>
 #include <linux/pseudo_fs.h>
 #include <linux/pagemap.h>
+#include <linux/swap.h>
 
 #include "kvm_mm.h"
 #include "guest_memfd.h"
@@ -556,10 +557,28 @@ static int kvm_gmem_mas_preallocate(struct ma_state *mas, u64 attributes,
 	return mas_preallocate(mas, xa_mk_value(attributes), GFP_KERNEL);
 }
 
+static bool __folio_has_outstanding_references(struct folio *folio,
+					       enum lru_cache_drained *drained)
+{
+	if (folio_maybe_dma_pinned(folio) || folio_mapped(folio))
+		return true;
+
+	/* 1 reference held by filemap_get_folios() in the folio batch. */
+	lru_cache_drain_for_folio(folio, 1, drained);
+
+	/*
+	 * Outstanding references are anything other than those from the page
+	 * cache, plus 1 temporary reference held by filemap_get_folios() in the
+	 * folio batch.
+	 */
+	return folio_ref_count(folio) != folio_nr_pages(folio) + 1;
+}
+
 static bool kvm_gmem_has_outstanding_references(struct inode *inode,
 						pgoff_t start, size_t nr_pages,
 						pgoff_t *err_index)
 {
+	enum lru_cache_drained drained = LRU_CACHE_NOT_DRAINED;
 	struct address_space *mapping = inode->i_mapping;
 	pgoff_t last = start + nr_pages - 1;
 	bool has_outstanding = false;
@@ -570,17 +589,12 @@ static bool kvm_gmem_has_outstanding_references(struct inode *inode,
 	folio_batch_init(&fbatch);
 
 	next = start;
-	while (has_outstanding && filemap_get_folios(mapping, &next, last, &fbatch)) {
+	while (!has_outstanding && filemap_get_folios(mapping, &next, last, &fbatch)) {
 		for (i = 0; i < folio_batch_count(&fbatch); ++i) {
 			struct folio *folio = fbatch.folios[i];
 
-			/*
-			 * Outstanding references are anything other than those
-			 * from the page cache, plus 1 temporary reference held
-			 * by filemap_get_folios() in the folio batch.
-			 */
-			if (folio_ref_count(folio) != folio_nr_pages(folio) + 1) {
-				has_outstanding = true;
+			has_outstanding = __folio_has_outstanding_references(folio, &drained);
+			if (has_outstanding) {
 				*err_index = max(start, folio->index);
 				break;
 			}

-- 
2.55.0.897.gb25b4bd76c-goog

