From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:02 -0800
Subject: [PATCH RFC v3 28/88] KVM: guest_memfd: Support reporting PFN
 attributes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-28-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=11580;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=wkmBy9lgUQWs8gneS+Jj/435+mtTQvBdcBYi1FNd9Co=;
 b=znxXsRqyxlLEyPJffrgjkhe6g3qMhwtVuYQ/aUhloAjmsUQJOdOK38+pbafKwTS56VSEV39b6
 oh0h1H3CWpzAaTNyQBLSOtJHT48k8mGmc6Zy8l9JrLi33jgjzGKz+5Y
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Fred Griffoul <fgriffo@amazon.co.uk>

Support reporting physical frame attributes when retrieving PFNs from
guest_memfd backends.

Add a pfn_attrs output parameter to kvm_gmem_get_pfn and
__kvm_gmem_get_pfn. Define GUEST_MEMFD_PFN_ATTRS_READONLY as the initial
attribute bit so backends can report read-only restrictions on physical
memory ranges.

Handle GUEST_MEMFD_PFN_ATTRS_READONLY across stage 2 fault handlers in
x86 and arm64 to ensure that guest page table mappings prevent writes
when the backing physical memory is marked read-only. Exit to userspace
with a memory fault if the guest attempts to write to a read-only
frame.

Ensure that private memory invariants are preserved: reject read-only
frames for private memory faults with -EFAULT, and reject populating
read-only frames with -EPERM.

Co-developed-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Fred Griffoul <fgriffo@amazon.co.uk>
---
 arch/arm64/kvm/mmu.c        | 13 +++++++++----
 arch/arm64/kvm/nested.c     | 14 ++++++++++++--
 arch/x86/kvm/mmu/mmu.c      | 10 ++++++++--
 arch/x86/kvm/svm/sev.c      | 15 +++++++++++++--
 include/linux/guest_memfd.h |  2 ++
 include/linux/kvm_host.h    |  7 +++++--
 virt/kvm/guest_memfd.c      | 32 ++++++++++++++++++++++++++++----
 7 files changed, 77 insertions(+), 16 deletions(-)

