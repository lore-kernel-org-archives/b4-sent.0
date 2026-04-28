From: Ackerley Tng <ackerleytng@google.com>
Date: Tue, 28 Apr 2026 16:25:17 -0700
Subject: [PATCH RFC v5 22/53] KVM: guest_memfd: Apply content modes while
 setting memory attributes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-gmem-inplace-conversion-v5-22-d8608ccfca22@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777418714; l=8609;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=MUDFg3cF6c9zZj9eh+GrJ3J5VFbXgeIVHlW3jinLVHw=;
 b=2XGqE3iV+Vi1bSn0hlNODYxtik3QyF9m9aUmkOk9DiJ6SyFSFBLsOf07/9slTvV8WlFojh1kw
 cm5zpBbGFbjByQhM6jLEcwU3cELZfDgCodbO76TBbTHf8UHrktag1mF
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Provide defined memory content modes so that KVM can make guarantees about
memory content after setting memory attributes, according to userspace
requests.

Suggested-by: Sean Christoperson <seanjc@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/virt/kvm/api.rst | 61 ++++++++++++++++++++++++++++++++++++++++++
 include/uapi/linux/kvm.h       |  4 +++
 virt/kvm/guest_memfd.c         | 56 ++++++++++++++++++++++++++++++++++++--
 3 files changed, 119 insertions(+), 2 deletions(-)

diff --git a/Documentation/virt/kvm/api.rst b/Documentation/virt/kvm/api.rst
index 6ce10c8ddb634..61b9974ba52e9 100644
--- a/Documentation/virt/kvm/api.rst
+++ b/Documentation/virt/kvm/api.rst
@@ -6573,6 +6573,8 @@ Errors:
   EAGAIN     Some page within requested range had unexpected refcounts. The
              offset of the page will be returned in `error_offset`.
   ENOMEM     Ran out of memory trying to track private/shared state
+  EOPNOTSUPP There is no way for KVM to guarantee in-memory contents as
+             requested.
   ========== ===============================================================
 
 KVM_SET_MEMORY_ATTRIBUTES2 is an extension to
@@ -6621,6 +6623,65 @@ on the shared pages, such as refcounts taken by get_user_pages(), and
 try the ioctl again. A possible source of these long term refcounts is
 if the guest_memfd memory was pinned in IOMMU page tables.
 
+By default, KVM makes no guarantees about the in-memory values after
+memory is convert to/from shared/private.  Optionally, userspace may
+instruct KVM to ensure the contents of memory are zeroed or preserved,
+e.g. to enable in-place sharing of data, or as an optimization to
+avoid having to re-zero memory when userspace could have relied on the
+trusted entity to guarantee the memory will be zeroed as part of the
+entire conversion process.
+
+The content modes available are as follows:
+
+``KVM_SET_MEMORY_ATTRIBUTES2_ZERO``
+
+  On conversion, KVM guarantees all entities that have "allowed"
+  access to the memory will read zeros.  E.g. on private to shared
+  conversion, both trusted and untrusted code will read zeros.
+
+  Zeroing is currently only supported for private-to-shared
+  conversions, as KVM in general is untrusted and thus cannot
+  guarantee the guest (or any trusted entity) will read zeros after
+  conversion.  Note, some CoCo implementations do zero memory contents
+  such that the guest reads zeros after conversion, and the guest may
+  choose to rely on that behavior.  However, that's a contract between
+  the trusted CoCo entity and the guest, not between KVM and the
+  guest.
+
+``KVM_SET_MEMORY_ATTRIBUTES2_PRESERVE``
+
+  On conversion, KVM guarantees memory contents will be preserved with
+  respect to the last written unencrypted value.  As a concrete
+  example, if the host writes ``0xbeef`` to shared memory and converts
+  the memory to private, the guest will also read ``0xbeef``, even if
+  the in-memory data is encrypted as part of the conversion.  And vice
+  versa, if the guest writes ``0xbeef`` to private memory and then
+  converts the memory to shared, the host (and guest) will read
+  ``0xbeef`` (if the memory is accessible).
+
+Note: These content modes apply to the entire requested range, not
+just the parts of the range that underwent conversion. For example, if
+this was the initial state:
+
+  * [0x0000, 0x1000): shared
+  * [0x1000, 0x2000): private
+  * [0x2000, 0x3000): shared
+
+and range [0x0000, 0x3000) was set to shared, the content mode would
+apply to all memory in [0x0000, 0x3000), not just the range that
+underwent conversion [0x1000, 0x2000).
+
+Note: These content modes apply only to allocated memory. No
+guarantees are made on offset ranges that do not have memory allocated
+(yet). For example, if this was the initial state:
+
+  * [0x0000, 0x1000): shared
+  * [0x1000, 0x2000): not allocated
+  * [0x2000, 0x3000): shared
+
+and range [0x0000, 0x3000) was set to shared, the content mode would
+apply to only to offset ranges [0x0000, 0x1000) and [0x2000, 0x3000).
+
 See also: :ref: `KVM_SET_MEMORY_ATTRIBUTES`.
 
 .. _kvm_run:
