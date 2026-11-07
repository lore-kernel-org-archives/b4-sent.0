From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:04 -0800
Subject: [PATCH RFC v3 30/88] KVM: guest_memfd: Refactor error handling in
 kvm_gmem_fault_user_mapping
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-30-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=1832;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=VKBzbTSyM8v25pj2OERwLhVUhvmGhWqrRwXpLizcOTo=;
 b=TNHQGkfJIKvSrJmsMJhLzh4Zf2IlSWb1GaDzeKt8ZF6I4gcbCyM3w70nbNY2BGZBmWj+BSlaL
 RGs8UwVSrcNDrzLDRtCrZvXA3lfyBNeELOimwZhBiqgNYheS6HmLA9N
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Track the status of kvm_gmem_fault_user_mapping() using an explicit error
code rather than encoding errors into the folio pointer.

This moves away from relying on the folio pointer holding error states,
such as synthesizing ERR_PTR(-EACCES) when memory is not shared only to
extract PTR_ERR afterwards, and prepares kvm_gmem_fault_user_mapping() for
PFN mode in the next commit, where no folio is returned on success.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 virt/kvm/guest_memfd.c | 18 +++++++++++-------
 1 file changed, 11 insertions(+), 7 deletions(-)

diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index eedf03df12c55..180418c65a1ae 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -568,24 +568,28 @@ static bool kvm_gmem_supports_mmap(struct inode *inode)
 static vm_fault_t kvm_gmem_fault_user_mapping(struct vm_fault *vmf)
 {
 	struct inode *inode = file_inode(vmf->vma->vm_file);
-	struct folio *folio;
 	vm_fault_t ret = VM_FAULT_LOCKED;
+	struct folio *folio = NULL;
+	int r = 0;
 
 	if (((loff_t)vmf->pgoff << PAGE_SHIFT) >= i_size_read(inode))
 		return VM_FAULT_SIGBUS;
 
 	filemap_invalidate_lock_shared(inode->i_mapping);
-	if (kvm_gmem_is_shared_mem(inode, vmf->pgoff))
+	if (!kvm_gmem_is_shared_mem(inode, vmf->pgoff)) {
+		r = -EACCES;
+	} else {
 		folio = kvm_gmem_get_folio(inode, vmf->pgoff);
-	else
-		folio = ERR_PTR(-EACCES);
+		if (IS_ERR(folio))
+			r = PTR_ERR(folio);
+	}
 	filemap_invalidate_unlock_shared(inode->i_mapping);
 
-	if (IS_ERR(folio)) {
-		if (PTR_ERR(folio) == -EAGAIN)
+	if (r) {
+		if (r == -EAGAIN)
 			return VM_FAULT_RETRY;
 
-		return vmf_error(PTR_ERR(folio));
+		return vmf_error(r);
 	}
 
 	if (WARN_ON_ONCE(folio_test_large(folio))) {

-- 
2.56.0.455.g6c5a503b38-goog