diff --git a/arch/arm64/kvm/mmu.c b/arch/arm64/kvm/mmu.c
index 705f6d84770e9..8f0217185973c 100644
--- a/arch/arm64/kvm/mmu.c
+++ b/arch/arm64/kvm/mmu.c
@@ -1738,6 +1738,7 @@ static int gmem_abort(const struct kvm_s2_fault_desc *s2fd,
 {
 	bool write_fault, exec_fault;
 	bool perm_fault = kvm_s2_fault_is_perm(s2fd);
+	bool writable;
 	enum kvm_pgtable_walk_flags flags = KVM_PGTABLE_WALK_SHARED;
 	enum kvm_pgtable_prot prot = KVM_PGTABLE_PROT_R;
 	struct kvm_pgtable *pgt = s2fd->mmu->pgt;
@@ -1746,6 +1747,7 @@ static int gmem_abort(const struct kvm_s2_fault_desc *s2fd,
 	struct kvm *kvm = s2fd->vcpu->kvm;
 	void *memcache = NULL;
 	gfn_t canonical_gfn;
+	u64 pfn_attrs = 0;
 	int ret;
 
 	if (!perm_fault) {
@@ -1773,18 +1775,21 @@ static int gmem_abort(const struct kvm_s2_fault_desc *s2fd,
 	/* Pairs with the smp_wmb() in kvm_mmu_invalidate_end(). */
 	smp_rmb();
 
-	ret = kvm_gmem_get_pfn(kvm, s2fd->memslot, canonical_gfn, &s2vi.pfn, NULL);
-	if (ret) {
+	ret = kvm_gmem_get_pfn(kvm, s2fd->memslot, canonical_gfn, &s2vi.pfn, NULL,
+			       &pfn_attrs);
+	writable = !(s2fd->memslot->flags & KVM_MEM_READONLY) &&
+		   !(pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY);
+	if (ret || (write_fault && !writable)) {
 		/* If result is non-NULL this is a synthetic fault. */
 		if (!result)
 			kvm_prepare_memory_fault_exit(s2fd->vcpu, gfn_to_gpa(canonical_gfn),
 						      s2vi.vma_pagesize, write_fault, exec_fault,
 						      false);
 		kfree(mapping);
-		return ret;
+		return ret ?: -EFAULT;
 	}
 
-	if (!(s2fd->memslot->flags & KVM_MEM_READONLY))
+	if (writable)
 		prot |= KVM_PGTABLE_PROT_W;
 
 	if (s2fd->nested)
diff --git a/arch/arm64/kvm/nested.c b/arch/arm64/kvm/nested.c
index 4d83281a7a28b..4519e92d89d66 100644
--- a/arch/arm64/kvm/nested.c
+++ b/arch/arm64/kvm/nested.c
@@ -1615,14 +1615,24 @@ static int kvm_translate_vncr(struct kvm_vcpu *vcpu, bool *is_gmem)
 			return -EFAULT;
 		}
 	} else {
-		ret = kvm_gmem_get_pfn(vcpu->kvm, memslot, gfn, &pfn, NULL);
+		u64 pfn_attrs;
+
+		ret = kvm_gmem_get_pfn(vcpu->kvm, memslot, gfn, &pfn, NULL,
+				       &pfn_attrs);
 		if (ret) {
 			kvm_prepare_memory_fault_exit(vcpu, vt->wr.pa, PAGE_SIZE,
 					      write_fault, false, false);
 			return ret;
 		}
 
-		writable = !(memslot->flags & KVM_MEM_READONLY);
+		writable = !(memslot->flags & KVM_MEM_READONLY) &&
+			   !(pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY);
+		/* TODO: Explain why vt->wr.pw needs to be checked. */
+		if (write_fault && vt->wr.pw && !writable) {
+			kvm_prepare_memory_fault_exit(vcpu, vt->wr.pa, PAGE_SIZE,
+						      true, false, false);
+			return -EFAULT;
+		}
 	}
 
 	/*
diff --git a/arch/x86/kvm/mmu/mmu.c b/arch/x86/kvm/mmu/mmu.c
index 5a2cc6a17a9b3..87deeeffd9919 100644
--- a/arch/x86/kvm/mmu/mmu.c
+++ b/arch/x86/kvm/mmu/mmu.c
@@ -4674,6 +4674,7 @@ static void kvm_mmu_finish_page_fault(struct kvm_vcpu *vcpu,
 static int kvm_mmu_faultin_pfn_gmem(struct kvm_vcpu *vcpu,
 				    struct kvm_page_fault *fault)
 {
+	u64 pfn_attrs;
 	int max_order, r;
 
 	if (!kvm_slot_has_gmem(fault->slot)) {
@@ -4682,13 +4683,18 @@ static int kvm_mmu_faultin_pfn_gmem(struct kvm_vcpu *vcpu,
 	}
 
 	r = kvm_gmem_get_pfn(vcpu->kvm, fault->slot, fault->gfn, &fault->pfn,
-			     &max_order);
+			     &max_order, &pfn_attrs);
 	if (r) {
 		kvm_mmu_prepare_memory_fault_exit(vcpu, fault);
 		return r;
 	}
 
-	fault->map_writable = !(fault->slot->flags & KVM_MEM_READONLY);
+	fault->map_writable = !(fault->slot->flags & KVM_MEM_READONLY) &&
+			      !(pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY);
+	if (fault->write && !fault->map_writable) {
+		kvm_mmu_prepare_memory_fault_exit(vcpu, fault);
+		return -EFAULT;
+	}
 	fault->max_level = kvm_max_level_for_order(max_order);
 
 	return RET_PF_CONTINUE;
diff --git a/arch/x86/kvm/svm/sev.c b/arch/x86/kvm/svm/sev.c
index 6427db390b1cd..5e37ea4bc7937 100644
--- a/arch/x86/kvm/svm/sev.c
+++ b/arch/x86/kvm/svm/sev.c
@@ -4053,6 +4053,7 @@ static void __sev_snp_reload_vmsa(struct kvm_vcpu *vcpu, gpa_t gpa)
 	struct kvm *kvm = vcpu->kvm;
 	gfn_t gfn = gpa_to_gfn(gpa);
 	unsigned long mmu_seq;
+	u64 pfn_attrs;
 	kvm_pfn_t pfn;
 
 	lockdep_assert_held(&svm->sev_es.snp_vmsa_mutex);
@@ -4096,7 +4097,10 @@ static void __sev_snp_reload_vmsa(struct kvm_vcpu *vcpu, gpa_t gpa)
 	 * The new VMSA will be private memory guest memory, so retrieve the
 	 * PFN from the gmem backend.
 	 */
-	if (kvm_gmem_get_pfn(vcpu->kvm, slot, gfn, &pfn, NULL))
+	if (kvm_gmem_get_pfn(vcpu->kvm, slot, gfn, &pfn, NULL, &pfn_attrs))
+		return;
+
+	if (pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY)
 		return;
 
 	read_lock(&kvm->mmu_lock);
@@ -5063,6 +5067,7 @@ void sev_handle_rmp_fault(struct kvm_vcpu *vcpu, gpa_t gpa, u64 error_code)
 	struct kvm *kvm = vcpu->kvm;
 	int order, rmp_level, ret;
 	unsigned long mmu_seq;
+	u64 pfn_attrs;
 	bool assigned;
 	kvm_pfn_t pfn;
 	gfn_t gfn;
@@ -5092,13 +5097,19 @@ void sev_handle_rmp_fault(struct kvm_vcpu *vcpu, gpa_t gpa, u64 error_code)
 	mmu_seq = kvm->mmu_invalidate_seq;
 	smp_rmb();
 
-	ret = kvm_gmem_get_pfn(kvm, slot, gfn, &pfn, &order);
+	ret = kvm_gmem_get_pfn(kvm, slot, gfn, &pfn, &order, &pfn_attrs);
 	if (ret) {
 		pr_warn_ratelimited("SEV: Unexpected RMP fault, no backing page for private GPA 0x%llx\n",
 				    gpa);
 		return;
 	}
 
+	if (pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY) {
+		pr_warn_ratelimited("SEV: Unexpected RMP fault, read-only backing page for GPA 0x%llx\n",
+				    gpa);
+		return;
+	}
+
 	ret = snp_lookup_rmpentry(pfn, &assigned, &rmp_level);
 	if (ret || !assigned) {
 		guard(read_lock)(&kvm->mmu_lock);
diff --git a/include/linux/guest_memfd.h b/include/linux/guest_memfd.h
index f3e6077c39ac3..df2db2a0bae6e 100644
--- a/include/linux/guest_memfd.h
+++ b/include/linux/guest_memfd.h
@@ -9,6 +9,8 @@ struct folio;
 struct inode;
 struct mempolicy;
 
+#define GUEST_MEMFD_PFN_ATTRS_READONLY	(1ULL << 0)
+
 /**
  * struct guest_memfd_provider_operations - Operations for external memory providers
  * @attach: Attach to a resource file, perform filesystem-specific validation,
diff --git a/include/linux/kvm_host.h b/include/linux/kvm_host.h
index d820afac49252..cf679efcf3260 100644
--- a/include/linux/kvm_host.h
+++ b/include/linux/kvm_host.h
@@ -35,6 +35,7 @@
 #include <linux/interval_tree.h>
 #include <linux/rbtree.h>
 #include <linux/xarray.h>
+#include <linux/guest_memfd.h>
 #include <asm/signal.h>
 
 #include <linux/kvm.h>
@@ -2627,11 +2628,13 @@ static inline u64 kvm_gmem_get_supported_flags(struct kvm *kvm)
 }
 
 int kvm_gmem_get_pfn(struct kvm *kvm, struct kvm_memory_slot *slot,
-		     gfn_t gfn, kvm_pfn_t *pfn, int *max_order);
+		     gfn_t gfn, kvm_pfn_t *pfn, int *max_order,
+		     u64 *pfn_attrs);
 #else
 static inline int kvm_gmem_get_pfn(struct kvm *kvm,
 				   struct kvm_memory_slot *slot, gfn_t gfn,
-				   kvm_pfn_t *pfn, int *max_order)
+				   kvm_pfn_t *pfn, int *max_order,
+				   u64 *pfn_attrs)
 {
 	KVM_BUG_ON(1, kvm);
 	return -EIO;
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 84877beed6701..f0bd90fd9c986 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -1274,7 +1274,7 @@ void kvm_gmem_unbind(struct kvm_memory_slot *slot)
 static struct folio *__kvm_gmem_get_pfn(struct file *file,
 					struct kvm_memory_slot *slot,
 					pgoff_t index, kvm_pfn_t *pfn,
-					int *max_order)
+					int *max_order, u64 *pfn_attrs)
 {
 	struct file *slot_file = READ_ONCE(slot->gmem.file);
 	struct gmem_file *f = file->private_data;
@@ -1308,18 +1308,23 @@ static struct folio *__kvm_gmem_get_pfn(struct file *file,
 	*pfn = folio_file_pfn(folio, index);
 	if (max_order)
 		*max_order = 0;
+	if (pfn_attrs)
+		*pfn_attrs = 0;
 
 	return folio;
 }
 
 int kvm_gmem_get_pfn(struct kvm *kvm, struct kvm_memory_slot *slot,
-		     gfn_t gfn, kvm_pfn_t *pfn, int *max_order)
+		     gfn_t gfn, kvm_pfn_t *pfn, int *max_order,
+		     u64 *pfn_attrs)
 {
 	pgoff_t index = kvm_gmem_get_index(slot, gfn);
 	struct folio *folio;
 	int r = 0, __order;
+	u64 __attrs;
 
 	max_order = max_order ?: &__order;
+	pfn_attrs = pfn_attrs ?: &__attrs;
 
 	CLASS(gmem_get_file, file)(slot);
 	if (!file)
@@ -1327,17 +1332,29 @@ int kvm_gmem_get_pfn(struct kvm *kvm, struct kvm_memory_slot *slot,
 
 	filemap_invalidate_lock_shared(file_inode(file)->i_mapping);
 
-	folio = __kvm_gmem_get_pfn(file, slot, index, pfn, max_order);
+	folio = __kvm_gmem_get_pfn(file, slot, index, pfn, max_order,
+				   pfn_attrs);
 	if (IS_ERR(folio)) {
 		r = PTR_ERR(folio);
 		goto out;
 	}
 
+	/*
+	 * Private memory requires exclusive, writable guest ownership and
+	 * cannot be backed by a read-only frame.
+	 */
+	if (kvm_gmem_is_private_mem(file_inode(file), index) &&
+	    (*pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY)) {
+		r = -EFAULT;
+		goto out_put_folio;
+	}
+
 	if (kvm_arch_has_gmem_convert() &&
 	    kvm_gmem_is_private_mem(file_inode(file), index))
 		r = kvm_arch_gmem_make_private(kvm, gfn, *pfn,
 					       (kvm_pfn_t)1 << *max_order);
 
+out_put_folio:
 	folio_unlock(folio);
 	folio_put(folio);
 
@@ -1355,12 +1372,13 @@ static long __kvm_gmem_populate(struct kvm *kvm, struct kvm_memory_slot *slot,
 {
 	pgoff_t index = kvm_gmem_get_index(slot, gfn);
 	struct folio *folio;
+	u64 pfn_attrs;
 	kvm_pfn_t pfn;
 	int ret;
 
 	filemap_invalidate_lock(file->f_mapping);
 
-	folio = __kvm_gmem_get_pfn(file, slot, index, &pfn, NULL);
+	folio = __kvm_gmem_get_pfn(file, slot, index, &pfn, NULL, &pfn_attrs);
 	if (IS_ERR(folio)) {
 		ret = PTR_ERR(folio);
 		goto out_unlock;
@@ -1368,6 +1386,12 @@ static long __kvm_gmem_populate(struct kvm *kvm, struct kvm_memory_slot *slot,
 
 	folio_unlock(folio);
 
+	/* Populating pages initializes private memory, which cannot be read-only. */
+	if (pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY) {
+		ret = -EPERM;
+		goto out_put_folio;
+	}
+
 	if (!kvm_is_private_gfn(kvm, gfn)) {
 		ret = -EINVAL;
 		goto out_put_folio;

-- 
2.56.0.455.g6c5a503b38-goog

