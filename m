From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:28:10 -0700
Subject: [PATCH RFC v2 38/50] KVM: guest_memfd: Support reclaim during hole
 punch in PFN mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-38-5dd1dc6c660a@google.com>
References: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
In-Reply-To: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
To: Alex Williamson <alex@shazbot.org>, Alexander Graf <graf@amazon.de>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, 
 Alexey Kardashevskiy <aik@amd.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 Ashish Kalra <ashish.kalra@amd.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Baolu Lu <baolu.lu@linux.intel.com>, Bill Wendling <morbo@google.com>, 
 Borislav Petkov <bp@alien8.de>, Catalin Marinas <catalin.marinas@arm.com>, 
 Christian Brauner <brauner@kernel.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Connor Williamson <connordw@amazon.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, David Hildenbrand <david@kernel.org>, 
 David Rientjes <rientjes@google.com>, David Woodhouse <dwmw2@infradead.org>, 
 Erdem Aktas <erdemaktas@google.com>, Frank van der Linden <fvdl@google.com>, 
 Fred Griffoul <fgriffo@amazon.co.uk>, Fred Griffoul <griffoul@gmail.com>, 
 Gregory Price <gourry@gourry.net>, "H. Peter Anvin" <hpa@zytor.com>, 
 Hugh Dickins <hughd@google.com>, Ingo Molnar <mingo@redhat.com>, 
 Jacob Pan <jacob.pan@linux.microsoft.com>, 
 James Houghton <jthoughton@google.com>, Jan Kara <jack@suse.cz>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Jianxiong Gao <jxgao@google.com>, 
 Joerg Roedel <joro@8bytes.org>, Joey Gouly <joey.gouly@arm.com>, 
 John Starks <John.Starks@microsoft.com>, Jonathan Corbet <corbet@lwn.net>, 
 Justin Stitt <justinstitt@google.com>, Kevin Tian <kevin.tian@intel.com>, 
 Lorenzo Stoakes <ljs@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 Michael Roth <michael.roth@amd.com>, Mike Rapoport <rppt@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Nicolin Chen <nicolinc@nvidia.com>, Oliver Upton <oupton@kernel.org>, 
 Paolo Bonzini <pbonzini@redhat.com>, Pratyush Yadav <pratyush@kernel.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Robin Murphy <robin.murphy@arm.com>, 
 Samiullah Khawaja <skhawaja@google.com>, 
 Sean Christopherson <seanjc@google.com>, Shuah Khan <shuah@kernel.org>, 
 Steffen Eiden <seiden@linux.ibm.com>, Steven Price <steven.price@arm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Tarun Sahu <tarunsahu@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Tom Lendacky <thomas.lendacky@amd.com>, Tycho Andersen <tycho@kernel.org>, 
 Vishal Annapurve <vannapurve@google.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Will Deacon <will@kernel.org>, 
 Xu Yilun <yilun.xu@linux.intel.com>, Yan Zhao <yan.y.zhao@intel.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, x86@kernel.org, 
 Shuah Khan <skhan@linuxfoundation.org>, Fuad Tabba <fuad.tabba@linux.dev>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, llvm@lists.linux.dev, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=2795;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=Amg9h7PFK16CNLlu8wPc8g3msTSzfsY9jcWdvuN1E3s=;
 b=juwFRws8T0z3x8gJBTIgAzHVW9gxXr/0rumZeyTIjNlEMf+me1eQ7r0gWp5QZxgPTATu/OJdn
 y897sKLaSagDVXPEqUTUL67SrR2vlPH17j+23zbPqaOnlyFKKID2cBN
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
 virt/kvm/guest_memfd.c | 32 ++++++++++++++++++++++++++++++--
 1 file changed, 30 insertions(+), 2 deletions(-)

diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 206b90646c743..0819c3653e88a 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -143,7 +143,7 @@ static int gmem_provider_get_pfn(struct gmem_inode *gi, pgoff_t index,
 	return 0;
 }
 
-#ifdef CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT
+#if defined(CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT) || defined(CONFIG_HAVE_KVM_ARCH_GMEM_RECLAIM)
 static int gmem_provider_lookup_pfn_range(struct gmem_inode *gi, pgoff_t index,
 					  kvm_pfn_t *pfn, size_t *nr_pages)
 {
@@ -379,6 +379,29 @@ static void kvm_gmem_invalidate_end(struct inode *inode, pgoff_t start,
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
+
+		if (!gmem_provider_lookup_pfn_range(gi, index, &pfn, &nr_pages)) {
+			step = min_t(size_t, nr_pages, end - index);
+			kvm_arch_gmem_reclaim(pfn, step);
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
@@ -400,7 +423,12 @@ static long kvm_gmem_punch_hole(struct inode *inode, loff_t offset, loff_t len)
 
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
2.56.0.257.gf7497c7d27-goog

