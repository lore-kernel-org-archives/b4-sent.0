From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 22 May 2026 15:46:10 -0700
Subject: [PATCH v2 5/5] KVM: SNP: Mark source page dirty in
 sev_gmem_post_populate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260522-fix-sev-gmem-post-populate-v2-5-3f196bfad5a1@google.com>
References: <20260522-fix-sev-gmem-post-populate-v2-0-3f196bfad5a1@google.com>
In-Reply-To: <20260522-fix-sev-gmem-post-populate-v2-0-3f196bfad5a1@google.com>
To: Sean Christopherson <seanjc@google.com>, 
 Paolo Bonzini <pbonzini@redhat.com>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, Kiryl Shutsemau <kas@kernel.org>, 
 Rick Edgecombe <rick.p.edgecombe@intel.com>, 
 Vishal Annapurve <vannapurve@google.com>, Yan Zhao <yan.y.zhao@intel.com>, 
 Michael Roth <michael.roth@amd.com>, 
 Isaku Yamahata <isaku.yamahata@intel.com>, 
 Chao Peng <chao.p.peng@linux.intel.com>, Xiaoyao Li <xiaoyao.li@intel.com>, 
 Zongyao Chen <ZongYao.Chen@linux.alibaba.com>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-coco@lists.linux.dev, Yu Zhang <yu.c.zhang@linux.intel.com>, 
 Fuad Tabba <tabba@google.com>, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779489970; l=999;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=LfALjZ80Yk9kfCpLRVu+g0s9OqQ+gOlMtaZvVRsk/ck=;
 b=GEvW3wsn10j8zAhuQEAtZjZZr7f320zjDpAJLa/xYdWJ5edUckXZrWHguQJheAgL3hhg1hQDP
 UIb2XQ1PfF5BwMn3xV7FRKSQG76irMpwNWB2RteEFhTtauw2Q+EYFuZ
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Mark the folio as dirty after copying data into the source page in
sev_gmem_post_populate. After the memcpy, failing to mark the page dirty
can lead to the memory management subsystem discarding the changes if the
page is reclaimed or otherwise processed by the swap subsystem.

Fixes: 2a62345b3052 ("KVM: guest_memfd: GUP source pages prior to populating guest memory")
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 arch/x86/kvm/svm/sev.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/x86/kvm/svm/sev.c b/arch/x86/kvm/svm/sev.c
index dbf75326a40f4..1a361f08c7a3d 100644
--- a/arch/x86/kvm/svm/sev.c
+++ b/arch/x86/kvm/svm/sev.c
@@ -2395,6 +2395,7 @@ static int sev_gmem_post_populate(struct kvm *kvm, gfn_t gfn, kvm_pfn_t pfn,
 		void *dst_vaddr = kmap_local_pfn(pfn);
 
 		memcpy(src_vaddr, dst_vaddr, PAGE_SIZE);
+		folio_mark_dirty(page_folio(src_page));
 
 		kunmap_local(dst_vaddr);
 		kunmap_local(src_vaddr);

-- 
2.54.0.794.g4f17f83d09-goog

