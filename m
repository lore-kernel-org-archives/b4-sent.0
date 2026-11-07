From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:39 -0800
Subject: [PATCH RFC v3 05/88] KVM: guest_memfd: Support using resource
 provider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-5-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=7993;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=+trcMG1AkUVLV5DTgtPr8oTB3iyi5IEbhg5RcJXjFzo=;
 b=CjjglONW/K86yi9bpPILRg7xwdCCcNCuzvlDIXTENgJflyOKaSJ7CATnoA9BUXoQbKXlTMhrd
 jTV8aEEZYpACo2HVgiFWfXPxelh0W8DZFIOJIuXxpl7Lk9zXDVst8cA
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A refcount on the resource_fd is taken only to keep the reference stable
for guest_memfd to figure out the existence of a provider. The provider is
responsible for pinning anything required to keep the provider's ops and
the actual provided resource alive.

.release() is called when this guest_memfd inode is destroyed to allow the
provider to clean up.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/virt/kvm/api.rst | 28 +++++++++++++++++----------
 include/linux/kvm_host.h       |  2 +-
 include/uapi/linux/kvm.h       |  5 ++++-
 virt/kvm/guest_memfd.c         | 44 ++++++++++++++++++++++++++++++++++--------
 4 files changed, 59 insertions(+), 20 deletions(-)

diff --git a/Documentation/virt/kvm/api.rst b/Documentation/virt/kvm/api.rst
index e95c9cda085d9..9f5313d405d9c 100644
--- a/Documentation/virt/kvm/api.rst
+++ b/Documentation/virt/kvm/api.rst
@@ -6486,7 +6486,9 @@ and cannot be resized  (guest_memfd files do however support PUNCH_HOLE).
   struct kvm_create_guest_memfd {
 	__u64 size;
 	__u64 flags;
-	__u64 reserved[6];
+	__s32 resource_fd;
+	__u32 pad;
+	__u64 reserved[5];
   };
 
 Conceptually, the inode backing a guest_memfd file represents physical memory,
@@ -6508,15 +6510,21 @@ a single guest_memfd file, but the bound ranges must not overlap).
 The capability KVM_CAP_GUEST_MEMFD_FLAGS enumerates the `flags` that can be
 specified via KVM_CREATE_GUEST_MEMFD.  Currently defined flags:
 
-  ============================ ================================================
-  GUEST_MEMFD_FLAG_MMAP        Enable using mmap() on the guest_memfd file
-                               descriptor.
-  GUEST_MEMFD_FLAG_INIT_SHARED Make all memory in the file shared during
-                               KVM_CREATE_GUEST_MEMFD (memory files created
-                               without INIT_SHARED will be marked private).
-                               Shared memory can be faulted into host userspace
-                               page tables. Private memory cannot.
-  ============================ ================================================
+  ============================= ================================================
+  GUEST_MEMFD_FLAG_MMAP         Enable using mmap() on the guest_memfd file
+                                descriptor.
+  GUEST_MEMFD_FLAG_INIT_SHARED  Make all memory in the file shared during
+                                KVM_CREATE_GUEST_MEMFD (memory files created
+                                without INIT_SHARED will be marked private).
+                                Shared memory can be faulted into host userspace
+                                page tables. Private memory cannot.
+  GUEST_MEMFD_FLAG_USE_RESOURCE Consume resource_fd as an external memory
+                                provider or resource pool. When not set,
+                                resource_fd must be '0'. When set, the provider
+                                must be a supported resource (e.g. tmpfs mount
+                                root directory). Currently, tmpfs resource pools
+                                require noswap and huge=never mount options.
+  ============================= ================================================
 
 When the KVM MMU performs a PFN lookup to service a guest fault, the fault will
 always be consumed from guest_memfd, regardless of whether it is a shared or a
