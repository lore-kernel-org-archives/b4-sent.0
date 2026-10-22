From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:28:03 -0700
Subject: [PATCH RFC v2 31/50] KVM: guest_memfd: Support getting PFNs for
 stage 2 from providers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-31-5dd1dc6c660a@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=6020;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=jEkr/nY1nFVQLtsltdN4AJnwp36Iu4m7TarLTGyPZVc=;
 b=vAkluFarmlZI1TwtSGhLOd+jHlS0DLSrWj3cCriODu55Bs8Tz1V4Ot2NifETUEWZCMUMWV2GD
 CtaY4a2NaZCCpOvCQwRHzJ6wEKfOMC4mO8bqs82RiiNQXQnqSLT2A0P
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add .get_pfn callback to struct guest_memfd_provider_operations to
support physical memory providers (e.g. devices, DAX, or pre-allocated
ranges) that supply PFNs directly without folio allocation or page cache
insertion.

Define GUEST_MEMFD_FLAG_PFN_MODE in uapi/linux/kvm.h and define
kvm_gmem_is_pfn_mode() to check for this flag in gi->flags.

In __kvm_gmem_get_pfn(), query .get_pfn() directly when in PFN mode
and return NULL on success (instead of a struct folio *).

Note that .alloc_folio is still required by kvm_gmem_attach_resource() and
GUEST_MEMFD_FLAG_PFN_MODE is not yet enabled for userspace.  Subsequent
patches will update the rest of guest_memfd (e.g. mmap, fallocate,
truncation, and attributes) to support PFN mode before enabling the flag
and allowing external PFN-backed providers to be attached.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/linux/guest_memfd.h |  8 ++++++++
 include/uapi/linux/kvm.h    |  1 +
 virt/kvm/guest_memfd.c      | 42 +++++++++++++++++++++++++++++++++++++-----
 3 files changed, 46 insertions(+), 5 deletions(-)

diff --git a/include/linux/guest_memfd.h b/include/linux/guest_memfd.h
index f3e6077c39ac3..10c48f41a6d7e 100644
--- a/include/linux/guest_memfd.h
+++ b/include/linux/guest_memfd.h
@@ -18,6 +18,12 @@ struct mempolicy;
  *               Must return a pointer to a struct folio on success, or an
  *               ERR_PTR() error code on failure. Must never return NULL.
  * @invalidate_folio: Notify provider that a folio has been invalidated.
+ * @get_pfn: Obtain a PFN for a given index. The provider must ensure backing
+ *           memory is present and is responsible for its contents, such as
+ *           zeroing if necessary. On success, return 0 with the physical frame
+ *           number in @pfn and, if @max_order is non-NULL, the maximum page
+ *           order of contiguous backing memory containing @pfn. Returns a
+ *           negative error code on failure.
  *
  * Used by filesystems and device drivers that provide memory for guest_memfd.
  */
@@ -27,6 +33,8 @@ struct guest_memfd_provider_operations {
 	struct folio *(*alloc_folio)(void *provider, pgoff_t index,
 				     struct mempolicy *mpol);
 	void (*invalidate_folio)(void *provider, struct folio *folio);
+	int (*get_pfn)(void *provider, pgoff_t index, unsigned long *pfn,
+		       int *max_order);
 };
 
 #endif /* _LINUX_GUEST_MEMFD_H */
