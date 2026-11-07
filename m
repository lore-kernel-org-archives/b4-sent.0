From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:16 -0800
Subject: [PATCH RFC v3 42/88] KVM: guest_memfd: Export kvm_gmem_revoke for
 provider-driven revocation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-42-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=9183;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=KGi0b4edDBIuTocBQekssX77k5i2otDcPksXtOPmhvI=;
 b=Te9++pLFJFnW4N3FxCx+9OU7l2p3qOhL8KAm2XxPNG+NWA488ixSARUq8p61w3XvYZUqQL9Hq
 +22sSMjPqkqCYF7whbd+ceNyTK0LG1TKeJMLvwoXrP5278iHSI2dzwu
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Providers may dynamically revoke physical memory ranges (e.g., dynamic
page removal or device teardown) and need a mechanism to sever guest and
host mappings and reclaim confidential architecture state.

Introduce __kvm_gmem_revoke() to share the core invalidation and
reclamation path between kvm_gmem_punch_hole() and kvm_gmem_revoke().

Introduce boolean to control whether to call .put_pfn_range().
.put_pfn_range() must not be called when revoke is used by a provider,
because the provider already initiated the revocation and calling back into
the provider could lead to self-deadlock or re-entrancy on provider locks.

Export kvm_gmem_revoke(struct inode *inode, pgoff_t start, size_t nr_pages,
const unsigned long *pfn) via EXPORT_SYMBOL_GPL. Providers must pass
both start and pfn.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 arch/x86/kvm/Makefile       |  3 +-
 include/linux/guest_memfd.h | 31 ++++++++++++++++----
 virt/kvm/guest_memfd.c      | 70 +++++++++++++++++++++++++++++++++++++++------
 3 files changed, 88 insertions(+), 16 deletions(-)

diff --git a/arch/x86/kvm/Makefile b/arch/x86/kvm/Makefile
index c6bf463f50327..5fd01bd19d1c4 100644
--- a/arch/x86/kvm/Makefile
+++ b/arch/x86/kvm/Makefile
@@ -61,7 +61,8 @@ exports_grep_trailer := --include='*.[ch]' -nrw $(srctree)/virt/kvm $(srctree)/a
 				-e kvm_page_track_unregister_notifier \
 				-e kvm_write_track_add_gfn \
 				-e kvm_write_track_remove_gfn \
-				-e kvm_file_to_kvm_fn
+				-e kvm_file_to_kvm_fn \
+				-e kvm_gmem_revoke
 
 # Force grep to emit a goofy group separator that can in turn be replaced with
 # the above newline macro (newlines in Make are a nightmare).  Note, grep only
diff --git a/include/linux/guest_memfd.h b/include/linux/guest_memfd.h
index 697f8f8c9b0ae..fb2279a001ebf 100644
--- a/include/linux/guest_memfd.h
+++ b/include/linux/guest_memfd.h
@@ -28,8 +28,13 @@ struct mempolicy;
  *           @pfn with uniform @pfn_attrs in @max_order. Once @get_pfn succeeds,
  *           the provider must keep the @index-to-@pfn mapping and @pfn_attrs
  *           constant, and the memory accessible, until guest_memfd stops using
- *           this page. Returns a negative error code on failure. The provider
- *           must define @lookup_pfn_range when @get_pfn is defined.
+ *           this page. Do not take locks held across kvm_gmem_revoke().
+ *           Returns a negative error code on failure. The provider must define
+ *           @lookup_pfn_range when @get_pfn is defined.
+ * @mmap: Optional callback to set up user mappings. Called when userspace calls
+ *        mmap() on guest_memfd. The provider can customize VMA flags,
+ *        cacheability/protections, or reject the mapping. If not defined,
+ *        guest_memfd falls back to default mapping behavior.
  * @lookup_pfn_range: Look up the PFN for a given index. This only checks for
  *                    the existence of backing pages and should not allocate
  *                    memory. Returns 0 on success with the physical frame
@@ -41,15 +46,18 @@ struct mempolicy;
  *                    constant until guest_memfd stops using the range. If
  *                    backing memory is not available at @index, return -ENOENT
  *                    with @nr_pages set to the number of consecutive indices
- *                    starting from @index that have no entry. Return a negative
- *                    error code on other failure. The provider must define
- *                    @get_pfn when @lookup_pfn_range is defined.
+ *                    starting from @index that have no entry. Do not take locks
+ *                    held across kvm_gmem_revoke(). Return a negative error
+ *                    code on other failure. The provider must define @get_pfn
+ *                    when @lookup_pfn_range is defined.
  * @put_pfn_range: Release a range of PFNs previously obtained for a given
  *                 index. Called with the exclusive filemap invalidate lock held.
  *                 This indicates to the provider that guest_memfd is no longer
  *                 using the memory range. The provider does not need to ensure
  *                 that backing memory is present; if backing memory is not
- *                 available, the provider should skip the unbacked range.
+ *                 available, the provider should skip the unbacked range. Not
+ *                 called on kvm_gmem_revoke(). Do not take locks held across
+ *                 kvm_gmem_revoke().
  *
  * Used by filesystems and device drivers that provide memory for guest_memfd.
  */
@@ -66,4 +74,15 @@ struct guest_memfd_provider_operations {
 	void (*put_pfn_range)(void *provider, pgoff_t index, size_t nr_pages);
 };
 
