From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:25 -0800
Subject: [PATCH RFC v3 51/88] KVM: guest_memfd: Support reporting PFN
 cacheability
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-51-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=9171;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=GZTQxVn0HjxORiNdxoBtqdA/HiYkhk8lDD2n3VKRLow=;
 b=y38OKIzJH7eiYyPKqj5uQCGyOxtwZlKxg8Qd3cuZA8cWdUQ0l3YXTkA3HzQD+e1zqhN4SOCvP
 0UXrPpAV/oeBBpAYUMPjuenU/9KmhLKmarn9kYJPf1fXNZN0arx3gYl
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When memory slots are backed exclusively by guest_memfd without a host
userspace VMA, KVM cannot inspect VMA flags or page protections to
determine the caching requirements of the backing physical frames. Even
when a VMA exists, external PFN providers such as device drivers may
expose multiple regions with distinct caching properties within a single
provider instance.

Extend PFN attributes with a cacheability field whose zero value
represents normal write-back cacheable memory so existing RAM providers
require no changes. Distinguish three non-cacheable modes alongside
normal cacheable memory: strict uncached MMIO where guest
write-combining could trigger uncontained host faults, uncached MMIO on
buses such as PCIe where stage-2 can safely permit guest write-combining
while host mappings remain uncached, and write-combining memory.

Handle the reported cacheability in stage-2 fault paths:

- On arm64, select Device or Normal Non-Cacheable stage-2 attributes for
  non-cacheable frames, forbid instruction fetches on non-cacheable
  mappings, verify hardware cacheability support for non-linear-mapped
  cacheable frames, and reject non-cacheable frames for nested VNCR
  mappings which require cacheable host kernel mappings.
- On x86, stage-2 PTE construction already derives MMIO status from host
  PAT and E820 tables (and couples that status with host memory
  encryption bits), so warn once with a TODO if the provider-reported
  cacheability disagrees with x86's host MMIO detection.

Preserve confidential RAM invariants by rejecting non-cacheable frames
during initial payload population, and during SEV-SNP VMSA reloading or
RMP fault handling.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 arch/arm64/kvm/mmu.c        | 30 ++++++++++++++++++++++++++++--
 arch/arm64/kvm/nested.c     |  5 +++++
 arch/x86/kvm/mmu/mmu.c      |  8 ++++++++
 arch/x86/kvm/mmu/spte.c     |  2 +-
 arch/x86/kvm/mmu/spte.h     |  1 +
 arch/x86/kvm/svm/sev.c      |  9 ++++++++-
 include/linux/guest_memfd.h | 29 ++++++++++++++++++++++++++++-
 virt/kvm/guest_memfd.c      |  8 ++++++--
 8 files changed, 85 insertions(+), 7 deletions(-)

diff --git a/arch/arm64/kvm/mmu.c b/arch/arm64/kvm/mmu.c
index 8f0217185973c..71fc823ed2076 100644
--- a/arch/arm64/kvm/mmu.c
+++ b/arch/arm64/kvm/mmu.c
@@ -1789,14 +1789,40 @@ static int gmem_abort(const struct kvm_s2_fault_desc *s2fd,
 		return ret ?: -EFAULT;
 	}
 
+	if (!kvm_gmem_pfn_is_cacheable(pfn_attrs) && exec_fault) {
+		kfree(mapping);
+		return -ENOEXEC;
+	}
+
 	if (writable)
 		prot |= KVM_PGTABLE_PROT_W;
 
 	if (s2fd->nested)
 		prot = adjust_nested_fault_perms(s2fd->nested, prot);
 
-	if (exec_fault || cpus_have_final_cap(ARM64_HAS_CACHE_DIC))
-		prot |= KVM_PGTABLE_PROT_X;
+	switch (pfn_attrs & GUEST_MEMFD_PFN_ATTRS_CACHE_MASK) {
+	case GUEST_MEMFD_PFN_ATTRS_CACHE_WB:
+		if (!pfn_is_map_memory(s2vi.pfn) &&
+		    !kvm_supports_cacheable_pfnmap()) {
+			if (!result)
+				kvm_prepare_memory_fault_exit(
+					s2fd->vcpu, gfn_to_gpa(canonical_gfn),
+					s2vi.vma_pagesize, write_fault,
+					exec_fault, false);
+			kfree(mapping);
+			return -EFAULT;
+		}
+		if (exec_fault || cpus_have_final_cap(ARM64_HAS_CACHE_DIC))
+			prot |= KVM_PGTABLE_PROT_X;
+		break;
+	case GUEST_MEMFD_PFN_ATTRS_CACHE_UC:
+		prot |= KVM_PGTABLE_PROT_DEVICE;
+		break;
+	case GUEST_MEMFD_PFN_ATTRS_CACHE_UC_ALLOW_WC:
+	case GUEST_MEMFD_PFN_ATTRS_CACHE_WC:
+		prot |= KVM_PGTABLE_PROT_NORMAL_NC;
+		break;
+	}
 
 	if (s2fd->nested)
 		prot = adjust_nested_exec_perms(kvm, s2fd->nested, prot);
