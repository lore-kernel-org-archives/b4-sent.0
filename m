From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 07 Aug 2026 14:52:44 -0700
Subject: [PATCH v10 05/41] KVM: Rename memory attribute APIs to prepare for
 in-place gmem conversion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260807-gmem-inplace-conversion-v10-5-2fc18ee6d3ba@google.com>
References: <20260807-gmem-inplace-conversion-v10-0-2fc18ee6d3ba@google.com>
In-Reply-To: <20260807-gmem-inplace-conversion-v10-0-2fc18ee6d3ba@google.com>
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
 Jason Gunthorpe <jgg@ziepe.ca>, John Hubbard <jhubbard@nvidia.com>, 
 Peter Xu <peterx@redhat.com>, tarunsahu@google.com, 
 Jason Gunthorpe <jgg@ziepe.ca>, Vlastimil Babka <vbabka@kernel.org>, 
 Baoquan He <baoquan.he@linux.dev>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>, 
 Xiaoyao Li <xiaoyao.li@intel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786139564; l=9969;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=C83vX1lAmz8SBa+/53A0ujJhVXz9H4O3UCQrFd3/VNI=;
 b=twt2ZPW27wC5JlvijhCC0Gmq1xhHh8LZOQJFxsOqpajmw7ZLFYulAnqL8YXgsdsOyfNmZ5rXU
 huDewhAxu32C92edhQ6dV5Eig7SE3a8YayF9dcfBT3wngfVS4IsKo8N
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sean Christopherson <seanjc@google.com>

Rename memory attribute APIs to add a "vm_" in the name in anticipation of
moving PRIVATE tracking into guest_memfd, to allow in-place conversion
between SHARED and PRIVATE.  At that point, there will effectively be two
(potential) sources of memory attributes: the VM and guest_memfd.

kvm_vm_set_mem_attributes() already has "vm" in the name to indicate that
it is a VM ioctl. Rename it to kvm_set_vm_mem_attributes() to show that it
is setting the VM's memory attributes. (Drop the VM-ioctl scoping since it
is a helper local to the file.) Update the accompanying trace function to
match.

No functional change intended.

Signed-off-by: Sean Christopherson <seanjc@google.com>
Reviewed-by: Fuad Tabba <tabba@google.com>
Tested-by: Shivank Garg <shivankg@amd.com>
Reviewed-by: Xiaoyao Li <xiaoyao.li@intel.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 arch/x86/kvm/mmu/mmu.c     | 14 +++++++-------
 include/linux/kvm_host.h   | 16 ++++++++--------
 include/trace/events/kvm.h |  2 +-
 virt/kvm/kvm_main.c        | 32 ++++++++++++++++----------------
 4 files changed, 32 insertions(+), 32 deletions(-)

diff --git a/arch/x86/kvm/mmu/mmu.c b/arch/x86/kvm/mmu/mmu.c
index acafa7964964c..2b3bc73845a8a 100644
--- a/arch/x86/kvm/mmu/mmu.c
+++ b/arch/x86/kvm/mmu/mmu.c
@@ -8089,8 +8089,8 @@ static void hugepage_set_mixed(struct kvm_memory_slot *slot, gfn_t gfn,
 	lpage_info_slot(gfn, slot, level)->disallow_lpage |= KVM_LPAGE_MIXED_FLAG;
 }
 
