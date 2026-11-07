From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:11 -0800
Subject: [PATCH RFC v3 37/88] KVM: guest_memfd: Support reclaim during hole
 punch in PFN mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-37-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=2960;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=A+lPi/p3Z1v064hQ39rLQoc0mJDvEqRw5dAJ/Tf0TGA=;
 b=6VCGlYPnFECRKbsAYmAxaDdiQTXZkKjRUn6KFTvTXc0TY/u+JgD3lmHTmh8qRzAJPogSJ8NYY
 STV4EajIPm+BAO+vnnyua9N/mlAtLGXUkAoZ9GqrdKnUInexv9GyoVd
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In PFN mode, guest_memfd does not allocate or insert folios into the page
cache (inode->i_mapping). Calling truncate_inode_pages_range() is therefore
unnecessary.

Instead, call unmap_mapping_range() when in PFN mode to unmap any host
userspace PTEs over the punched range, while retaining
kvm_gmem_invalidate_start() and kvm_gmem_invalidate_end() to zap stage-2
KVM SPTEs.

Reclaim any confidential architecture state (e.g. SEV-SNP RMP) on provider
PFNs across the punched range via kvm_gmem_pfn_reclaim(), querying
.lookup_pfn_range() to skip unallocated holes without allocating memory.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 virt/kvm/guest_memfd.c | 38 ++++++++++++++++++++++++++++++++++++--
 1 file changed, 36 insertions(+), 2 deletions(-)

diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 9e8204f5c2588..567735a564c7a 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -149,7 +149,7 @@ static int gmem_provider_get_pfn(struct gmem_inode *gi, pgoff_t index,
 	return 0;
 }
 
-#ifdef CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT
+#if defined(CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT) || defined(CONFIG_HAVE_KVM_ARCH_GMEM_RECLAIM)
 static int gmem_provider_lookup_pfn_range(struct gmem_inode *gi, pgoff_t index,
 					  kvm_pfn_t *pfn, size_t *nr_pages)
 {
@@ -385,6 +385,35 @@ static void kvm_gmem_invalidate_end(struct inode *inode, pgoff_t start,
 		__kvm_gmem_invalidate_end(f, start, end);
 }
 
+#ifdef CONFIG_HAVE_KVM_ARCH_GMEM_RECLAIM
+static void kvm_gmem_pfn_reclaim(struct gmem_inode *gi, pgoff_t start, pgoff_t end)
+{
+	pgoff_t index;
+
+	for (index = start; index < end; ) {
+		size_t step = 1;
+		size_t nr_pages;
+		kvm_pfn_t pfn;
+		int r;
+
+		r = gmem_provider_lookup_pfn_range(gi, index, &pfn, &nr_pages);
+		if (!r || r == -ENOENT) {
+			step = min_t(size_t, nr_pages, end - index);
+			if (!r)
+				kvm_arch_gmem_reclaim(pfn, step);
+		} else {
+			WARN_ONCE(1, "unexpected lookup_pfn_range error %d at index 0x%lx\n",
+				  r, index);
+		}
+
+		index += step;
+		cond_resched();
+	}
+}
+#else
+static void kvm_gmem_pfn_reclaim(struct gmem_inode *gi, pgoff_t start, pgoff_t end) {}
+#endif
+
 static long kvm_gmem_punch_hole(struct inode *inode, loff_t offset, loff_t len)
 {
 	enum kvm_gfn_range_filter filter = kvm_gmem_get_all_gfns_filter(inode);
@@ -406,7 +435,12 @@ static long kvm_gmem_punch_hole(struct inode *inode, loff_t offset, loff_t len)
 
 	kvm_gmem_invalidate_start(inode, start, end, filter);
 
-	truncate_inode_pages_range(inode->i_mapping, offset, offset + len - 1);
+	if (kvm_gmem_is_pfn_mode(GMEM_I(inode))) {
+		unmap_mapping_range(inode->i_mapping, offset, len, 0);
+		kvm_gmem_pfn_reclaim(GMEM_I(inode), start, end);
+	} else {
+		truncate_inode_pages_range(inode->i_mapping, offset, offset + len - 1);
+	}
 
 	kvm_gmem_invalidate_end(inode, start, end);
 

-- 
2.56.0.455.g6c5a503b38-goog

