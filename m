From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:06 -0800
Subject: [PATCH RFC v3 32/88] KVM: guest_memfd: Support user fault handling
 in PFN mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-32-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=4803;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=BHfl6wvLdeD6eD5eILiiO6y1oWReh7OD+qFN9r31eZY=;
 b=PheuT7ywy0hAO/mjTx3YVz658XWJPOjzwi+5Hkdw/rJUyuN13z+94s/e15qbngjBlOTdHHYJA
 gCPlAhTinKMAkcCG8fDXSpq+8UE96qNxdU+ZortX7X5Tdcsqh23gX1A
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In PFN mode, guest_memfd memory is backed by raw PFNs rather than
page-cache folios.

When inserting the PFN into the user page tables during fault handling,
constrain the inserted protection by stripping write permissions if the
provider reports a read-only PFN attribute, and fail immediate write faults
on read-only frames with VM_FAULT_SIGBUS.

Introduce kvm_gmem_pfn_vm_ops with a .pfn_mkwrite callback that returns
VM_FAULT_SIGBUS to block subsequent write attempts or upgrades to read-only
PFN mappings. Without this, core MM would have marked the PTE writable and
the write would have succeeded.

There is no need to do another .get_pfn() call since the contract with the
provider requires the attributes to be kept constant until memory is
revoked, at which time the user page tables would have been zapped.

In folio mode, the fault handler obtains a locked folio under the shared
filemap invalidation lock and returns with the folio still locked so the
core fault handler installs the PTE before unlocking the folio. Any
concurrent truncation or invalidation must wait on the folio lock before
unmapping and removing the folio.

In PFN mode, there is no folio lock to bridge the gap after dropping the
shared filemap invalidation lock. Hold the shared filemap invalidation lock
across PFN insertion to prevent races with revocation.

Co-developed-by: Fred Griffoul <fgriffo@amazon.co.uk>
Signed-off-by: Fred Griffoul <fgriffo@amazon.co.uk>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 virt/kvm/guest_memfd.c | 52 +++++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 51 insertions(+), 1 deletion(-)

diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 183e15775523f..e94f2359b7c9a 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -565,11 +565,40 @@ static bool kvm_gmem_supports_mmap(struct inode *inode)
 	return GMEM_I(inode)->flags & GUEST_MEMFD_FLAG_MMAP;
 }
 
+/*
+ * In PFN mode, physical frame attributes are constant for the lifetime of the
+ * mapping. If a page was inserted read-only, it was because the provider
+ * reported a read-only PFN attribute, and write upgrades are never permitted.
+ * Write faults on such pages must fail with SIGBUS.
+ */
+static vm_fault_t kvm_gmem_pfn_mkwrite(struct vm_fault *vmf)
+{
+	return VM_FAULT_SIGBUS;
+}
+
+static vm_fault_t gmem_insert_pfn(struct vm_fault *vmf, kvm_pfn_t pfn,
+				 u64 pfn_attrs)
+{
+	struct vm_area_struct *vma = vmf->vma;
+	vm_flags_t flags = vma->vm_flags;
+
+	if (pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY)
+		flags &= ~VM_WRITE;
+
+	if ((vmf->flags & FAULT_FLAG_WRITE) && !(flags & VM_WRITE))
+		return VM_FAULT_SIGBUS;
+
+	return vmf_insert_pfn_prot(vma, vmf->address, pfn,
+				   vm_get_page_prot(flags));
+}
+
 static vm_fault_t kvm_gmem_fault_user_mapping(struct vm_fault *vmf)
 {
 	struct inode *inode = file_inode(vmf->vma->vm_file);
+	struct gmem_inode *gi = GMEM_I(inode);
 	vm_fault_t ret = VM_FAULT_LOCKED;
 	struct folio *folio = NULL;
+	kvm_pfn_t pfn;
 	int r = 0;
 
 	if (((loff_t)vmf->pgoff << PAGE_SHIFT) >= i_size_read(inode))
@@ -578,6 +607,12 @@ static vm_fault_t kvm_gmem_fault_user_mapping(struct vm_fault *vmf)
 	filemap_invalidate_lock_shared(inode->i_mapping);
 	if (!kvm_gmem_is_shared_mem(inode, vmf->pgoff)) {
 		r = -EACCES;
+	} else if (kvm_gmem_is_pfn_mode(gi)) {
+		u64 pfn_attrs;
+
+		r = gmem_provider_get_pfn(gi, vmf->pgoff, &pfn, NULL, &pfn_attrs);
+		if (!r)
+			ret = gmem_insert_pfn(vmf, pfn, pfn_attrs);
 	} else {
 		folio = kvm_gmem_get_folio(inode, vmf->pgoff);
 		if (IS_ERR(folio))
@@ -592,6 +627,9 @@ static vm_fault_t kvm_gmem_fault_user_mapping(struct vm_fault *vmf)
 		return vmf_error(r);
 	}
 
+	if (kvm_gmem_is_pfn_mode(gi))
+		return ret;
+
 	if (WARN_ON_ONCE(folio_test_large(folio))) {
 		ret = VM_FAULT_SIGBUS;
 		goto out_folio;
@@ -650,6 +688,15 @@ static const struct vm_operations_struct kvm_gmem_vm_ops = {
 #endif
 };
 
+static const struct vm_operations_struct kvm_gmem_pfn_vm_ops = {
+	.fault		= kvm_gmem_fault_user_mapping,
+	.pfn_mkwrite	= kvm_gmem_pfn_mkwrite,
+#ifdef CONFIG_NUMA
+	.get_policy	= kvm_gmem_get_policy,
+	.set_policy	= kvm_gmem_set_policy,
+#endif
+};
+
 static int kvm_gmem_mmap(struct file *file, struct vm_area_struct *vma)
 {
 	struct gmem_inode *gi = GMEM_I(file_inode(file));
@@ -665,7 +712,10 @@ static int kvm_gmem_mmap(struct file *file, struct vm_area_struct *vma)
 	if (kvm_gmem_is_pfn_mode(gi))
 		vm_flags_set(vma, VM_PFNMAP);
 
-	vma->vm_ops = &kvm_gmem_vm_ops;
+	if (kvm_gmem_is_pfn_mode(gi))
+		vma->vm_ops = &kvm_gmem_pfn_vm_ops;
+	else
+		vma->vm_ops = &kvm_gmem_vm_ops;
 
 	return 0;
 }

-- 
2.56.0.455.g6c5a503b38-goog