diff --git a/include/linux/kvm_host.h b/include/linux/kvm_host.h
index e7fc94e2910a8..d820afac49252 100644
--- a/include/linux/kvm_host.h
+++ b/include/linux/kvm_host.h
@@ -2618,7 +2618,7 @@ bool kvm_arch_supports_gmem_init_shared(struct kvm *kvm);
 
 static inline u64 kvm_gmem_get_supported_flags(struct kvm *kvm)
 {
-	u64 flags = GUEST_MEMFD_FLAG_MMAP;
+	u64 flags = GUEST_MEMFD_FLAG_MMAP | GUEST_MEMFD_FLAG_USE_RESOURCE;
 
 	if (!kvm || kvm_arch_supports_gmem_init_shared(kvm))
 		flags |= GUEST_MEMFD_FLAG_INIT_SHARED;
diff --git a/include/uapi/linux/kvm.h b/include/uapi/linux/kvm.h
index 8dff2fc1972e9..f4108bf7e3192 100644
--- a/include/uapi/linux/kvm.h
+++ b/include/uapi/linux/kvm.h
@@ -1674,11 +1674,14 @@ struct kvm_memory_attributes2 {
 #define KVM_CREATE_GUEST_MEMFD	_IOWR(KVMIO,  0xd4, struct kvm_create_guest_memfd)
 #define GUEST_MEMFD_FLAG_MMAP		(1ULL << 0)
 #define GUEST_MEMFD_FLAG_INIT_SHARED	(1ULL << 1)
+#define GUEST_MEMFD_FLAG_USE_RESOURCE	(1ULL << 2)
 
 struct kvm_create_guest_memfd {
 	__u64 size;
 	__u64 flags;
-	__u64 reserved[6];
+	__s32 resource_fd;
+	__u32 pad;
+	__u64 reserved[5];
 };
 
 #define KVM_PRE_FAULT_MEMORY	_IOWR(KVMIO, 0xd5, struct kvm_pre_fault_memory)
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index ee823f2ef0368..84877beed6701 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -85,15 +85,26 @@ static const struct guest_memfd_provider_operations gmem_native_provider_ops = {
 static int kvm_gmem_attach_resource(struct inode *inode, int resource_fd)
 {
 	const struct guest_memfd_provider_operations *ops = NULL;
+	void *provider = ERR_PTR(-EOPNOTSUPP);
 	struct file *resource_file = NULL;
-	void *provider;
 
-	if (resource_fd == GMEM_RESOURCE_FD_NATIVE)
+	if (resource_fd == GMEM_RESOURCE_FD_NATIVE) {
 		ops = &gmem_native_provider_ops;
-	else
-		return -EOPNOTSUPP;
+	} else {
+		resource_file = fget_raw(resource_fd);
+		if (!resource_file)
+			return -EBADF;
+
+		if (resource_file->f_op)
+			ops = resource_file->f_op->gmem_provider_ops;
+	}
+
+	if (ops && ops->attach && ops->alloc_folio)
+		provider = ops->attach(inode, resource_file);
+
+	if (resource_file)
+		fput(resource_file);
 
-	provider = ops->attach(inode, resource_file);
 	if (IS_ERR(provider))
 		return PTR_ERR(provider);
 
@@ -120,6 +131,12 @@ static void gmem_provider_invalidate_folio(struct gmem_inode *gi,
 		gi->provider_ops->invalidate_folio(gi->provider, folio);
 }
 
+static void gmem_provider_release(struct gmem_inode *gi)
+{
+	if (gi->provider_ops && gi->provider_ops->release)
+		gi->provider_ops->release(gi->provider);
+}
+
 #define kvm_gmem_for_each_file(f, inode) \
 	list_for_each_entry(f, &GMEM_I(inode)->gmem_file_list, entry)
 
@@ -1033,7 +1050,7 @@ static int kvm_gmem_init_inode(struct inode *inode, loff_t size, u64 flags)
 	return r;
 }
 
-static int __kvm_gmem_create(struct kvm *kvm, loff_t size, u64 flags)
+static int __kvm_gmem_create(struct kvm *kvm, loff_t size, u64 flags, int resource_fd)
 {
 	static const char *name = "[kvm-gmem]";
 	struct gmem_file *f;
@@ -1088,7 +1105,7 @@ static int __kvm_gmem_create(struct kvm *kvm, loff_t size, u64 flags)
 	 */
 	smp_wmb();
 
-	err = kvm_gmem_attach_resource(inode, GMEM_RESOURCE_FD_NATIVE);
+	err = kvm_gmem_attach_resource(inode, resource_fd);
 	if (err) {
 		fput(file);
 		put_unused_fd(fd);
@@ -1111,6 +1128,7 @@ static int __kvm_gmem_create(struct kvm *kvm, loff_t size, u64 flags)
 
 int kvm_gmem_create(struct kvm *kvm, struct kvm_create_guest_memfd *args)
 {
+	int resource_fd = GMEM_RESOURCE_FD_NATIVE;
 	loff_t size = args->size;
 	u64 flags = args->flags;
 
@@ -1120,7 +1138,15 @@ int kvm_gmem_create(struct kvm *kvm, struct kvm_create_guest_memfd *args)
 	if (size <= 0 || !PAGE_ALIGNED(size))
 		return -EINVAL;
 
-	return __kvm_gmem_create(kvm, size, flags);
+	if (flags & GUEST_MEMFD_FLAG_USE_RESOURCE) {
+		if (args->resource_fd < 0)
+			return -EBADF;
+		resource_fd = args->resource_fd;
+	} else if (args->resource_fd) {
+		return -EINVAL;
+	}
+
+	return __kvm_gmem_create(kvm, size, flags, resource_fd);
 }
 
 int kvm_gmem_prepare_memory_region(struct kvm *kvm, struct kvm_memory_slot *slot,
@@ -1464,6 +1490,8 @@ static void kvm_gmem_destroy_inode(struct inode *inode)
 {
 	struct gmem_inode *gi = GMEM_I(inode);
 
+	gmem_provider_release(gi);
+
 	mpol_free_shared_policy(&gi->policy);
 
 	/*

-- 
2.56.0.455.g6c5a503b38-goog