diff --git a/arch/arm64/kvm/nested.c b/arch/arm64/kvm/nested.c
index 4519e92d89d66..a3818ece5c753 100644
--- a/arch/arm64/kvm/nested.c
+++ b/arch/arm64/kvm/nested.c
@@ -1633,6 +1633,11 @@ static int kvm_translate_vncr(struct kvm_vcpu *vcpu, bool *is_gmem)
 						      true, false, false);
 			return -EFAULT;
 		}
+
+		if (!kvm_gmem_pfn_is_cacheable(pfn_attrs)) {
+			fail_s1_walk(&vt->wr, ESR_ELx_FSC_EXTABT, false);
+			return -EINVAL;
+		}
 	}
 
 	/*
diff --git a/arch/x86/kvm/mmu/mmu.c b/arch/x86/kvm/mmu/mmu.c
index 87deeeffd9919..23feb737c755b 100644
--- a/arch/x86/kvm/mmu/mmu.c
+++ b/arch/x86/kvm/mmu/mmu.c
@@ -4695,6 +4695,14 @@ static int kvm_mmu_faultin_pfn_gmem(struct kvm_vcpu *vcpu,
 		kvm_mmu_prepare_memory_fault_exit(vcpu, fault);
 		return -EFAULT;
 	}
+
+	/*
+	 * TODO: Perhaps resolve stage-2 cacheability from pfn_attrs instead of
+	 * relying on host MMIO PFN heuristics when constructing SPTEs?
+	 */
+	WARN_ON_ONCE(__kvm_is_mmio_pfn(fault->pfn) !=
+		     !kvm_gmem_pfn_is_cacheable(pfn_attrs));
+
 	fault->max_level = kvm_max_level_for_order(max_order);
 
 	return RET_PF_CONTINUE;
diff --git a/arch/x86/kvm/mmu/spte.c b/arch/x86/kvm/mmu/spte.c
index 5fc27e9733b38..fd119ac2fad94 100644
--- a/arch/x86/kvm/mmu/spte.c
+++ b/arch/x86/kvm/mmu/spte.c
@@ -106,7 +106,7 @@ u64 make_mmio_spte(struct kvm_vcpu *vcpu, u64 gfn, unsigned int access)
 	return spte;
 }
 
-static bool __kvm_is_mmio_pfn(kvm_pfn_t pfn)
+bool __kvm_is_mmio_pfn(kvm_pfn_t pfn)
 {
 	if (pfn_valid(pfn))
 		return !is_zero_pfn(pfn) && PageReserved(pfn_to_page(pfn)) &&
diff --git a/arch/x86/kvm/mmu/spte.h b/arch/x86/kvm/mmu/spte.h
index e730717824b38..05c7bffa5d2ed 100644
--- a/arch/x86/kvm/mmu/spte.h
+++ b/arch/x86/kvm/mmu/spte.h
@@ -557,6 +557,7 @@ static inline u64 get_mmio_spte_generation(u64 spte)
 	return gen;
 }
 
+bool __kvm_is_mmio_pfn(kvm_pfn_t pfn);
 bool spte_needs_atomic_update(u64 spte);
 
 bool make_spte(struct kvm_vcpu *vcpu, struct kvm_mmu_page *sp,
diff --git a/arch/x86/kvm/svm/sev.c b/arch/x86/kvm/svm/sev.c
index 5e37ea4bc7937..526f2a457cfe0 100644
--- a/arch/x86/kvm/svm/sev.c
+++ b/arch/x86/kvm/svm/sev.c
@@ -4100,7 +4100,8 @@ static void __sev_snp_reload_vmsa(struct kvm_vcpu *vcpu, gpa_t gpa)
 	if (kvm_gmem_get_pfn(vcpu->kvm, slot, gfn, &pfn, NULL, &pfn_attrs))
 		return;
 
-	if (pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY)
+	if ((pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY) ||
+	    !kvm_gmem_pfn_is_cacheable(pfn_attrs))
 		return;
 
 	read_lock(&kvm->mmu_lock);
@@ -5110,6 +5111,12 @@ void sev_handle_rmp_fault(struct kvm_vcpu *vcpu, gpa_t gpa, u64 error_code)
 		return;
 	}
 
