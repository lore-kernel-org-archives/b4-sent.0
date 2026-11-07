From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:27 -0800
Subject: [PATCH RFC v3 53/88] KVM: guest_memfd: Support
 check_set_attributes provider operation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-53-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=3677;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=4/4nca6vwG0g+Wn7pJHbmNNbLNupPdnyAc+KxS+ZWuk=;
 b=4XLQVntDynKX6Hg61os4N4mZ/7bH7llDByPzeK1+3F1ZkrFt6ryuxsC2lG0iwgffcbuQmL9lt
 ubm7if6Rr/sAdM97hG/ER6jDIEJ3FeCcV39rg4Ept71S/oiS0BHnOZR
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow memory providers to validate or reject attribute changes on a
range of memory offsets before they are committed.

Add an optional .check_set_attributes callback to struct
guest_memfd_provider_operations returning an int error code, and invoke
it via gmem_provider_check_set_attributes() under the exclusive filemap
invalidation lock before preallocating maple tree entries or unmapping
userspace mappings. If the provider rejects the attribute change with an
error, fail the ioctl with that error code and report the error index
back to userspace.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/linux/guest_memfd.h | 12 ++++++++++++
 virt/kvm/guest_memfd.c      | 16 ++++++++++++++++
 2 files changed, 28 insertions(+)

diff --git a/include/linux/guest_memfd.h b/include/linux/guest_memfd.h
index a2af279cd3c34..cd634576c9af8 100644
--- a/include/linux/guest_memfd.h
+++ b/include/linux/guest_memfd.h
@@ -88,6 +88,16 @@ static inline bool kvm_gmem_pfn_is_cacheable(u64 pfn_attrs)
  * @mmap: Optional callback to set up user mappings. Called when userspace calls
  *        mmap() on guest_memfd. The provider can customize VMA flags, or reject
  *        the mapping.
+ * @check_set_attributes: Optional callback to validate attribute changes on a
+ *                        range of indices before they are committed. Called
+ *                        with the exclusive filemap invalidate lock held. The
+ *                        provider can inspect the requested attributes and
+ *                        offset range and return 0 to allow the transition or
+ *                        a negative error code (e.g. -EINVAL or -EPERM) to
+ *                        reject it. Once @check_set_attributes succeeds, the
+ *                        provider must ensure this result stays valid and
+ *                        constant until guest_memfd stops using the range. Do
+ *                        not take locks held across kvm_gmem_revoke().
  *
  * Used by filesystems and device drivers that provide memory for guest_memfd.
  */
@@ -103,6 +113,8 @@ struct guest_memfd_provider_operations {
 				unsigned long *pfn, size_t *nr_pages);
 	void (*put_pfn_range)(void *provider, pgoff_t index, size_t nr_pages);
 	int (*mmap)(void *provider, struct vm_area_struct *vma);
+	int (*check_set_attributes)(void *provider, pgoff_t index,
+				    size_t nr_pages, u64 attributes);
 };
 
 #ifdef CONFIG_KVM_GUEST_MEMFD
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index ec908419e5faa..61a3ff7fcd84c 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -210,6 +210,16 @@ static int gmem_provider_mmap(struct gmem_inode *gi, struct vm_area_struct *vma)
 	return 0;
 }
 
+static int gmem_provider_check_set_attributes(struct gmem_inode *gi, pgoff_t index,
+					      size_t nr_pages, u64 attributes)
+{
+	if (gi->provider_ops && gi->provider_ops->check_set_attributes)
+		return gi->provider_ops->check_set_attributes(gi->provider, index,
+							      nr_pages, attributes);
+
+	return 0;
+}
+
 #define kvm_gmem_for_each_file(f, inode) \
 	list_for_each_entry(f, &GMEM_I(inode)->gmem_file_list, entry)
 
@@ -1083,6 +1093,12 @@ static int __kvm_gmem_set_attributes(struct inode *inode, pgoff_t start,
 	if (kvm_gmem_range_has_attributes(inode, start, nr_pages, attrs))
 		goto out;
 
+	r = gmem_provider_check_set_attributes(gi, start, nr_pages, attrs);
+	if (r) {
+		*err_index = start;
+		goto out;
+	}
+
 	mas_init(&mas, mt, start);
 	r = kvm_gmem_mas_preallocate(&mas, attrs, start, nr_pages);
 	if (r) {

-- 
2.56.0.455.g6c5a503b38-goog