+#ifdef CONFIG_KVM_GUEST_MEMFD
+int kvm_gmem_revoke(struct inode *inode, pgoff_t start, size_t nr_pages,
+		    const unsigned long *pfn);
+#else
+static inline int kvm_gmem_revoke(struct inode *inode, pgoff_t start, size_t nr_pages,
+				  const unsigned long *pfn)
+{
+	return -EOPNOTSUPP;
+}
+#endif
+
 #endif /* _LINUX_GUEST_MEMFD_H */
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 1b6fc44ba00bb..023bf095340be 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -433,18 +433,25 @@ static void kvm_gmem_pfn_reclaim(struct gmem_inode *gi, pgoff_t start, pgoff_t e
 static void kvm_gmem_pfn_reclaim(struct gmem_inode *gi, pgoff_t start, pgoff_t end) {}
 #endif
 
-static long kvm_gmem_punch_hole(struct inode *inode, loff_t offset, loff_t len)
+static int __kvm_gmem_revoke(struct inode *inode, pgoff_t start,
+			      size_t nr_pages, const unsigned long *pfn,
+			      bool put_pfn_range)
 {
 	enum kvm_gfn_range_filter filter = kvm_gmem_get_all_gfns_filter(inode);
-	loff_t size = i_size_read(inode);
-	pgoff_t start, end;
+	pgoff_t max_pages = i_size_read(inode) >> PAGE_SHIFT;
+	loff_t offset, len;
+	pgoff_t end;
 
-	if (offset >= size)
+	if (start >= max_pages)
 		return 0;
 
-	len = min(len, size - offset);
-	start = offset >> PAGE_SHIFT;
-	end = (offset + len) >> PAGE_SHIFT;
+	nr_pages = min_t(size_t, nr_pages, max_pages - start);
+	if (!nr_pages)
+		return 0;
+
+	offset = (loff_t)start << PAGE_SHIFT;
+	len = (loff_t)nr_pages << PAGE_SHIFT;
+	end = start + nr_pages;
 
 	/*
 	 * Bindings must be stable across invalidation to ensure the start+end
@@ -456,8 +463,14 @@ static long kvm_gmem_punch_hole(struct inode *inode, loff_t offset, loff_t len)
 
 	if (kvm_gmem_is_pfn_mode(GMEM_I(inode))) {
 		unmap_mapping_range(inode->i_mapping, offset, len, 0);
-		kvm_gmem_pfn_reclaim(GMEM_I(inode), start, end);
-		gmem_provider_put_pfn_range(GMEM_I(inode), start, end - start);
+#ifdef CONFIG_HAVE_KVM_ARCH_GMEM_RECLAIM
+		if (pfn)
+			kvm_arch_gmem_reclaim(*pfn, nr_pages);
+		else
+			kvm_gmem_pfn_reclaim(GMEM_I(inode), start, end);
+#endif
+		if (put_pfn_range)
+			gmem_provider_put_pfn_range(GMEM_I(inode), start, nr_pages);
 	} else {
 		truncate_inode_pages_range(inode->i_mapping, offset, offset + len - 1);
 	}
@@ -469,6 +482,45 @@ static long kvm_gmem_punch_hole(struct inode *inode, loff_t offset, loff_t len)
 	return 0;
 }
 
+static long kvm_gmem_punch_hole(struct inode *inode, loff_t offset, loff_t len)
+{
+	return __kvm_gmem_revoke(inode, offset >> PAGE_SHIFT, len >> PAGE_SHIFT,
+				 NULL, true);
+}
+
+/**
+ * kvm_gmem_revoke - Revoke and reclaim a range of memory in guest_memfd.
+ * @inode:    The guest_memfd inode.
+ * @start:    Starting page index within the file.
+ * @nr_pages: Number of pages to revoke.
+ * @pfn:      The physical address / frame number being revoked. Directly
+ *            reclaims this physical range without querying the provider's
+ *            .lookup_pfn_range().
+ *
+ * guest_memfd will do everything to make sure the range revoked is no longer in
+ * use across guest and host mappings, as well as reclaim any confidential
+ * architecture state.
+ *
+ * Before calling kvm_gmem_revoke(), the caller must ensure that future
+ * .get_pfn() calls for the revoked range will fail so new mappings cannot be
+ * faulted back in after kvm_gmem_revoke() releases the inode's invalidate_lock.
+ * Must be called before accessing, freeing, resetting, or powering down the
+ * backing resource, and the caller must keep the @start-to-PFN mapping valid
+ * and accessible until kvm_gmem_revoke() returns. .put_pfn_range() will not be
+ * called.
+ *
+ * Acquires @inode->i_mapping->invalidate_lock exclusively; callers must not
+ * hold any lock that is also acquired inside provider callbacks.
+ *
+ * Return: 0 on success, or a negative error code on failure.
+ */
+int kvm_gmem_revoke(struct inode *inode, pgoff_t start, size_t nr_pages,
+		    const unsigned long *pfn)
+{
+	return __kvm_gmem_revoke(inode, start, nr_pages, pfn, false);
+}
+EXPORT_SYMBOL_GPL(kvm_gmem_revoke);
+
 static long kvm_gmem_allocate(struct inode *inode, loff_t offset, loff_t len)
 {
 	struct address_space *mapping = inode->i_mapping;

-- 
2.56.0.455.g6c5a503b38-goog