+	if (!kvm_gmem_pfn_is_cacheable(pfn_attrs)) {
+		pr_warn_ratelimited("SEV: Unexpected RMP fault, non-cacheable backing page for GPA 0x%llx\n",
+				    gpa);
+		return;
+	}
+
 	ret = snp_lookup_rmpentry(pfn, &assigned, &rmp_level);
 	if (ret || !assigned) {
 		guard(read_lock)(&kvm->mmu_lock);
diff --git a/include/linux/guest_memfd.h b/include/linux/guest_memfd.h
index fb2279a001ebf..8cdc334d1c9aa 100644
--- a/include/linux/guest_memfd.h
+++ b/include/linux/guest_memfd.h
@@ -2,6 +2,7 @@
 #ifndef _LINUX_GUEST_MEMFD_H
 #define _LINUX_GUEST_MEMFD_H
 
+#include <linux/bits.h>
 #include <linux/types.h>
 
 struct file;
@@ -9,7 +10,33 @@ struct folio;
 struct inode;
 struct mempolicy;
 
-#define GUEST_MEMFD_PFN_ATTRS_READONLY	(1ULL << 0)
+#define GUEST_MEMFD_PFN_ATTRS_READONLY		(1ULL << 0)
+
+/*
+ * Cacheability attributes for physical frames returned by providers
+ * (columns show x86 / arm64 memory types):
+ *
+ * Attribute                               | Host PTE       | Stage-2 PTE
+ * ----------------------------------------+----------------+---------------
+ * GUEST_MEMFD_PFN_ATTRS_CACHE_WB          | WB / Normal    | WB / Normal
+ * GUEST_MEMFD_PFN_ATTRS_CACHE_UC          | UC / Device    | UC / Device
+ * GUEST_MEMFD_PFN_ATTRS_CACHE_UC_ALLOW_WC | UC / Device    | UC / Normal-NC
+ * GUEST_MEMFD_PFN_ATTRS_CACHE_WC          | WC / Normal-NC | UC / Normal-NC
+ *
+ * GUEST_MEMFD_PFN_ATTRS_CACHE_WB is 0 so normal cacheable memory is the
+ * default when no cacheability bits are set.
+ */
+#define GUEST_MEMFD_PFN_ATTRS_CACHE_MASK	GENMASK_ULL(2, 1)
+#define GUEST_MEMFD_PFN_ATTRS_CACHE_WB		(0ULL << 1)
+#define GUEST_MEMFD_PFN_ATTRS_CACHE_UC		(1ULL << 1)
+#define GUEST_MEMFD_PFN_ATTRS_CACHE_UC_ALLOW_WC	(2ULL << 1)
+#define GUEST_MEMFD_PFN_ATTRS_CACHE_WC		(3ULL << 1)
+
+static inline bool kvm_gmem_pfn_is_cacheable(u64 pfn_attrs)
+{
+	return (pfn_attrs & GUEST_MEMFD_PFN_ATTRS_CACHE_MASK) ==
+	       GUEST_MEMFD_PFN_ATTRS_CACHE_WB;
+}
 
 /**
  * struct guest_memfd_provider_operations - Operations for external memory providers
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 023bf095340be..1fbb719f0e31f 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -1678,8 +1678,12 @@ static long __kvm_gmem_populate(struct kvm *kvm, struct kvm_memory_slot *slot,
 	if (folio)
 		folio_unlock(folio);
 
-	/* Populating pages initializes private memory, which cannot be read-only. */
-	if (pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY) {
+	/*
+	 * Populating pages initializes private memory, which cannot be
+	 * read-only or non-cacheable.
+	 */
+	if ((pfn_attrs & GUEST_MEMFD_PFN_ATTRS_READONLY) ||
+	    !kvm_gmem_pfn_is_cacheable(pfn_attrs)) {
 		ret = -EPERM;
 		goto out_put_folio;
 	}

-- 
2.56.0.455.g6c5a503b38-goog

