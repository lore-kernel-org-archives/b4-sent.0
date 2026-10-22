From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:28:15 -0700
Subject: [PATCH RFC v2 43/50] KVM: guest_memfd: Export kvm_gmem_revoke for
 provider-driven revocation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-43-5dd1dc6c660a@google.com>
References: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
In-Reply-To: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
To: Alex Williamson <alex@shazbot.org>, Alexander Graf <graf@amazon.de>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, 
 Alexey Kardashevskiy <aik@amd.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 Ashish Kalra <ashish.kalra@amd.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Baolu Lu <baolu.lu@linux.intel.com>, Bill Wendling <morbo@google.com>, 
 Borislav Petkov <bp@alien8.de>, Catalin Marinas <catalin.marinas@arm.com>, 
 Christian Brauner <brauner@kernel.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Connor Williamson <connordw@amazon.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, David Hildenbrand <david@kernel.org>, 
 David Rientjes <rientjes@google.com>, David Woodhouse <dwmw2@infradead.org>, 
 Erdem Aktas <erdemaktas@google.com>, Frank van der Linden <fvdl@google.com>, 
 Fred Griffoul <fgriffo@amazon.co.uk>, Fred Griffoul <griffoul@gmail.com>, 
 Gregory Price <gourry@gourry.net>, "H. Peter Anvin" <hpa@zytor.com>, 
 Hugh Dickins <hughd@google.com>, Ingo Molnar <mingo@redhat.com>, 
 Jacob Pan <jacob.pan@linux.microsoft.com>, 
 James Houghton <jthoughton@google.com>, Jan Kara <jack@suse.cz>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Jianxiong Gao <jxgao@google.com>, 
 Joerg Roedel <joro@8bytes.org>, Joey Gouly <joey.gouly@arm.com>, 
 John Starks <John.Starks@microsoft.com>, Jonathan Corbet <corbet@lwn.net>, 
 Justin Stitt <justinstitt@google.com>, Kevin Tian <kevin.tian@intel.com>, 
 Lorenzo Stoakes <ljs@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 Michael Roth <michael.roth@amd.com>, Mike Rapoport <rppt@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Nicolin Chen <nicolinc@nvidia.com>, Oliver Upton <oupton@kernel.org>, 
 Paolo Bonzini <pbonzini@redhat.com>, Pratyush Yadav <pratyush@kernel.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Robin Murphy <robin.murphy@arm.com>, 
 Samiullah Khawaja <skhawaja@google.com>, 
 Sean Christopherson <seanjc@google.com>, Shuah Khan <shuah@kernel.org>, 
 Steffen Eiden <seiden@linux.ibm.com>, Steven Price <steven.price@arm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Tarun Sahu <tarunsahu@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Tom Lendacky <thomas.lendacky@amd.com>, Tycho Andersen <tycho@kernel.org>, 
 Vishal Annapurve <vannapurve@google.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Will Deacon <will@kernel.org>, 
 Xu Yilun <yilun.xu@linux.intel.com>, Yan Zhao <yan.y.zhao@intel.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, x86@kernel.org, 
 Shuah Khan <skhan@linuxfoundation.org>, Fuad Tabba <fuad.tabba@linux.dev>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, llvm@lists.linux.dev, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=6495;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=hV27o4dOKADJOBUsB7Zz8/cT/cHzwJnpPOhSKk352LI=;
 b=4E+0DU5MfmUTG1hQwn7ACZlFI+aTYH7wks1B6nXtVQ3pWafKFTMBo9Mjy6qKdycEe7OVKp8HY
 LiHgjjinaImDtSQUqTE85dXAF4QL/Tb+eK+zVjZ97MxpL/inN+lsKCX
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
 arch/x86/kvm/Makefile       |  3 ++-
 include/linux/guest_memfd.h | 14 +++++++++-
 virt/kvm/guest_memfd.c      | 63 ++++++++++++++++++++++++++++++++++++++-------
 3 files changed, 69 insertions(+), 11 deletions(-)

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
index 3c0cc35f748bc..3e2c0714ca33e 100644
--- a/include/linux/guest_memfd.h
+++ b/include/linux/guest_memfd.h
@@ -36,7 +36,8 @@ struct mempolicy;
  * @put_pfn_range: Release a range of PFNs previously obtained for a given
  *                 index.  The provider does not need to ensure that backing
  *                 memory is present. If backing memory is not available, the
- *                 provider should skip the unbacked range.
+ *                 provider should skip the unbacked range. Not called on
+ *                 kvm_gmem_revoke().
  *
  * Used by filesystems and device drivers that provide memory for guest_memfd.
  */
@@ -53,4 +54,15 @@ struct guest_memfd_provider_operations {
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
index a4519f3b9eadb..3c4bedceccfc2 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -421,18 +421,25 @@ static void kvm_gmem_pfn_reclaim(struct gmem_inode *gi, pgoff_t start, pgoff_t e
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
@@ -444,8 +451,14 @@ static long kvm_gmem_punch_hole(struct inode *inode, loff_t offset, loff_t len)
 
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
@@ -457,6 +470,38 @@ static long kvm_gmem_punch_hole(struct inode *inode, loff_t offset, loff_t len)
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
+ * Must be called before accessing memory contents. Keeping the mapping from
+ * @start to @pfn constant is the responsibility of the caller.
+ * .put_pfn_range() will not be called.
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
2.56.0.257.gf7497c7d27-goog

