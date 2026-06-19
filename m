From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 18 Jun 2026 17:31:44 -0700
Subject: [PATCH v8 07/46] KVM: Rename memory attribute APIs to prepare for
 in-place gmem conversion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260618-gmem-inplace-conversion-v8-7-9d2959357853@google.com>
References: <20260618-gmem-inplace-conversion-v8-0-9d2959357853@google.com>
In-Reply-To: <20260618-gmem-inplace-conversion-v8-0-9d2959357853@google.com>
To: aik@amd.com, andrew.jones@linux.dev, binbin.wu@linux.intel.com, 
 brauner@kernel.org, chao.p.peng@linux.intel.com, david@kernel.org, 
 jmattson@google.com, jthoughton@google.com, michael.roth@amd.com, 
 oupton@kernel.org, pankaj.gupta@amd.com, qperret@google.com, 
 rick.p.edgecombe@intel.com, rientjes@google.com, shivankg@amd.com, 
 steven.price@arm.com, tabba@google.com, willy@infradead.org, 
 wyihan@google.com, yan.y.zhao@intel.com, forkloop@google.com, 
 pratyush@kernel.org, suzuki.poulose@arm.com, aneesh.kumar@kernel.org, 
 liam@infradead.org, Paolo Bonzini <pbonzini@redhat.com>, 
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
 Jason Gunthorpe <jgg@ziepe.ca>, Vlastimil Babka <vbabka@kernel.org>, 
 Baoquan He <baoquan.he@linux.dev>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781829104; l=6750;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=AxBihaCLX0GxTHg2jIViDGPzQnVe7kaqirasKB6Zq0Q=;
 b=RxjUxb5mhHLRNGU/hAwlj5EfVbs3uZkdfvx7fkXSaQxT9NbNDR3MOrMAp4Zu75NstEPFxYqRG
 pPKqh78kvtbCGNwrzmyKIAEIKAqKUiluPwb+X/DPY5UqiV32KOjpTOw
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sean Christopherson <seanjc@google.com>

Rename memory attribute APIs to add a "vm_" in the name in anticipation of
moving PRIVATE tracking into guest_memfd, to allow in-place conversion
between SHARED and PRIVATE.  At that point, there will effectively be two
(potential) sources of memory attributes: the VM and guest_memfd.

No functional change intended.

Signed-off-by: Sean Christopherson <seanjc@google.com>
---
 arch/x86/kvm/mmu/mmu.c   |  6 +++---
 include/linux/kvm_host.h | 15 +++++++++++----
 virt/kvm/guest_memfd.c   |  6 +++---
 virt/kvm/kvm_main.c      | 16 ++++++++--------
 4 files changed, 25 insertions(+), 18 deletions(-)

diff --git a/arch/x86/kvm/mmu/mmu.c b/arch/x86/kvm/mmu/mmu.c
index e0005a21b6e22..cbc50aef801fb 100644
--- a/arch/x86/kvm/mmu/mmu.c
+++ b/arch/x86/kvm/mmu/mmu.c
@@ -8087,11 +8087,11 @@ static bool hugepage_has_attrs(struct kvm *kvm, struct kvm_memory_slot *slot,
 	const unsigned long end = start + KVM_PAGES_PER_HPAGE(level);
 
 	if (level == PG_LEVEL_2M)
-		return kvm_range_has_memory_attributes(kvm, start, end, ~0, attrs);
+		return kvm_range_has_vm_memory_attributes(kvm, start, end, ~0, attrs);
 
 	for (gfn = start; gfn < end; gfn += KVM_PAGES_PER_HPAGE(level - 1)) {
 		if (hugepage_test_mixed(slot, gfn, level - 1) ||
-		    attrs != kvm_get_memory_attributes(kvm, gfn))
+		    attrs != kvm_get_vm_memory_attributes(kvm, gfn))
 			return false;
 	}
 	return true;
