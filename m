From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 27 May 2026 08:33:22 -0700
Subject: [PATCH RFC 10/12] KVM: guest_memfd: Clarify comment about
 gmem.file vs kvm->srcu
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-kvm-locking-docs-v1-10-4fe8b602ff47@google.com>
References: <20260527-kvm-locking-docs-v1-0-4fe8b602ff47@google.com>
In-Reply-To: <20260527-kvm-locking-docs-v1-0-4fe8b602ff47@google.com>
To: Paolo Bonzini <pbonzini@redhat.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Tianrui Zhao <zhaotianrui@loongson.cn>, Bibo Mao <maobibo@loongson.cn>, 
 Huacai Chen <chenhuacai@kernel.org>, WANG Xuerui <kernel@xen0n.name>, 
 Sean Christopherson <seanjc@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, Fuad Tabba <tabba@google.com>, 
 vannapurve@google.com, x86@kernel.org, "H. Peter Anvin" <hpa@zytor.com>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, loongarch@lists.linux.dev, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779896001; l=1303;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=Tom9j4Egg9w53w5LFUq+AuZPef+PZPDtSajFqVBtT2Y=;
 b=zmWHHdOBn2VUHo/3MFGM+UFpeHWLnLuk5bbX+cVcR6fbgTn96QkVjabkLihMX7tye0SnmS6Tj
 4yHcgDc5PfsADjhgoYLEkOnUJTwyvLLyJX53hXSzWi5YZ0QcGrBfAyn
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Clarify the existing comment about synchronize_srcu() and
kvm_gmem_get_pfn() to provide further context. Explain which
synchronize_srcu() prevents races with how kvm_gmem_get_pfn() is used.

Also point reader to documentation for better understanding.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 virt/kvm/guest_memfd.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 69c9d6d546b28..f2218db0af980 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -711,8 +711,13 @@ static void __kvm_gmem_unbind(struct kvm_memory_slot *slot, struct gmem_file *f)
 	xa_store_range(&f->bindings, start, end - 1, NULL, GFP_KERNEL);
 
 	/*
-	 * synchronize_srcu(&kvm->srcu) ensured that kvm_gmem_get_pfn()
-	 * cannot see this memslot.
+	 * This is called when memslots are updated, after the old
+	 * memslot container is no longer in
+	 * use. synchronize_srcu(&kvm->srcu) was called there, so
+	 * kvm_gmem_get_pfn() from KVM's guest fault handling cannot
+	 * see this memslot. See Documentation/virt/kvm/locking.rst
+	 * for more information about kvm->srcu and the memslots
+	 * container.
 	 */
 	WRITE_ONCE(slot->gmem.file, NULL);
 }

-- 
2.54.0.823.g6e5bcc1fc9-goog

