From: Ackerley Tng <ackerleytng@google.com>
Date: Tue, 28 Jul 2026 17:35:06 -0700
Subject: [PATCH v9 07/41] KVM: guest_memfd: Wire up core private/shared
 attribute interfaces
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260728-gmem-inplace-conversion-v9-7-35f9aec2aed2@google.com>
References: <20260728-gmem-inplace-conversion-v9-0-35f9aec2aed2@google.com>
In-Reply-To: <20260728-gmem-inplace-conversion-v9-0-35f9aec2aed2@google.com>
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
 Peter Xu <peterx@redhat.com>, Jason Gunthorpe <jgg@ziepe.ca>, 
 Vlastimil Babka <vbabka@kernel.org>, Baoquan He <baoquan.he@linux.dev>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785285305; l=4904;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=Khc6sycubGrfoJCb/kBxgxJ7UDuxLVJB5MenqDESOq8=;
 b=c/JKNYH+h7dgoAGoTZo/8qTYbeNkf3QS755Gf97nN6FnguidBdhiMdZ4OfzZK7DSDrl3bLd4l
 tjElD8FU2xUBYgOf4Tg9CW7t1Se5AjSPj25c1x5+i3J/ohAwM5mSBBL
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sean Christopherson <seanjc@google.com>

With in-place conversion, guest_memfd is able to track the private/shared
status of memory. Use a global flag to toggle between tracking
private/shared status per-vm or within guest_memfd.

When queried for supported vm memory attributes, return 0 if attributes are
tracked in guest_memfd.

When querying for memory attributes over a range, look up memory attributes
based on the flag's state at query time.

For per-GFN memory attribute queries, choose an implementation (VM or
guest_memfd lookup) at KVM load time.

The flag is always false for now and will be made toggle-able after all
in-place conversion features are added in subsequent patches.

If/since the flag is false, if CONFIG_KVM_VM_MEMORY_ATTRIBUTES is also not
selected, the per-GFN memory attribute query defaults to returning
0 (false/not private).

Signed-off-by: Sean Christopherson <seanjc@google.com>
Reviewed-by: Fuad Tabba <tabba@google.com>
Tested-by: Shivank Garg <shivankg@amd.com>
Co-developed-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/linux/kvm_host.h |  4 ++++
 virt/kvm/guest_memfd.c   | 25 ++++++++++++++++++++++---
 virt/kvm/kvm_main.c      | 12 +++++++++++-
 3 files changed, 37 insertions(+), 4 deletions(-)

diff --git a/include/linux/kvm_host.h b/include/linux/kvm_host.h
index 73f564b87a324..a913dd57ae622 100644
--- a/include/linux/kvm_host.h
+++ b/include/linux/kvm_host.h
@@ -2579,6 +2579,8 @@ static inline bool kvm_vm_mem_is_private(struct kvm *kvm, gfn_t gfn)
 #endif  /* CONFIG_KVM_VM_MEMORY_ATTRIBUTES */
 
 #ifdef kvm_arch_has_private_mem
+extern bool gmem_in_place_conversion;
+
 typedef bool (kvm_mem_is_private_t)(struct kvm *kvm, gfn_t gfn);
 DECLARE_STATIC_CALL(__kvm_mem_is_private, kvm_mem_is_private_t);
 
@@ -2587,6 +2589,8 @@ static inline bool kvm_mem_is_private(struct kvm *kvm, gfn_t gfn)
 	return static_call(__kvm_mem_is_private)(kvm, gfn);
 }
 #else
+#define gmem_in_place_conversion false
+
 static inline bool kvm_mem_is_private(struct kvm *kvm, gfn_t gfn)
 {
 	return false;
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 33c9830190e2e..89cf922232920 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -893,6 +893,27 @@ int kvm_gmem_get_pfn(struct kvm *kvm, struct kvm_memory_slot *slot,
 EXPORT_SYMBOL_FOR_KVM_INTERNAL(kvm_gmem_get_pfn);
 
 #ifdef CONFIG_HAVE_KVM_ARCH_GMEM_POPULATE
+static bool kvm_range_is_private(struct file *file, pgoff_t index,
+				 size_t nr_pages, struct kvm *kvm, gfn_t gfn)
+{
+	struct inode *inode = file_inode(file);
+	pgoff_t last = index + nr_pages - 1;
+	struct maple_tree *mt;
+	void *entry;
+
+	if (!gmem_in_place_conversion)
+		return kvm_range_has_vm_memory_attributes(kvm, gfn, gfn + nr_pages,
+							  KVM_MEMORY_ATTRIBUTE_PRIVATE,
+							  KVM_MEMORY_ATTRIBUTE_PRIVATE);
+
+	mt = &GMEM_I(inode)->attributes;
+	mt_for_each(mt, entry, index, last) {
+		if (kvm_gmem_interpret_entry(inode, entry) !=
+		    KVM_MEMORY_ATTRIBUTE_PRIVATE)
+			return false;
+	}
+	return true;
+}
 
 static long __kvm_gmem_populate(struct kvm *kvm, struct kvm_memory_slot *slot,
 				struct file *file, gfn_t gfn, struct page *src_page,
@@ -913,9 +934,7 @@ static long __kvm_gmem_populate(struct kvm *kvm, struct kvm_memory_slot *slot,
 
 	folio_unlock(folio);
 
-	if (!kvm_range_has_vm_memory_attributes(kvm, gfn, gfn + 1,
-						KVM_MEMORY_ATTRIBUTE_PRIVATE,
-						KVM_MEMORY_ATTRIBUTE_PRIVATE)) {
+	if (!kvm_range_is_private(file, index, 1, kvm, gfn)) {
 		ret = -EINVAL;
 		goto out_put_folio;
 	}
diff --git a/virt/kvm/kvm_main.c b/virt/kvm/kvm_main.c
index 80317d2c15d07..0dfc91b9478ce 100644
--- a/virt/kvm/kvm_main.c
+++ b/virt/kvm/kvm_main.c
@@ -101,6 +101,10 @@ EXPORT_SYMBOL_FOR_KVM_INTERNAL(halt_poll_ns_shrink);
 static bool __ro_after_init allow_unsafe_mappings;
 module_param(allow_unsafe_mappings, bool, 0444);
 
+#ifdef kvm_arch_has_private_mem
+bool __ro_after_init gmem_in_place_conversion = false;
+#endif
+
 /*
  * Ordering of locks:
  *
@@ -2422,6 +2426,9 @@ static int kvm_vm_ioctl_clear_dirty_log(struct kvm *kvm,
 static u64 kvm_supported_vm_mem_attributes(struct kvm *kvm)
 {
 #ifdef kvm_arch_has_private_mem
+	if (gmem_in_place_conversion)
+		return 0;
+
 	if (!kvm || kvm_arch_has_private_mem(kvm))
 		return KVM_MEMORY_ATTRIBUTE_PRIVATE;
 #endif
@@ -2633,8 +2640,11 @@ EXPORT_STATIC_CALL_GPL(__kvm_mem_is_private);
 
 static void kvm_init_memory_attributes(void)
 {
+	if (gmem_in_place_conversion)
+		static_call_update(__kvm_mem_is_private, kvm_gmem_is_private);
 #ifdef CONFIG_KVM_VM_MEMORY_ATTRIBUTES
-	static_call_update(__kvm_mem_is_private, kvm_vm_mem_is_private);
+	else
+		static_call_update(__kvm_mem_is_private, kvm_vm_mem_is_private);
 #endif
 }
 #else

-- 
2.55.0.508.g3f0d502094-goog

