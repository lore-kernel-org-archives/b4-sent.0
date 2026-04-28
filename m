From: Ackerley Tng <ackerleytng@google.com>
Date: Tue, 28 Apr 2026 16:25:23 -0700
Subject: [PATCH RFC v5 28/53] KVM: Add CAP to enumerate supported
 SET_MEMORY_ATTRIBUTES2 flags
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-gmem-inplace-conversion-v5-28-d8608ccfca22@google.com>
References: <20260428-gmem-inplace-conversion-v5-0-d8608ccfca22@google.com>
In-Reply-To: <20260428-gmem-inplace-conversion-v5-0-d8608ccfca22@google.com>
To: aik@amd.com, andrew.jones@linux.dev, binbin.wu@linux.intel.com, 
 brauner@kernel.org, chao.p.peng@linux.intel.com, david@kernel.org, 
 ira.weiny@intel.com, jmattson@google.com, jthoughton@google.com, 
 michael.roth@amd.com, oupton@kernel.org, pankaj.gupta@amd.com, 
 qperret@google.com, rick.p.edgecombe@intel.com, rientjes@google.com, 
 shivankg@amd.com, steven.price@arm.com, tabba@google.com, 
 willy@infradead.org, wyihan@google.com, yan.y.zhao@intel.com, 
 forkloop@google.com, pratyush@kernel.org, suzuki.poulose@arm.com, 
 aneesh.kumar@kernel.org, Paolo Bonzini <pbonzini@redhat.com>, 
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
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <bhe@redhat.com>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Youngjun Park <youngjun.park@lge.com>, Qi Zheng <qi.zheng@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Vlastimil Babka <vbabka@kernel.org>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777418714; l=5528;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=pIqYKdyBIT9N1Rsog/1YD0EZWPUQYi37ZuQ2ZuzAyaY=;
 b=LQBZ48AGkz7+oQLurDh/BMdAf+VaqtbjZWVqTJOoJUGv/ubksh354Cn4r3Ib2Hs6R4f/Dz53w
 n3OEKv307fhDKS75Bmp15XQZ4T1xi6Ti7nszk4NxAk+S39eJn3ZXztw
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add CAP to enumerate supported SET_MEMORY_ATTRIBUTES2 flags, so userspace
can find out which flags are supported when sending the
KVM_SET_MEMORY_ATTRIBUTES2 ioctl to a guest_memfd.

Add a parameter for_cap to support enumeration of supported flags
irrespective of attribute being set.

These flags are only supported by guest_memfd, hence, if
vm_memory_attributes is enabled, return 0 - no flags are supported when
KVM_SET_MEMORY_ATTRIBUTES2 is sent to a VM fd.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/virt/kvm/api.rst |  3 +++
 arch/x86/kvm/x86.c             |  5 +++--
 include/linux/kvm_host.h       | 11 ++++++++++-
 include/uapi/linux/kvm.h       |  1 +
 virt/kvm/guest_memfd.c         |  6 ++++--
 virt/kvm/kvm_main.c            |  5 +++++
 6 files changed, 26 insertions(+), 5 deletions(-)

diff --git a/Documentation/virt/kvm/api.rst b/Documentation/virt/kvm/api.rst
index aaa4a82f0b75d..38938243c2dfd 100644
--- a/Documentation/virt/kvm/api.rst
+++ b/Documentation/virt/kvm/api.rst
@@ -6685,6 +6685,9 @@ guarantees are made on offset ranges that do not have memory allocated
 and range [0x0000, 0x3000) was set to shared, the content mode would
 apply to only to offset ranges [0x0000, 0x1000) and [0x2000, 0x3000).
 
+The supported content modes can be queried using
+``KVM_CAP_MEMORY_ATTRIBUTES2_FLAGS``.
+
 See also: :ref: `KVM_SET_MEMORY_ATTRIBUTES`.
 
 .. _kvm_run:
diff --git a/arch/x86/kvm/x86.c b/arch/x86/kvm/x86.c
index 296ed3b8ace6c..92709735613d5 100644
--- a/arch/x86/kvm/x86.c
+++ b/arch/x86/kvm/x86.c
@@ -14195,7 +14195,8 @@ void kvm_arch_gmem_invalidate(kvm_pfn_t start, kvm_pfn_t end)
 }
 #endif
 
