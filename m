From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:13 -0800
Subject: [PATCH RFC v3 39/88] KVM: guest_memfd: Support put_pfn_range
 provider op in PFN mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-39-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=3807;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=4/hbHbxMiZ7tJ/EDsUOTijR3o3N5MOrwP4iwQrovXOg=;
 b=wEgX7S15CuxNocEJ8imeNb1DKOtdXWIeo5BKhw7JB1HIucbwA5tWqkgNHuEBrNHN9EmXUaOGf
 qC33A9oFGreC5TF8gaEGBO+NelsJof7bFPo9Hm4/kvO1bco1qCxhRPQ
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When punching holes or destroying guest_memfd files in folio mode,
folios are truncated and freed, allowing the backing filesystem to free
or reset memory.

In PFN mode, memory is not backed by page cache folios. To inform the
provider that a physical range has been released by guest_memfd,
introduce the .put_pfn_range callback to struct
guest_memfd_provider_operations.

Invoke .put_pfn_range() after kvm_gmem_pfn_reclaim() during both hole
punching and inode destruction, passing the file index and page count.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/linux/guest_memfd.h |  7 +++++++
 virt/kvm/guest_memfd.c      | 16 ++++++++++++++--
 2 files changed, 21 insertions(+), 2 deletions(-)

diff --git a/include/linux/guest_memfd.h b/include/linux/guest_memfd.h
index e965aeca061a6..697f8f8c9b0ae 100644
--- a/include/linux/guest_memfd.h
+++ b/include/linux/guest_memfd.h
@@ -44,6 +44,12 @@ struct mempolicy;
  *                    starting from @index that have no entry. Return a negative
  *                    error code on other failure. The provider must define
  *                    @get_pfn when @lookup_pfn_range is defined.
+ * @put_pfn_range: Release a range of PFNs previously obtained for a given
+ *                 index. Called with the exclusive filemap invalidate lock held.
+ *                 This indicates to the provider that guest_memfd is no longer
+ *                 using the memory range. The provider does not need to ensure
+ *                 that backing memory is present; if backing memory is not
+ *                 available, the provider should skip the unbacked range.
  *
  * Used by filesystems and device drivers that provide memory for guest_memfd.
  */
@@ -57,6 +63,7 @@ struct guest_memfd_provider_operations {
 		       int *max_order, u64 *pfn_attrs);
 	int (*lookup_pfn_range)(void *provider, pgoff_t index,
 				unsigned long *pfn, size_t *nr_pages);
+	void (*put_pfn_range)(void *provider, pgoff_t index, size_t nr_pages);
 };
 
 #endif /* _LINUX_GUEST_MEMFD_H */
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index b46907b480138..501c3e250fc98 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -177,6 +177,13 @@ static void gmem_provider_invalidate_folio(struct gmem_inode *gi,
 		gi->provider_ops->invalidate_folio(gi->provider, folio);
 }
 
+static void gmem_provider_put_pfn_range(struct gmem_inode *gi, pgoff_t index,
+					size_t nr_pages)
+{
+	if (gi->provider_ops && gi->provider_ops->put_pfn_range)
+		gi->provider_ops->put_pfn_range(gi->provider, index, nr_pages);
+}
+
 static void gmem_provider_release(struct gmem_inode *gi)
 {
 	if (gi->provider_ops && gi->provider_ops->release)
@@ -438,6 +445,7 @@ static long kvm_gmem_punch_hole(struct inode *inode, loff_t offset, loff_t len)
 	if (kvm_gmem_is_pfn_mode(GMEM_I(inode))) {
 		unmap_mapping_range(inode->i_mapping, offset, len, 0);
 		kvm_gmem_pfn_reclaim(GMEM_I(inode), start, end);
+		gmem_provider_put_pfn_range(GMEM_I(inode), start, end - start);
 	} else {
 		truncate_inode_pages_range(inode->i_mapping, offset, offset + len - 1);
 	}
@@ -1730,8 +1738,12 @@ static void kvm_gmem_destroy_inode(struct inode *inode)
 	 * Skip if the provider was not yet set up, as iput() can reach this on
 	 * error paths before provider_ops is initialized.
 	 */
-	if (gi->provider_ops && kvm_gmem_is_pfn_mode(gi))
-		kvm_gmem_pfn_reclaim(gi, 0, i_size_read(inode) >> PAGE_SHIFT);
+	if (gi->provider_ops && kvm_gmem_is_pfn_mode(gi)) {
+		pgoff_t nr_pages = i_size_read(inode) >> PAGE_SHIFT;
+
+		kvm_gmem_pfn_reclaim(gi, 0, nr_pages);
+		gmem_provider_put_pfn_range(gi, 0, nr_pages);
+	}
 
 	gmem_provider_release(gi);
 

-- 
2.56.0.455.g6c5a503b38-goog

