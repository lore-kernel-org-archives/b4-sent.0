From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 22 May 2026 15:46:08 -0700
Subject: [PATCH v2 3/5] KVM: guest_memfd: Handle errors from
 xa_store_range() when binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260522-fix-sev-gmem-post-populate-v2-3-3f196bfad5a1@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779489969; l=1708;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=IUci/DrJoi/pXPstnReU0IiJiRojPWLPI0HoQxzkXfg=;
 b=Amt1w5AFQnzejoJxCw29NWfrlwfW6wOUsNMYv7ermZIU5gGfnwJSb+05ToXZTdPKj+VforE4J
 AAZgTZ0DIT/Bn4PsYTeG5+piXbBgrdlMgmGl0ENRjiDP3UlybUnTtV7
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Unhandled errors from xa_store_range() means kvm_gmem_bind() might falsely
reporting success, leading to false assumptions in guest_memfd's lifecycle
later.

On error, restore the unbound state and return the error to userspace.

Fixes: a7800aa80ea4d ("KVM: Add KVM_CREATE_GUEST_MEMFD ioctl() for guest-specific backing memory")
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 virt/kvm/guest_memfd.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index d203135969d13..5b4911ffa208a 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -648,6 +648,7 @@ int kvm_gmem_bind(struct kvm *kvm, struct kvm_memory_slot *slot,
 	struct inode *inode;
 	struct file *file;
 	int r = -EINVAL;
+	void *result;
 
 	BUILD_BUG_ON(sizeof(gfn_t) != sizeof(slot->gmem.pgoff));
 
@@ -688,7 +689,14 @@ int kvm_gmem_bind(struct kvm *kvm, struct kvm_memory_slot *slot,
 	if (kvm_gmem_supports_mmap(inode))
 		slot->flags |= KVM_MEMSLOT_GMEM_ONLY;
 
-	xa_store_range(&f->bindings, start, end - 1, slot, GFP_KERNEL);
+	result = xa_store_range(&f->bindings, start, end - 1, slot, GFP_KERNEL);
+	if (xa_is_err(result)) {
+		r = xa_err(result);
+		xa_store_range(&f->bindings, start, end - 1, NULL, GFP_KERNEL);
+	} else {
+		r = 0;
+	}
+
 	filemap_invalidate_unlock(inode->i_mapping);
 
 	/*
@@ -696,7 +704,6 @@ int kvm_gmem_bind(struct kvm *kvm, struct kvm_memory_slot *slot,
 	 * not the other way 'round.  Active bindings are invalidated if the
 	 * file is closed before memslots are destroyed.
 	 */
-	r = 0;
 err:
 	fput(file);
 	return r;

-- 
2.54.0.794.g4f17f83d09-goog