diff --git a/include/uapi/linux/kvm.h b/include/uapi/linux/kvm.h
index f437fd0f1350c..c7cc6c22c2023 100644
--- a/include/uapi/linux/kvm.h
+++ b/include/uapi/linux/kvm.h
@@ -1652,6 +1652,10 @@ struct kvm_memory_attributes {
 /* Available with KVM_CAP_GUEST_MEMFD_MEMORY_ATTRIBUTES */
 #define KVM_SET_MEMORY_ATTRIBUTES2              _IOWR(KVMIO,  0xd2, struct kvm_memory_attributes2)
 
+#define KVM_SET_MEMORY_ATTRIBUTES2_MODE_UNSPECIFIED	0
+#define KVM_SET_MEMORY_ATTRIBUTES2_ZERO		(1ULL << 0)
+#define KVM_SET_MEMORY_ATTRIBUTES2_PRESERVE	(1ULL << 1)
+
 struct kvm_memory_attributes2 {
 	union {
 		__u64 address;
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index b0e4bb554cdf3..5c1db67e6fd35 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -699,6 +699,19 @@ u64 __weak kvm_arch_gmem_supported_content_modes(struct kvm *kvm, bool to_privat
 	return 0;
 }
 
+static bool kvm_gmem_content_mode_is_supported(struct kvm *kvm,
+					       u64 content_mode,
+					       bool to_private)
+{
+	if (content_mode == KVM_SET_MEMORY_ATTRIBUTES2_MODE_UNSPECIFIED)
+		return true;
+
+	if (content_mode == KVM_SET_MEMORY_ATTRIBUTES2_ZERO && to_private)
+		return false;
+
+	return kvm_arch_gmem_supported_content_modes(kvm, to_private) & content_mode;
+}
+
 int kvm_gmem_apply_content_mode_zero(struct inode *inode, pgoff_t start,
 				     pgoff_t end)
 {
@@ -759,8 +772,26 @@ int __weak kvm_arch_gmem_apply_content_mode_preserve(struct kvm *kvm,
 	return -EOPNOTSUPP;
 }
 
+static int kvm_gmem_apply_content_mode(struct kvm *kvm, uint64_t content_mode,
+				       struct inode *inode, pgoff_t start,
+				       pgoff_t end)
+{
+	switch (content_mode) {
+	case KVM_SET_MEMORY_ATTRIBUTES2_MODE_UNSPECIFIED:
+		return kvm_arch_gmem_apply_content_mode_unspecified(kvm, inode, start, end);
+	case KVM_SET_MEMORY_ATTRIBUTES2_ZERO:
+		return kvm_arch_gmem_apply_content_mode_zero(kvm, inode, start, end);
+	case KVM_SET_MEMORY_ATTRIBUTES2_PRESERVE:
+		return kvm_arch_gmem_apply_content_mode_preserve(kvm, inode, start, end);
+	default:
+		WARN_ONCE(1, "Unexpected policy requested.");
+		return -EOPNOTSUPP;
+	}
+}
+
 static int __kvm_gmem_set_attributes(struct inode *inode, pgoff_t start,
 				     size_t nr_pages, uint64_t attrs,
+				     struct kvm *kvm, uint64_t content_mode,
 				     pgoff_t *err_index)
 {
 	bool to_private = attrs & KVM_MEMORY_ATTRIBUTE_PRIVATE;
@@ -775,7 +806,21 @@ static int __kvm_gmem_set_attributes(struct inode *inode, pgoff_t start,
 
 	filemap_invalidate_lock(mapping);
 
+	if (!kvm_gmem_content_mode_is_supported(kvm, content_mode,
+						to_private)) {
+		r = -EOPNOTSUPP;
+		*err_index = start;
+		goto out;
+	}
+
 	if (kvm_gmem_range_has_attributes(mt, start, nr_pages, attrs)) {
+		/*
+		 * Even if no update is required to attributes, the
+		 * requested content mode is applied.
+		 */
+		WARN_ON(kvm_gmem_apply_content_mode(kvm, content_mode,
+						    inode, start, end));
+
 		r = 0;
 		goto out;
 	}
@@ -808,6 +853,9 @@ static int __kvm_gmem_set_attributes(struct inode *inode, pgoff_t start,
 	if (!to_private)
 		kvm_gmem_invalidate(inode, start, end);
 
+	WARN_ON(kvm_gmem_apply_content_mode(kvm, content_mode, inode,
+					    start, end));
+
 	mas_store_prealloc(&mas, xa_mk_value(attrs));
 
 	kvm_gmem_invalidate_end(inode, start, end);
@@ -829,7 +877,11 @@ static long kvm_gmem_set_attributes(struct file *file, void __user *argp)
 	if (copy_from_user(&attrs, argp, sizeof(attrs)))
 		return -EFAULT;
 
-	if (attrs.flags)
+	if (attrs.flags & ~(KVM_SET_MEMORY_ATTRIBUTES2_ZERO |
+			    KVM_SET_MEMORY_ATTRIBUTES2_PRESERVE))
+		return -EINVAL;
+	if ((attrs.flags & KVM_SET_MEMORY_ATTRIBUTES2_ZERO) &&
+	    (attrs.flags & KVM_SET_MEMORY_ATTRIBUTES2_PRESERVE))
 		return -EINVAL;
 	for (i = 0; i < ARRAY_SIZE(attrs.reserved); i++) {
 		if (attrs.reserved[i])
@@ -849,7 +901,7 @@ static long kvm_gmem_set_attributes(struct file *file, void __user *argp)
 	nr_pages = attrs.size >> PAGE_SHIFT;
 	index = attrs.offset >> PAGE_SHIFT;
 	r = __kvm_gmem_set_attributes(inode, index, nr_pages, attrs.attributes,
-				      &err_index);
+				      f->kvm, attrs.flags, &err_index);
 	if (r) {
 		attrs.error_offset = ((uint64_t)err_index) << PAGE_SHIFT;
 

-- 
2.54.0.545.g6539524ca2-goog