-u64 kvm_arch_gmem_supported_content_modes(struct kvm *kvm, bool to_private)
+u64 kvm_arch_gmem_supported_content_modes(struct kvm *kvm, bool to_private,
+					  bool for_cap)
 {
 	if (!kvm) {
 		return KVM_SET_MEMORY_ATTRIBUTES2_ZERO |
@@ -14227,7 +14228,7 @@ u64 kvm_arch_gmem_supported_content_modes(struct kvm *kvm, bool to_private)
 		 * shared, memory contents for pages that had already
 		 * been faulted could be zeroed.
 		 */
-		if (to_private && !kvm->arch.pre_fault_allowed)
+		if (for_cap || (to_private && !kvm->arch.pre_fault_allowed))
 			supported |= KVM_SET_MEMORY_ATTRIBUTES2_PRESERVE;
 
 		return supported;
diff --git a/include/linux/kvm_host.h b/include/linux/kvm_host.h
index 458bad0083c37..13d126dde32f1 100644
--- a/include/linux/kvm_host.h
+++ b/include/linux/kvm_host.h
@@ -742,7 +742,8 @@ static inline u64 kvm_gmem_get_supported_flags(struct kvm *kvm)
 	return flags;
 }
 
-u64 kvm_arch_gmem_supported_content_modes(struct kvm *kvm, bool to_private);
+u64 kvm_arch_gmem_supported_content_modes(struct kvm *kvm, bool to_private,
+					  bool for_cap);
 int kvm_gmem_apply_content_mode_zero(struct inode *inode, pgoff_t start,
 				     pgoff_t end);
 int kvm_arch_gmem_apply_content_mode_zero(struct kvm *kvm, struct inode *inode,
@@ -2551,6 +2552,14 @@ static inline u64 kvm_supported_mem_attributes(struct kvm *kvm)
 	return 0;
 }
 
+static inline u64 kvm_supported_set_mem_attributes2_flags(struct kvm *kvm)
+{
+	if (!IS_ENABLED(CONFIG_KVM_GUEST_MEMFD))
+		return 0;
+
+	return kvm_arch_gmem_supported_content_modes(kvm, false, true);
+}
+
 typedef unsigned long (kvm_get_memory_attributes_t)(struct kvm *kvm, gfn_t gfn);
 DECLARE_STATIC_CALL(__kvm_get_memory_attributes, kvm_get_memory_attributes_t);
 
diff --git a/include/uapi/linux/kvm.h b/include/uapi/linux/kvm.h
index c7cc6c22c2023..c0d465a5577da 100644
--- a/include/uapi/linux/kvm.h
+++ b/include/uapi/linux/kvm.h
@@ -997,6 +997,7 @@ struct kvm_enable_cap {
 #define KVM_CAP_S390_KEYOP 247
 #define KVM_CAP_S390_VSIE_ESAMODE 248
 #define KVM_CAP_GUEST_MEMFD_MEMORY_ATTRIBUTES 249
+#define KVM_CAP_MEMORY_ATTRIBUTES2_FLAGS 250
 
 struct kvm_irq_routing_irqchip {
 	__u32 irqchip;
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 5c1db67e6fd35..071bf636ba5c0 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -693,7 +693,8 @@ static void kvm_gmem_invalidate(struct inode *inode, pgoff_t start, pgoff_t end)
 static void kvm_gmem_invalidate(struct inode *inode, pgoff_t start, pgoff_t end) {}
 #endif
 
-u64 __weak kvm_arch_gmem_supported_content_modes(struct kvm *kvm, bool to_private)
+u64 __weak kvm_arch_gmem_supported_content_modes(struct kvm *kvm,
+						 bool to_private, bool for_cap)
 {
 	/* Architectures must override with supported modes. */
 	return 0;
@@ -709,7 +710,8 @@ static bool kvm_gmem_content_mode_is_supported(struct kvm *kvm,
 	if (content_mode == KVM_SET_MEMORY_ATTRIBUTES2_ZERO && to_private)
 		return false;
 
-	return kvm_arch_gmem_supported_content_modes(kvm, to_private) & content_mode;
+	return kvm_arch_gmem_supported_content_modes(kvm, to_private, false) &
+	       content_mode;
 }
 
 int kvm_gmem_apply_content_mode_zero(struct inode *inode, pgoff_t start,
diff --git a/virt/kvm/kvm_main.c b/virt/kvm/kvm_main.c
index 3bf212fd99193..9fa6ecebab939 100644
--- a/virt/kvm/kvm_main.c
+++ b/virt/kvm/kvm_main.c
@@ -4979,6 +4979,11 @@ static int kvm_vm_ioctl_check_extension_generic(struct kvm *kvm, long arg)
 			return 0;
 
 		return kvm_supported_mem_attributes(kvm);
+	case KVM_CAP_MEMORY_ATTRIBUTES2_FLAGS:
+		if (vm_memory_attributes)
+			return 0;
+
+		return kvm_supported_set_mem_attributes2_flags(kvm);
 #endif
 	default:
 		break;

-- 
2.54.0.545.g6539524ca2-goog