@@ -8191,7 +8191,7 @@ void kvm_mmu_init_memslot_memory_attributes(struct kvm *kvm,
 		 * be manually checked as the attributes may already be mixed.
 		 */
 		for (gfn = start; gfn < end; gfn += nr_pages) {
-			unsigned long attrs = kvm_get_memory_attributes(kvm, gfn);
+			unsigned long attrs = kvm_get_vm_memory_attributes(kvm, gfn);
 
 			if (hugepage_has_attrs(kvm, slot, gfn, level, attrs))
 				hugepage_clear_mixed(slot, gfn, level);
diff --git a/include/linux/kvm_host.h b/include/linux/kvm_host.h
index d370e834d619e..eb26d4ea8945a 100644
--- a/include/linux/kvm_host.h
+++ b/include/linux/kvm_host.h
@@ -2534,13 +2534,13 @@ static inline bool kvm_memslot_is_gmem_only(const struct kvm_memory_slot *slot)
 }
 
 #ifdef CONFIG_KVM_VM_MEMORY_ATTRIBUTES
-static inline unsigned long kvm_get_memory_attributes(struct kvm *kvm, gfn_t gfn)
+static inline unsigned long kvm_get_vm_memory_attributes(struct kvm *kvm, gfn_t gfn)
 {
 	return xa_to_value(xa_load(&kvm->mem_attr_array, gfn));
 }
 
-bool kvm_range_has_memory_attributes(struct kvm *kvm, gfn_t start, gfn_t end,
-				     unsigned long mask, unsigned long attrs);
+bool kvm_range_has_vm_memory_attributes(struct kvm *kvm, gfn_t start, gfn_t end,
+					unsigned long mask, unsigned long attrs);
 bool kvm_arch_pre_set_memory_attributes(struct kvm *kvm,
 					struct kvm_gfn_range *range);
 bool kvm_arch_post_set_memory_attributes(struct kvm *kvm,
@@ -2548,7 +2548,14 @@ bool kvm_arch_post_set_memory_attributes(struct kvm *kvm,
 
 static inline bool kvm_mem_is_private(struct kvm *kvm, gfn_t gfn)
 {
-	return kvm_get_memory_attributes(kvm, gfn) & KVM_MEMORY_ATTRIBUTE_PRIVATE;
+	return kvm_get_vm_memory_attributes(kvm, gfn) & KVM_MEMORY_ATTRIBUTE_PRIVATE;
+}
+static inline bool kvm_mem_range_is_private(struct kvm *kvm, gfn_t start,
+					    gfn_t end)
+{
+	return kvm_range_has_vm_memory_attributes(kvm, start, end,
+						  KVM_MEMORY_ATTRIBUTE_PRIVATE,
+						  KVM_MEMORY_ATTRIBUTE_PRIVATE);
 }
 #else
 static inline bool kvm_mem_is_private(struct kvm *kvm, gfn_t gfn)
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index b4c24fdf159f6..8101f64e0366f 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -915,9 +915,9 @@ static long __kvm_gmem_populate(struct kvm *kvm, struct kvm_memory_slot *slot,
 
 	folio_unlock(folio);
 
-	if (!kvm_range_has_memory_attributes(kvm, gfn, gfn + 1,
-					     KVM_MEMORY_ATTRIBUTE_PRIVATE,
-					     KVM_MEMORY_ATTRIBUTE_PRIVATE)) {
+	if (!kvm_range_has_vm_memory_attributes(kvm, gfn, gfn + 1,
+						KVM_MEMORY_ATTRIBUTE_PRIVATE,
+						KVM_MEMORY_ATTRIBUTE_PRIVATE)) {
 		ret = -EINVAL;
 		goto out_put_folio;
 	}
diff --git a/virt/kvm/kvm_main.c b/virt/kvm/kvm_main.c
index 7b989b659cf82..6669f1477013c 100644
--- a/virt/kvm/kvm_main.c
+++ b/virt/kvm/kvm_main.c
@@ -2419,7 +2419,7 @@ static int kvm_vm_ioctl_clear_dirty_log(struct kvm *kvm,
 #endif /* CONFIG_KVM_GENERIC_DIRTYLOG_READ_PROTECT */
 
 #ifdef CONFIG_KVM_VM_MEMORY_ATTRIBUTES
-static u64 kvm_supported_mem_attributes(struct kvm *kvm)
+static u64 kvm_supported_vm_mem_attributes(struct kvm *kvm)
 {
 #ifdef kvm_arch_has_private_mem
 	if (!kvm || kvm_arch_has_private_mem(kvm))
@@ -2433,19 +2433,19 @@ static u64 kvm_supported_mem_attributes(struct kvm *kvm)
  * Returns true if _all_ gfns in the range [@start, @end) have attributes
  * such that the bits in @mask match @attrs.
  */
-bool kvm_range_has_memory_attributes(struct kvm *kvm, gfn_t start, gfn_t end,
-				     unsigned long mask, unsigned long attrs)
+bool kvm_range_has_vm_memory_attributes(struct kvm *kvm, gfn_t start, gfn_t end,
+					unsigned long mask, unsigned long attrs)
 {
 	XA_STATE(xas, &kvm->mem_attr_array, start);
 	unsigned long index;
 	void *entry;
 
-	mask &= kvm_supported_mem_attributes(kvm);
+	mask &= kvm_supported_vm_mem_attributes(kvm);
 	if (attrs & ~mask)
 		return false;
 
 	if (end == start + 1)
-		return (kvm_get_memory_attributes(kvm, start) & mask) == attrs;
+		return (kvm_get_vm_memory_attributes(kvm, start) & mask) == attrs;
 
 	guard(rcu)();
 	if (!attrs)
@@ -2567,7 +2567,7 @@ static int kvm_vm_set_mem_attributes(struct kvm *kvm, gfn_t start, gfn_t end,
 	mutex_lock(&kvm->slots_lock);
 
 	/* Nothing to do if the entire range has the desired attributes. */
-	if (kvm_range_has_memory_attributes(kvm, start, end, ~0, attributes))
+	if (kvm_range_has_vm_memory_attributes(kvm, start, end, ~0, attributes))
 		goto out_unlock;
 
 	/*
@@ -2606,7 +2606,7 @@ static int kvm_vm_ioctl_set_mem_attributes(struct kvm *kvm,
 	/* flags is currently not used. */
 	if (attrs->flags)
 		return -EINVAL;
-	if (attrs->attributes & ~kvm_supported_mem_attributes(kvm))
+	if (attrs->attributes & ~kvm_supported_vm_mem_attributes(kvm))
 		return -EINVAL;
 	if (attrs->size == 0 || attrs->address + attrs->size < attrs->address)
 		return -EINVAL;
@@ -4926,7 +4926,7 @@ static int kvm_vm_ioctl_check_extension_generic(struct kvm *kvm, long arg)
 		return 1;
 #ifdef CONFIG_KVM_VM_MEMORY_ATTRIBUTES
 	case KVM_CAP_MEMORY_ATTRIBUTES:
-		return kvm_supported_mem_attributes(kvm);
+		return kvm_supported_vm_mem_attributes(kvm);
 #endif
 #ifdef CONFIG_KVM_GUEST_MEMFD
 	case KVM_CAP_GUEST_MEMFD:

-- 
2.55.0.rc0.738.g0c8ab3ebcc-goog