diff --git a/include/uapi/linux/kvm.h b/include/uapi/linux/kvm.h
index f4108bf7e3192..6798056f50e32 100644
--- a/include/uapi/linux/kvm.h
+++ b/include/uapi/linux/kvm.h
@@ -1675,6 +1675,7 @@ struct kvm_memory_attributes2 {
 #define GUEST_MEMFD_FLAG_MMAP		(1ULL << 0)
 #define GUEST_MEMFD_FLAG_INIT_SHARED	(1ULL << 1)
 #define GUEST_MEMFD_FLAG_USE_RESOURCE	(1ULL << 2)
+#define GUEST_MEMFD_FLAG_PFN_MODE	(1ULL << 3)
 
 struct kvm_create_guest_memfd {
 	__u64 size;
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 84877beed6701..3d89bc76f3867 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -54,6 +54,11 @@ static __always_inline struct gmem_inode *GMEM_I(struct inode *inode)
 	return container_of(inode, struct gmem_inode, vfs_inode);
 }
 
+static bool kvm_gmem_is_pfn_mode(struct gmem_inode *gi)
+{
+	return gi->flags & GUEST_MEMFD_FLAG_PFN_MODE;
+}
+
 static void *gmem_native_attach(struct inode *gmem_inode,
 				struct file *resource_file)
 {
@@ -124,6 +129,20 @@ static struct folio *gmem_provider_alloc_folio(struct gmem_inode *gi,
 	return ERR_PTR(-EOPNOTSUPP);
 }
 
+static int gmem_provider_get_pfn(struct gmem_inode *gi, pgoff_t index,
+				 kvm_pfn_t *pfn, int *max_order)
+{
+	unsigned long raw_pfn;
+	int r;
+
+	r = gi->provider_ops->get_pfn(gi->provider, index, &raw_pfn, max_order);
+	if (r)
+		return r;
+
+	*pfn = raw_pfn;
+	return 0;
+}
+
 static void gmem_provider_invalidate_folio(struct gmem_inode *gi,
 					   struct folio *folio)
 {
@@ -1270,15 +1289,17 @@ void kvm_gmem_unbind(struct kvm_memory_slot *slot)
 	filemap_invalidate_unlock(file->f_mapping);
 }
 
-/* Returns a locked folio on success.  */
+/* On success, return a locked folio in folio mode and NULL in PFN mode. */
 static struct folio *__kvm_gmem_get_pfn(struct file *file,
 					struct kvm_memory_slot *slot,
 					pgoff_t index, kvm_pfn_t *pfn,
 					int *max_order)
 {
 	struct file *slot_file = READ_ONCE(slot->gmem.file);
+	struct gmem_inode *gi = GMEM_I(file_inode(file));
 	struct gmem_file *f = file->private_data;
 	struct folio *folio;
+	int r;
 
 	if (file != slot_file) {
 		WARN_ON_ONCE(slot_file);
@@ -1290,6 +1311,13 @@ static struct folio *__kvm_gmem_get_pfn(struct file *file,
 		return ERR_PTR(-EIO);
 	}
 
+	if (kvm_gmem_is_pfn_mode(gi)) {
+		r = gmem_provider_get_pfn(gi, index, pfn, max_order);
+		if (r)
+			return ERR_PTR(r);
+		return NULL;
+	}
+
 	folio = kvm_gmem_get_folio(file_inode(file), index);
 	if (IS_ERR(folio))
 		return folio;
@@ -1338,8 +1366,10 @@ int kvm_gmem_get_pfn(struct kvm *kvm, struct kvm_memory_slot *slot,
 		r = kvm_arch_gmem_make_private(kvm, gfn, *pfn,
 					       (kvm_pfn_t)1 << *max_order);
 
-	folio_unlock(folio);
-	folio_put(folio);
+	if (folio) {
+		folio_unlock(folio);
+		folio_put(folio);
+	}
 
 out:
 	filemap_invalidate_unlock_shared(file_inode(file)->i_mapping);
@@ -1366,7 +1396,8 @@ static long __kvm_gmem_populate(struct kvm *kvm, struct kvm_memory_slot *slot,
 		goto out_unlock;
 	}
 
-	folio_unlock(folio);
+	if (folio)
+		folio_unlock(folio);
 
 	if (!kvm_is_private_gfn(kvm, gfn)) {
 		ret = -EINVAL;
@@ -1376,7 +1407,8 @@ static long __kvm_gmem_populate(struct kvm *kvm, struct kvm_memory_slot *slot,
 	ret = post_populate(kvm, gfn, pfn, src_page, opaque);
 
 out_put_folio:
-	folio_put(folio);
+	if (folio)
+		folio_put(folio);
 out_unlock:
 	filemap_invalidate_unlock(file->f_mapping);
 	return ret;

-- 
2.56.0.257.gf7497c7d27-goog

