From: Ackerley Tng <ackerleytng@google.com>
Date: Tue, 28 Apr 2026 16:25:21 -0700
Subject: [PATCH RFC v5 26/53] KVM: x86: Support SNP and TDX applying
 content modes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-gmem-inplace-conversion-v5-26-d8608ccfca22@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777418714; l=4286;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=i6q4uvrNtDgNcr9CUmAU4UKURJOJAI1o/insHn6kLI8=;
 b=foRZV+tCQRN2/9dqQLMIWhiR8IkHAAal9ueWWCez/CvrtzIdOAsEjakqSz8gPfly9NNY9T4yW
 o8g90xsHHZlBcopXzRcG+cTT1Wpw3RzkLcw9qlFNF/cbBuXd7+GBfv/
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Define supported content modes for TDX and SNP.

For now, content preservation is not generally supported for conversions.

Allow conversion only from shared to private before the VM is finalized to
support this VM set up flow from userspace:

1. Set up guest_memfd as shared.
2. Write directly to guest_memfd.
3. Set memory attributes to private with the PRESERVE flag
4. Call KVM_TDX_INIT_MEM_REGION/KVM_SEV_SNP_LAUNCH_UPDATE to load and
   encrypt memory

An alternative would be to the work done by the kernel in step 3 into 4,
but the process of conversion is complicated (needs to check refcounts,
handle failures, etc) and plumbing the errors out through the
platform-specific ioctl is complex and pollutes the platform-specific
ioctl.

Allow conversion with content preservation only to_private since preserving
content on a to-shared conversion after population cannot be supported.

Suggested-by: Sean Christopherson <seanjc@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
Co-developed-by: Michael Roth <michael.roth@amd.com>
Signed-off-by: Michael Roth <michael.roth@amd.com>
---
 Documentation/virt/kvm/api.rst |  3 +++
 arch/x86/kvm/x86.c             | 38 ++++++++++++++++++++++++++++++++++++++
 2 files changed, 41 insertions(+)

diff --git a/Documentation/virt/kvm/api.rst b/Documentation/virt/kvm/api.rst
index 61b9974ba52e9..aaa4a82f0b75d 100644
--- a/Documentation/virt/kvm/api.rst
+++ b/Documentation/virt/kvm/api.rst
@@ -6659,6 +6659,9 @@ The content modes available are as follows:
   converts the memory to shared, the host (and guest) will read
   ``0xbeef`` (if the memory is accessible).
 
+  For TDX and SNP, content preservation is only supported before the
+  VM is finalized, and only on conversion to private.
+
 Note: These content modes apply to the entire requested range, not
 just the parts of the range that underwent conversion. For example, if
 this was the initial state:
diff --git a/arch/x86/kvm/x86.c b/arch/x86/kvm/x86.c
index e8abff71001eb..296ed3b8ace6c 100644
--- a/arch/x86/kvm/x86.c
+++ b/arch/x86/kvm/x86.c
@@ -14206,6 +14206,32 @@ u64 kvm_arch_gmem_supported_content_modes(struct kvm *kvm, bool to_private)
 	case KVM_X86_SW_PROTECTED_VM:
 		return KVM_SET_MEMORY_ATTRIBUTES2_ZERO |
 		       KVM_SET_MEMORY_ATTRIBUTES2_PRESERVE;
+	case KVM_X86_SNP_VM:
+	case KVM_X86_TDX_VM: {
+		u64 supported = KVM_SET_MEMORY_ATTRIBUTES2_ZERO;
+
+		/*
+		 * Preservation is only supported for VMs with
+		 * protected state up until the guest is launched and
+		 * vCPUs become capable of generating KVM MMU faults,
+		 * since those faults can be destructive to the
+		 * initial memory contents from the guest point of
+		 * view, i.e. plaintext data will become random data,
+		 * or zeroed, after a shared->private conversion.
+		 *
+		 * Use pre_fault_allowed to guard PRESERVE support,
+		 * since that is set to true when VMs are finalized.
+		 *
+		 * Along the same lines, only support PRESERVE for
+		 * to_private conversions, since when converting to
+		 * shared, memory contents for pages that had already
+		 * been faulted could be zeroed.
+		 */
+		if (to_private && !kvm->arch.pre_fault_allowed)
+			supported |= KVM_SET_MEMORY_ATTRIBUTES2_PRESERVE;
+
+		return supported;
+	}
 	default:
 		return 0;
 	}
@@ -14216,6 +14242,16 @@ int kvm_arch_gmem_apply_content_mode_zero(struct kvm *kvm, struct inode *inode,
 {
 	switch (kvm->arch.vm_type) {
 	case KVM_X86_SW_PROTECTED_VM:
+	case KVM_X86_SNP_VM:
+	case KVM_X86_TDX_VM:
+		/*
+		 * TDX firmware will zero on unmapping from the
+		 * Secure-EPTs, but suppose a shared page with
+		 * contents was converted to private, and then
+		 * converted back without ever being mapped into
+		 * Secure-EPTs: guest_memfd can't rely on TDX firmware
+		 * for zeroing then.
+		 */
 		return kvm_gmem_apply_content_mode_zero(inode, start, end);
 	default:
 		return 0;
@@ -14228,6 +14264,8 @@ int kvm_arch_gmem_apply_content_mode_preserve(struct kvm *kvm,
 {
 	switch (kvm->arch.vm_type) {
 	case KVM_X86_SW_PROTECTED_VM:
+	case KVM_X86_SNP_VM:
+	case KVM_X86_TDX_VM:
 		/* Do nothing to preserve content. */
 		return 0;
 	default:

-- 
2.54.0.545.g6539524ca2-goog