-bool kvm_arch_pre_set_memory_attributes(struct kvm *kvm,
-					struct kvm_gfn_range *range)
+bool kvm_arch_pre_set_vm_memory_attributes(struct kvm *kvm,
+					   struct kvm_gfn_range *range)
 {
 	struct kvm_memory_slot *slot = range->slot;
 	int level;
@@ -8159,18 +8159,18 @@ static bool hugepage_has_attrs(struct kvm *kvm, struct kvm_memory_slot *slot,
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
 }
 
-bool kvm_arch_post_set_memory_attributes(struct kvm *kvm,
-					 struct kvm_gfn_range *range)
+bool kvm_arch_post_set_vm_memory_attributes(struct kvm *kvm,
+					    struct kvm_gfn_range *range)
 {
 	unsigned long attrs = range->arg.attributes;
 	struct kvm_memory_slot *slot = range->slot;
@@ -8263,7 +8263,7 @@ void kvm_mmu_init_memslot_memory_attributes(struct kvm *kvm,
 		 * be manually checked as the attributes may already be mixed.
 		 */
 		for (gfn = start; gfn < end; gfn += nr_pages) {
-			unsigned long attrs = kvm_get_memory_attributes(kvm, gfn);
+			unsigned long attrs = kvm_get_vm_memory_attributes(kvm, gfn);
 
 			if (hugepage_has_attrs(kvm, slot, gfn, level, attrs))
 				hugepage_clear_mixed(slot, gfn, level);
diff --git a/include/linux/kvm_host.h b/include/linux/kvm_host.h
index e3666d0b40b74..3464a0ddbae74 100644
--- a/include/linux/kvm_host.h
+++ b/include/linux/kvm_host.h
@@ -2561,21 +2561,21 @@ static inline bool kvm_memslot_is_gmem_only(const struct kvm_memory_slot *slot)
 }
 
 #ifdef CONFIG_KVM_VM_MEMORY_ATTRIBUTES
-static inline unsigned long kvm_get_memory_attributes(struct kvm *kvm, gfn_t gfn)
+static inline unsigned long kvm_get_vm_memory_attributes(struct kvm *kvm, gfn_t gfn)
 {
 	return xa_to_value(xa_load(&kvm->mem_attr_array, gfn));
 }
 
-bool kvm_range_has_memory_attributes(struct kvm *kvm, gfn_t start, gfn_t end,
-				     unsigned long mask, unsigned long attrs);
-bool kvm_arch_pre_set_memory_attributes(struct kvm *kvm,
-					struct kvm_gfn_range *range);
-bool kvm_arch_post_set_memory_attributes(struct kvm *kvm,
-					 struct kvm_gfn_range *range);
+bool kvm_range_has_vm_memory_attributes(struct kvm *kvm, gfn_t start, gfn_t end,
+					unsigned long mask, unsigned long attrs);
+bool kvm_arch_pre_set_vm_memory_attributes(struct kvm *kvm,
+					   struct kvm_gfn_range *range);
+bool kvm_arch_post_set_vm_memory_attributes(struct kvm *kvm,
+					    struct kvm_gfn_range *range);
 
 static inline bool kvm_mem_is_private(struct kvm *kvm, gfn_t gfn)
 {
-	return kvm_get_memory_attributes(kvm, gfn) & KVM_MEMORY_ATTRIBUTE_PRIVATE;
+	return kvm_get_vm_memory_attributes(kvm, gfn) & KVM_MEMORY_ATTRIBUTE_PRIVATE;
 }
 #else
 static inline bool kvm_mem_is_private(struct kvm *kvm, gfn_t gfn)
diff --git a/include/trace/events/kvm.h b/include/trace/events/kvm.h
index 1ba72bd73ea2f..c4d514d2350cf 100644
--- a/include/trace/events/kvm.h
+++ b/include/trace/events/kvm.h
@@ -364,7 +364,7 @@ TRACE_EVENT(kvm_dirty_ring_exit,
  * @end:	End address of guest memory range
  * @attr:	The value of the attribute being set.
  */
-TRACE_EVENT(kvm_vm_set_mem_attributes,
+TRACE_EVENT(kvm_set_vm_mem_attributes,
 	TP_PROTO(gfn_t start, gfn_t end, unsigned long attr),
 	TP_ARGS(start, end, attr),
 
diff --git a/virt/kvm/kvm_main.c b/virt/kvm/kvm_main.c
index 560ff05e95959..b3f9396123be2 100644
--- a/virt/kvm/kvm_main.c
+++ b/virt/kvm/kvm_main.c
@@ -2420,7 +2420,7 @@ static int kvm_vm_ioctl_clear_dirty_log(struct kvm *kvm,
 #endif /* CONFIG_KVM_GENERIC_DIRTYLOG_READ_PROTECT */
 
 #ifdef CONFIG_KVM_VM_MEMORY_ATTRIBUTES
-static u64 kvm_supported_mem_attributes(struct kvm *kvm)
+static u64 kvm_supported_vm_mem_attributes(struct kvm *kvm)
 {
 #ifdef kvm_arch_has_private_mem
 	if (!kvm || kvm_arch_has_private_mem(kvm))
@@ -2434,19 +2434,19 @@ static u64 kvm_supported_mem_attributes(struct kvm *kvm)
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
@@ -2517,8 +2517,8 @@ static __always_inline void kvm_handle_gfn_range(struct kvm *kvm,
 		KVM_MMU_UNLOCK(kvm);
 }
 
-static bool kvm_pre_set_memory_attributes(struct kvm *kvm,
-					  struct kvm_gfn_range *range)
+static bool kvm_pre_set_vm_memory_attributes(struct kvm *kvm,
+					     struct kvm_gfn_range *range)
 {
 	/*
 	 * Unconditionally add the range to the invalidation set, regardless of
@@ -2533,18 +2533,18 @@ static bool kvm_pre_set_memory_attributes(struct kvm *kvm,
 	 */
 	kvm_mmu_invalidate_range_add(kvm, range->start, range->end);
 
-	return kvm_arch_pre_set_memory_attributes(kvm, range);
+	return kvm_arch_pre_set_vm_memory_attributes(kvm, range);
 }
 
 /* Set @attributes for the gfn range [@start, @end). */
-static int kvm_vm_set_mem_attributes(struct kvm *kvm, gfn_t start, gfn_t end,
+static int kvm_set_vm_mem_attributes(struct kvm *kvm, gfn_t start, gfn_t end,
 				     unsigned long attributes)
 {
 	struct kvm_mmu_notifier_range pre_set_range = {
 		.start = start,
 		.end = end,
 		.arg.attributes = attributes,
-		.handler = kvm_pre_set_memory_attributes,
+		.handler = kvm_pre_set_vm_memory_attributes,
 		.on_lock = kvm_mmu_invalidate_start,
 		.flush_on_ret = true,
 		.may_block = true,
@@ -2553,7 +2553,7 @@ static int kvm_vm_set_mem_attributes(struct kvm *kvm, gfn_t start, gfn_t end,
 		.start = start,
 		.end = end,
 		.arg.attributes = attributes,
-		.handler = kvm_arch_post_set_memory_attributes,
+		.handler = kvm_arch_post_set_vm_memory_attributes,
 		.on_lock = kvm_mmu_invalidate_end,
 		.may_block = true,
 	};
@@ -2563,12 +2563,12 @@ static int kvm_vm_set_mem_attributes(struct kvm *kvm, gfn_t start, gfn_t end,
 
 	entry = attributes ? xa_mk_value(attributes) : NULL;
 
-	trace_kvm_vm_set_mem_attributes(start, end, attributes);
+	trace_kvm_set_vm_mem_attributes(start, end, attributes);
 
 	mutex_lock(&kvm->slots_lock);
 
 	/* Nothing to do if the entire range has the desired attributes. */
-	if (kvm_range_has_memory_attributes(kvm, start, end, ~0, attributes))
+	if (kvm_range_has_vm_memory_attributes(kvm, start, end, ~0, attributes))
 		goto out_unlock;
 
 	/*
@@ -2607,7 +2607,7 @@ static int kvm_vm_ioctl_set_mem_attributes(struct kvm *kvm,
 	/* flags is currently not used. */
 	if (attrs->flags)
 		return -EINVAL;
-	if (attrs->attributes & ~kvm_supported_mem_attributes(kvm))
+	if (attrs->attributes & ~kvm_supported_vm_mem_attributes(kvm))
 		return -EINVAL;
 	if (attrs->size == 0 || attrs->address + attrs->size < attrs->address)
 		return -EINVAL;
@@ -2624,7 +2624,7 @@ static int kvm_vm_ioctl_set_mem_attributes(struct kvm *kvm,
 	 */
 	BUILD_BUG_ON(sizeof(attrs->attributes) != sizeof(unsigned long));
 
-	return kvm_vm_set_mem_attributes(kvm, start, end, attrs->attributes);
+	return kvm_set_vm_mem_attributes(kvm, start, end, attrs->attributes);
 }
 #endif /* CONFIG_KVM_VM_MEMORY_ATTRIBUTES */
 
@@ -4945,7 +4945,7 @@ static int kvm_vm_ioctl_check_extension_generic(struct kvm *kvm, long arg)
 		return 1;
 #ifdef CONFIG_KVM_VM_MEMORY_ATTRIBUTES
 	case KVM_CAP_MEMORY_ATTRIBUTES:
-		return kvm_supported_mem_attributes(kvm);
+		return kvm_supported_vm_mem_attributes(kvm);
 #endif
 #ifdef CONFIG_KVM_GUEST_MEMFD
 	case KVM_CAP_GUEST_MEMFD:

-- 
2.55.0.654.g21b8a5bc05-goog

