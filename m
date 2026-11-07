From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:08 -0800
Subject: [PATCH RFC v3 34/88] KVM: guest_memfd: Support converting to
 shared in PFN mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-34-8484dde66a7e@google.com>
References: <20261106-gmem-alternative-providers-v3-0-8484dde66a7e@google.com>
In-Reply-To: <20261106-gmem-alternative-providers-v3-0-8484dde66a7e@google.com>
To: Alexey Kardashevskiy <aik@amd.com>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 Christian Brauner <brauner@kernel.org>, 
 David Hildenbrand <david@kernel.org>, David Woodhouse <dwmw2@infradead.org>, 
 Fred Griffoul <fgriffo@amazon.co.uk>, 
 Jacob Pan <jacob.pan@linux.microsoft.com>, Jianxiong Gao <jxgao@google.com>, 
 John Starks <John.Starks@microsoft.com>, 
 Michael Roth <michael.roth@amd.com>, Paolo Bonzini <pbonzini@redhat.com>, 
 Samiullah Khawaja <skhawaja@google.com>, 
 Sean Christopherson <seanjc@google.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Tarun Sahu <tarunsahu@google.com>, Vishal Annapurve <vannapurve@google.com>, 
 Xu Yilun <yilun.xu@linux.intel.com>, Fuad Tabba <fuad.tabba@linux.dev>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=5043;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=Iv1zxYO7fP3JXSyVWe6MUD/FvJRtFUd+FcQgJ86kKzs=;
 b=t9r2seWbuOAXmUmfzxNh546Jm5ih8d+H+/MViGmGMCCMkk14rA7b1r8r4bFuLkICvw9lrZNT9
 aVvzkME4C1NDEPrlUHY28C3SvXO2C/Assv0iGM+b0fiXHh5FEAyWZKf
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When converting memory attributes to shared, guest_memfd iterates
through folios in the page cache to notify architecture code.

In PFN mode, memory is not backed by page cache folios. To notify
architecture code without unintentionally triggering memory allocation
in dynamic providers for unpopulated ranges, introduce the
lookup_pfn_range provider operation. It returns the PFN and number of
pages of contiguous backing memory, or -ENOENT if not allocated.

Add support for PFN mode when converting to shared by querying
lookup_pfn_range and converting contiguous chunks.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/linux/guest_memfd.h | 19 +++++++++++++++++-
 virt/kvm/guest_memfd.c      | 47 +++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 65 insertions(+), 1 deletion(-)

diff --git a/include/linux/guest_memfd.h b/include/linux/guest_memfd.h
index 9fdc0bd1a7190..e965aeca061a6 100644
--- a/include/linux/guest_memfd.h
+++ b/include/linux/guest_memfd.h
@@ -28,7 +28,22 @@ struct mempolicy;
  *           @pfn with uniform @pfn_attrs in @max_order. Once @get_pfn succeeds,
  *           the provider must keep the @index-to-@pfn mapping and @pfn_attrs
  *           constant, and the memory accessible, until guest_memfd stops using
- *           this page. Returns a negative error code on failure.
+ *           this page. Returns a negative error code on failure. The provider
+ *           must define @lookup_pfn_range when @get_pfn is defined.
+ * @lookup_pfn_range: Look up the PFN for a given index. This only checks for
+ *                    the existence of backing pages and should not allocate
+ *                    memory. Returns 0 on success with the physical frame
+ *                    number in @pfn and the number of physically contiguous
+ *                    pages in @nr_pages (@nr_pages need not be reduced for
+ *                    pages with different PFN attributes). Once
+ *                    @lookup_pfn_range succeeds, the provider must keep the
+ *                    existence of the pages and the @index-to-@pfn mapping
+ *                    constant until guest_memfd stops using the range. If
+ *                    backing memory is not available at @index, return -ENOENT
+ *                    with @nr_pages set to the number of consecutive indices
+ *                    starting from @index that have no entry. Return a negative
+ *                    error code on other failure. The provider must define
+ *                    @get_pfn when @lookup_pfn_range is defined.
  *
  * Used by filesystems and device drivers that provide memory for guest_memfd.
  */
@@ -40,6 +55,8 @@ struct guest_memfd_provider_operations {
 	void (*invalidate_folio)(void *provider, struct folio *folio);
 	int (*get_pfn)(void *provider, pgoff_t index, unsigned long *pfn,
 		       int *max_order, u64 *pfn_attrs);
+	int (*lookup_pfn_range)(void *provider, pgoff_t index,
+				unsigned long *pfn, size_t *nr_pages);
 };
 
 #endif /* _LINUX_GUEST_MEMFD_H */
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index ceef61cb63a0d..0e392b8735259 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -149,6 +149,27 @@ static int gmem_provider_get_pfn(struct gmem_inode *gi, pgoff_t index,
 	return 0;
 }
 
+#ifdef CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT
+static int gmem_provider_lookup_pfn_range(struct gmem_inode *gi, pgoff_t index,
+					  kvm_pfn_t *pfn, size_t *nr_pages)
+{
+	unsigned long raw_pfn;
+	int r;
+
+	r = gi->provider_ops->lookup_pfn_range(gi->provider, index, &raw_pfn,
+					       nr_pages);
+	if (!r || r == -ENOENT) {
+		if (WARN_ON_ONCE(!*nr_pages))
+			return -EINVAL;
+	}
+	if (r)
+		return r;
+
+	*pfn = raw_pfn;
+	return 0;
+}
+#endif
+
 static void gmem_provider_invalidate_folio(struct gmem_inode *gi,
 					   struct folio *folio)
 {
@@ -830,10 +851,36 @@ static bool kvm_gmem_has_outstanding_references(struct inode *inode,
 #ifdef CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT
 static void kvm_gmem_make_shared(struct inode *inode, pgoff_t start, pgoff_t end)
 {
+	struct gmem_inode *gi = GMEM_I(inode);
 	struct folio_batch fbatch;
 	pgoff_t next = start;
 	int i;
 
+	if (kvm_gmem_is_pfn_mode(gi)) {
+		pgoff_t index;
+
+		for (index = start; index < end; ) {
+			size_t step = 1;
+			size_t nr_pages;
+			kvm_pfn_t pfn;
+			int r;
+
+			r = gmem_provider_lookup_pfn_range(gi, index, &pfn, &nr_pages);
+			if (!r || r == -ENOENT) {
+				step = min_t(size_t, nr_pages, end - index);
+				if (!r)
+					kvm_arch_gmem_make_shared(pfn, step);
+			} else {
+				WARN_ONCE(1, "unexpected lookup_pfn_range error %d at index 0x%lx\n",
+					  r, index);
+			}
+
+			index += step;
+			cond_resched();
+		}
+		return;
+	}
+
 	folio_batch_init(&fbatch);
 	while (filemap_get_folios(inode->i_mapping, &next, end - 1, &fbatch)) {
 		for (i = 0; i < folio_batch_count(&fbatch); ++i) {

-- 
2.56.0.455.g6c5a503b38-goog

