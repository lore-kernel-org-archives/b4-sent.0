From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 27 May 2026 08:33:23 -0700
Subject: [PATCH RFC 11/12] KVM: mmu: Point users of
 host_pfn_mapping_level() to docs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-kvm-locking-docs-v1-11-4fe8b602ff47@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779896001; l=4206;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=1Iv7rmsthjHBhqlZuqMTaGdIcDmY7dzZBn2M3n/QhfA=;
 b=DbFncF6doMBB+aSot4N9pP3MjdxICCeHux2pefhL0l/IYTSzt+vFHwnY3udE0SyelBPn1PfAQ
 H4IwkJf86J8D18K8SCuU30i5QSn926OUxaY1cKuJTR+oj3QTWScfu5d
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After consolidating documentation for host_pfn_mapping_level() in
Documentation/virt/kvm/locking.rst, point users of function to docs.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 arch/loongarch/kvm/mmu.c | 24 ++++--------------------
 arch/x86/kvm/mmu/mmu.c   | 24 ++++--------------------
 2 files changed, 8 insertions(+), 40 deletions(-)

diff --git a/arch/loongarch/kvm/mmu.c b/arch/loongarch/kvm/mmu.c
index a7fa458e33605..0313901171a2e 100644
--- a/arch/loongarch/kvm/mmu.c
+++ b/arch/loongarch/kvm/mmu.c
@@ -641,27 +641,11 @@ static bool fault_supports_huge_mapping(struct kvm_memory_slot *memslot,
 /*
  * Lookup the mapping level for @gfn in the current mm.
  *
- * WARNING!  Use of host_pfn_mapping_level() requires the caller and the end
- * consumer to be tied into KVM's handlers for MMU notifier events!
+ * WARNING!  This derives information from the current state of memslots and
+ * page mappings and may race with invalidations.
  *
- * There are several ways to safely use this helper:
- *
- * - Check mmu_invalidate_retry_gfn() after grabbing the mapping level, before
- *   consuming it.  In this case, mmu_lock doesn't need to be held during the
- *   lookup, but it does need to be held while checking the MMU notifier.
- *
- * - Hold mmu_lock AND ensure there is no in-progress MMU notifier invalidation
- *   event for the hva.  This can be done by explicit checking the MMU notifier
- *   or by ensuring that KVM already has a valid mapping that covers the hva.
- *
- * - Do not use the result to install new mappings, e.g. use the host mapping
- *   level only to decide whether or not to zap an entry.  In this case, it's
- *   not required to hold mmu_lock (though it's highly likely the caller will
- *   want to hold mmu_lock anyways, e.g. to modify SPTEs).
- *
- * Note!  The lookup can still race with modifications to host page tables, but
- * the above "rules" ensure KVM will not _consume_ the result of the walk if a
- * race with the primary MMU occurs.
+ * See Documentation/virt/kvm/locking.rst to understand how to consuming the
+ * result of this lookup safely.
  */
 static int host_pfn_mapping_level(struct kvm *kvm, gfn_t gfn,
 				const struct kvm_memory_slot *slot)
diff --git a/arch/x86/kvm/mmu/mmu.c b/arch/x86/kvm/mmu/mmu.c
index f8aa7eda661ee..20cdcdd20e78d 100644
--- a/arch/x86/kvm/mmu/mmu.c
+++ b/arch/x86/kvm/mmu/mmu.c
@@ -3214,27 +3214,11 @@ static void direct_pte_prefetch(struct kvm_vcpu *vcpu, u64 *sptep)
 /*
  * Lookup the mapping level for @gfn in the current mm.
  *
- * WARNING!  Use of host_pfn_mapping_level() requires the caller and the end
- * consumer to be tied into KVM's handlers for MMU notifier events!
+ * WARNING!  This derives information from the current state of memslots and
+ * page mappings and may race with invalidations.
  *
- * There are several ways to safely use this helper:
- *
- * - Check mmu_invalidate_retry_gfn() after grabbing the mapping level, before
- *   consuming it.  In this case, mmu_lock doesn't need to be held during the
- *   lookup, but it does need to be held while checking the MMU notifier.
- *
- * - Hold mmu_lock AND ensure there is no in-progress MMU notifier invalidation
- *   event for the hva.  This can be done by explicit checking the MMU notifier
- *   or by ensuring that KVM already has a valid mapping that covers the hva.
- *
- * - Do not use the result to install new mappings, e.g. use the host mapping
- *   level only to decide whether or not to zap an entry.  In this case, it's
- *   not required to hold mmu_lock (though it's highly likely the caller will
- *   want to hold mmu_lock anyways, e.g. to modify SPTEs).
- *
- * Note!  The lookup can still race with modifications to host page tables, but
- * the above "rules" ensure KVM will not _consume_ the result of the walk if a
- * race with the primary MMU occurs.
+ * See Documentation/virt/kvm/locking.rst to understand how to consuming the
+ * result of this lookup safely.
  */
 static int host_pfn_mapping_level(struct kvm *kvm, gfn_t gfn,
 				  const struct kvm_memory_slot *slot)

-- 
2.54.0.823.g6e5bcc1fc9-goog

