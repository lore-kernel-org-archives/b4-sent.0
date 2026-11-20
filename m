From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 20 Nov 2026 13:07:12 -0800
Subject: [PATCH] KVM: x86/mmu: Prevent hugepage recovery on non-guest_memfd
 private GFNs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-gmem-fix-gmem-max-mapping-level-v1-1-108788914fe8@google.com>
X-B4-Tracking: v=1; b=H4sIAH+2AGsC/yWNwQqDMBBEf0X23AUTaYX+SukhWbdxi0lDoiKI/
 95tPQzMg+HNDpWLcIV7s0PhVap8koK5NECjS4FRBmWwrb0ZY1sMkSO+ZDtLdJsmZ0kBJ155Qkf
 kfW+o664W1JIL6/r/8HieXBf/Zpp/WjiOLytk3UKDAAAA
X-Change-ID: 20261120-gmem-fix-gmem-max-mapping-level-accbb71c3352
To: Sean Christopherson <seanjc@google.com>, 
 Paolo Bonzini <pbonzini@redhat.com>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, Fuad Tabba <fuad.tabba@linux.dev>, 
 David Hildenbrand <david@kernel.org>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795208833; l=2547;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=Y0i6Euk/xaC1ZCsSKIuwJUQwvKbcrEW4zjiLBGkW4HE=;
 b=yGonGreEgc0BdPMVqeglPV5HUwVFM4Dw1iv2Lr9P4AMWQ6f6wM0eyzt/GT2B9ke6JNrIpdkAm
 uf9Z/wXEoTuBqibEvSAT8CtdDu+DCZhw5/hWtY5LzPjcfz/kBPIaVu4
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When determining the maximum mapping level outside of a page fault
(such as when disabling dirty logging), KVM queries the VM memory
attributes to determine whether a GFN is private. Userspace can mark a
GFN as private in the VM attributes even when the covering memslot is
not backed by guest_memfd.

Previously, this caused the mapping level calculation to fall into
kvm_gmem_max_mapping_level(), triggering a kernel warning.

Here's 1 way to trigger the warning on a TDX VM, with VM memory attributes
enabled on KVM.

1. Create a non-guest_memfd memslot covering a 1G-aligned base GFN with
   dirty logging enabled.
2. In that memslot, fault a shared page outside the first 2M chunk so a
   non-leaf PTE at the 1G level is installed.
3. Mark the first 2M chunk (at the 1G-aligned base GFN) private. Conversion
   zaps that 2M chunk, while the shared mapping outside it keeps the 1G
   non-leaf PTE present.
4. Disable dirty logging on the memslot.

Hugepage recovery iterates over the present 1G non-leaf PTE, sees that its
base GFN is private and the 2M range is not mixed, and calls into
kvm_gmem_max_mapping_level() without a fault context, hitting the WARN.

Return 4K as the maximum mapping level when a GFN is marked private in
a non-fault path for a memslot without guest_memfd. Fault paths already
disallow mapping private GFNs in non-guest_memfd memslots, and
returning 4K prevents hugepage recovery on such GFNs.

Fixes: a3522ac71f5e ("KVM: x86/mmu: Enforce guest_memfd's max order when recovering hugepages")
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 arch/x86/kvm/mmu/mmu.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/x86/kvm/mmu/mmu.c b/arch/x86/kvm/mmu/mmu.c
index f89e9f8a6cc2f..af40fbe9001a7 100644
--- a/arch/x86/kvm/mmu/mmu.c
+++ b/arch/x86/kvm/mmu/mmu.c
@@ -3489,6 +3489,14 @@ int kvm_mmu_max_mapping_level(struct kvm *kvm, struct kvm_page_fault *fault,
 	} else {
 		max_level = PG_LEVEL_NUM;
 		is_private = kvm_is_private_gfn(kvm, gfn);
+
+		/*
+		 * is_private (set in VM attributes) should never have been used
+		 * with a non-guest_memfd memslot. Return PG_LEVEL_4K to prevent
+		 * hugepage recovery.
+		 */
+		if (is_private && !kvm_slot_has_gmem(slot))
+			return PG_LEVEL_4K;
 	}
 
 	max_level = min(max_level, max_huge_page_level);

---
base-commit: d0f871bfb831705d9f55479f5b2b40f636ea7b16
change-id: 20261120-gmem-fix-gmem-max-mapping-level-accbb71c3352

Best regards,
--  
Ackerley Tng <ackerleytng@google.com>

