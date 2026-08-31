From: Ackerley Tng <ackerleytng@google.com>
Date: Sun, 30 Aug 2026 17:25:10 -0700
Subject: [PATCH v12 09/45] KVM: guest_memfd: Stub in ability to enable
 in-place shared<=>private conversion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-gmem-inplace-conversion-v12-9-85e5fd25252a@google.com>
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
 Xiaoyao Li <xiaoyao.li@intel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788135915; l=5719;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=fuPA5g+KPLXd1J5vplOVCQXEWYNrFEGb5t+IM2iiuDA=;
 b=Zl/GFK2YJOqfEO1qjinm3ljaqYpgc7Xmo3lnukUV3NCuYapl+/+wXFtGqMiNeGWakN0SxQX15
 TjkhIIejtvfAdDTFm/ry6aZXV6coxoMu8iqP9u9A4q7YByz7s7W68ws
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sean Christopherson <seanjc@google.com>

Stub in global variable to enable in-place guest_memfd private<=>shared
memory conversion, which will eventually be exposed to userspace via a
module param, and wire up the __kvm_is_private_gfn() static call to the
guest_memfd version when in-place conversion is enabled, i.e. when gmem is
the sole authority on private vs. shared memory.

Cc: Fuad Tabba <tabba@google.com>
Cc: Xiaoyao Li <xiaoyao.li@intel.com>
Signed-off-by: Sean Christopherson <seanjc@google.com>
Co-developed-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/virt/kvm/api.rst |  7 +++++++
 include/linux/kvm_host.h       |  6 ++++++
 virt/kvm/guest_memfd.c         | 26 ++++++++++++++++++++++++++
 virt/kvm/kvm_main.c            | 12 +++++++++++-
 4 files changed, 50 insertions(+), 1 deletion(-)

diff --git a/Documentation/virt/kvm/api.rst b/Documentation/virt/kvm/api.rst
index e0430cc750c9e..90a29424c54c8 100644
--- a/Documentation/virt/kvm/api.rst
+++ b/Documentation/virt/kvm/api.rst
@@ -6382,6 +6382,11 @@ KVM_SET_USER_MEMORY_REGION2, e.g. shared memory can be lazily mapped/allocated
 on-demand.
 
 When mapping a gfn into the guest, KVM selects shared vs. private, i.e consumes
+userspace_addr vs. guest_memfd, based on the state in guest_memfd, which is the
+sole authority on private vs. shared memory.  See :ref:`KVM_CREATE_GUEST_MEMFD`
+to find out more about the creation-time shared/private status.
+
+If in-place conversion is disabled, KVM selects shared vs. private, i.e consumes
 userspace_addr vs. guest_memfd, based on the gfn's KVM_MEMORY_ATTRIBUTE_PRIVATE
 state.  At VM creation time, all memory is shared, i.e. the PRIVATE attribute
 is '0' for all gfns.  Userspace can control whether memory is shared/private by
@@ -6429,6 +6434,8 @@ the state of a gfn/page as needed.
 
 The "flags" field is reserved for future extensions and must be '0'.
 
+.. _KVM_CREATE_GUEST_MEMFD:
+
 4.142 KVM_CREATE_GUEST_MEMFD
 ----------------------------
 
diff --git a/include/linux/kvm_host.h b/include/linux/kvm_host.h
index 3579feb631775..b0110143d2ff8 100644
--- a/include/linux/kvm_host.h
+++ b/include/linux/kvm_host.h
@@ -2580,6 +2580,8 @@ static inline bool kvm_vm_is_private_gfn(struct kvm *kvm, gfn_t gfn)
 #endif  /* CONFIG_KVM_VM_MEMORY_ATTRIBUTES */
 
 #ifdef kvm_arch_has_private_mem
+extern bool gmem_in_place_conversion;
+
 typedef bool (kvm_is_private_gfn_t)(struct kvm *kvm, gfn_t gfn);
 DECLARE_STATIC_CALL(__kvm_is_private_gfn, kvm_is_private_gfn_t);
 
@@ -2588,6 +2590,8 @@ static inline bool kvm_is_private_gfn(struct kvm *kvm, gfn_t gfn)
 	return static_call(__kvm_is_private_gfn)(kvm, gfn);
 }
 #else
