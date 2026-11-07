From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:26 -0800
Subject: [PATCH RFC v3 52/88] KVM: guest_memfd: Support mmap provider
 operation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-52-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=3134;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=S8Nn9NlzC19FEsDW/4vv5XCK3el09MMI9122tikd9N0=;
 b=qFWCP9ocy+CJAo1wAx8I62v4m4/bwjbD4jcoXy8lKZE5NFzAeR2EgcdTl2MSl1EOSgIt9Z528
 Mu3iaaYc/xFBJic9zQXSjuIt0XgQbALEABnfwb9x54IpphtX+CXdJLk
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow memory providers to customize VMA setup when userspace creates a
shared mapping on a guest_memfd file.

Add an optional .mmap callback to struct guest_memfd_provider_operations
and invoke it via gmem_provider_mmap() during mmap handling on
guest_memfd descriptors. If the provider does not define .mmap,
gmem_provider_mmap() simply returns 0.

Invoke the provider callback before setting VM_PFNMAP and guest_memfd
VMA operations so that PFN mode mappings always have VM_PFNMAP set and
remain mediated by guest_memfd fault handling even if the provider omits
the callback or configures its own VMA flags and operations.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/linux/guest_memfd.h |  4 ++++
 virt/kvm/guest_memfd.c      | 13 +++++++++++++
 2 files changed, 17 insertions(+)

diff --git a/include/linux/guest_memfd.h b/include/linux/guest_memfd.h
index 8cdc334d1c9aa..a2af279cd3c34 100644
--- a/include/linux/guest_memfd.h
+++ b/include/linux/guest_memfd.h
@@ -85,6 +85,9 @@ static inline bool kvm_gmem_pfn_is_cacheable(u64 pfn_attrs)
  *                 available, the provider should skip the unbacked range. Not
  *                 called on kvm_gmem_revoke(). Do not take locks held across
  *                 kvm_gmem_revoke().
+ * @mmap: Optional callback to set up user mappings. Called when userspace calls
+ *        mmap() on guest_memfd. The provider can customize VMA flags, or reject
+ *        the mapping.
  *
  * Used by filesystems and device drivers that provide memory for guest_memfd.
  */
@@ -99,6 +102,7 @@ struct guest_memfd_provider_operations {
 	int (*lookup_pfn_range)(void *provider, pgoff_t index,
 				unsigned long *pfn, size_t *nr_pages);
 	void (*put_pfn_range)(void *provider, pgoff_t index, size_t nr_pages);
+	int (*mmap)(void *provider, struct vm_area_struct *vma);
 };
 
 #ifdef CONFIG_KVM_GUEST_MEMFD
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 1fbb719f0e31f..ec908419e5faa 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -202,6 +202,14 @@ static void gmem_provider_release(struct gmem_inode *gi)
 		gi->provider_ops->release(gi->provider);
 }
 
+static int gmem_provider_mmap(struct gmem_inode *gi, struct vm_area_struct *vma)
+{
+	if (gi->provider_ops && gi->provider_ops->mmap)
+		return gi->provider_ops->mmap(gi->provider, vma);
+
+	return 0;
+}
+
 #define kvm_gmem_for_each_file(f, inode) \
 	list_for_each_entry(f, &GMEM_I(inode)->gmem_file_list, entry)
 
@@ -860,6 +868,7 @@ static const struct vm_operations_struct kvm_gmem_pfn_vm_ops = {
 static int kvm_gmem_mmap(struct file *file, struct vm_area_struct *vma)
 {
 	struct gmem_inode *gi = GMEM_I(file_inode(file));
+	int ret;
 
 	if (!kvm_gmem_supports_mmap(file_inode(file)))
 		return -ENODEV;
@@ -869,6 +878,10 @@ static int kvm_gmem_mmap(struct file *file, struct vm_area_struct *vma)
 		return -EINVAL;
 	}
 
+	ret = gmem_provider_mmap(gi, vma);
+	if (ret)
+		return ret;
+
 	if (kvm_gmem_is_pfn_mode(gi))
 		vm_flags_set(vma, VM_PFNMAP);
 

-- 
2.56.0.455.g6c5a503b38-goog

