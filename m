From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:05 -0800
Subject: [PATCH RFC v3 31/88] KVM: guest_memfd: Set VM_PFNMAP on VMA in PFN
 mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-31-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=1105;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=bgDskVh5mQ4qf8kZnnMpcc5wqYuHuhwtZVlrwhGpftw=;
 b=bJSGIHIjI8Dun3pnzzwKMZBEVyIeNKBR6I98tBOsF6T1Tze7EzogHxlnUyHvxeFc6sylwP9tC
 RStTsmb8zUGD1ktql3UfDaKz0Idd1TUrp9o5uPxLSI7y9s4cXsdLKOq
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In PFN mode, guest_memfd memory is backed by raw PFNs rather than
page-cache folios.

Mark the VMA with VM_PFNMAP when setting up the VMA in PFN mode so that
the core memory management subsystem recognizes the mapping as PFN-backed.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 virt/kvm/guest_memfd.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 180418c65a1ae..183e15775523f 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -652,6 +652,8 @@ static const struct vm_operations_struct kvm_gmem_vm_ops = {
 
 static int kvm_gmem_mmap(struct file *file, struct vm_area_struct *vma)
 {
+	struct gmem_inode *gi = GMEM_I(file_inode(file));
+
 	if (!kvm_gmem_supports_mmap(file_inode(file)))
 		return -ENODEV;
 
@@ -660,6 +662,9 @@ static int kvm_gmem_mmap(struct file *file, struct vm_area_struct *vma)
 		return -EINVAL;
 	}
 
+	if (kvm_gmem_is_pfn_mode(gi))
+		vm_flags_set(vma, VM_PFNMAP);
+
 	vma->vm_ops = &kvm_gmem_vm_ops;
 
 	return 0;

-- 
2.56.0.455.g6c5a503b38-goog