+#define gmem_in_place_conversion false
+
 static inline bool kvm_is_private_gfn(struct kvm *kvm, gfn_t gfn)
 {
 	return false;
@@ -2595,6 +2599,8 @@ static inline bool kvm_is_private_gfn(struct kvm *kvm, gfn_t gfn)
 #endif /* kvm_arch_has_private_mem */
 
 #ifdef CONFIG_KVM_GUEST_MEMFD
+bool kvm_gmem_is_private_gfn(struct kvm *kvm, gfn_t gfn);
+
 int kvm_gmem_get_pfn(struct kvm *kvm, struct kvm_memory_slot *slot,
 		     gfn_t gfn, kvm_pfn_t *pfn, int *max_order);
 #else
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index ce5efcacda36e..cd966eef45b69 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -478,6 +478,32 @@ static int kvm_gmem_mmap(struct file *file, struct vm_area_struct *vma)
 	return 0;
 }
 
+bool kvm_gmem_is_private_gfn(struct kvm *kvm, gfn_t gfn)
+{
+	struct kvm_memory_slot *slot = gfn_to_memslot(kvm, gfn);
+	struct inode *inode;
+
+	if (!slot)
+		return 0;
+
+	CLASS(gmem_get_file, file)(slot);
+	if (!file)
+		return 0;
+
+	inode = file_inode(file);
+
+	/*
+	 * Rely on the maple tree's internal RCU lock to ensure a stable result.
+	 * This result can become stale as soon as the lock is dropped, so the
+	 * caller _must_ protect consumption of private vs. shared either by
+	 * holding guest_memfd's invalidate lock for the entire duration, or by
+	 * checking mmu_invalidate_retry_gfn() under mmu_lock to serialize
+	 * against concurrent attribute updates.
+	 */
+	return kvm_gmem_is_private_mem(inode, kvm_gmem_get_index(slot, gfn));
+}
+EXPORT_SYMBOL_FOR_KVM_INTERNAL(kvm_gmem_is_private_gfn);
+
 static struct file_operations kvm_gmem_fops = {
 	.mmap		= kvm_gmem_mmap,
 	.open		= generic_file_open,
diff --git a/virt/kvm/kvm_main.c b/virt/kvm/kvm_main.c
index 78278730b2ae4..46d2e123448c2 100644
--- a/virt/kvm/kvm_main.c
+++ b/virt/kvm/kvm_main.c
@@ -102,6 +102,10 @@ EXPORT_SYMBOL_FOR_KVM_INTERNAL(halt_poll_ns_shrink);
 static bool __ro_after_init allow_unsafe_mappings;
 module_param(allow_unsafe_mappings, bool, 0444);
 
+#ifdef kvm_arch_has_private_mem
+bool __ro_after_init gmem_in_place_conversion = false;
+#endif
+
 /*
  * Ordering of locks:
  *
@@ -2423,6 +2427,9 @@ static int kvm_vm_ioctl_clear_dirty_log(struct kvm *kvm,
 static u64 kvm_supported_vm_mem_attributes(struct kvm *kvm)
 {
 #ifdef kvm_arch_has_private_mem
+	if (gmem_in_place_conversion)
+		return 0;
+
 	if (!kvm || kvm_arch_has_private_mem(kvm))
 		return KVM_MEMORY_ATTRIBUTE_PRIVATE;
 #endif
@@ -2634,8 +2641,11 @@ EXPORT_STATIC_CALL_GPL(__kvm_is_private_gfn);
 
 static void kvm_init_memory_attributes(void)
 {
+	if (gmem_in_place_conversion)
+		static_call_update(__kvm_is_private_gfn, kvm_gmem_is_private_gfn);
 #ifdef CONFIG_KVM_VM_MEMORY_ATTRIBUTES
-	static_call_update(__kvm_is_private_gfn, kvm_vm_is_private_gfn);
+	else
+		static_call_update(__kvm_is_private_gfn, kvm_vm_is_private_gfn);
 #endif
 }
 #else

-- 
2.55.0.897.gb25b4bd76c-goog

