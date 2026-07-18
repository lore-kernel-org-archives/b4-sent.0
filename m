From: Phil Rosenthal <phil@phil.gs>
Date: Sat, 18 Jul 2026 12:50:23 -0400
Subject: [PATCH v3] KVM: x86/mmu: Fix use-after-free on vendor module
 reload
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260718-kvm-mmu-cache-uaf-v3-1-e103b93c74e1@phil.gs>
X-B4-Tracking: v=1; b=H4sIAM6uW2oC/x3MQQqAIBBA0avIrBsow7KuEi3ExhrCCsUIwrsnL
 d/i/xciBaYIo3gh0M2Rz6OgrQTYzRwrIS/FIGvZ1X2jcb89ep/QGrsRJuNwUEq2SmtyxkHprkC
 On/85zTl//ccQmWMAAAA=
X-Change-ID: 20260718-kvm-mmu-cache-uaf-95523588efaf
To: Sean Christopherson <seanjc@google.com>, 
 Paolo Bonzini <pbonzini@redhat.com>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Phil Rosenthal <phil@phil.gs>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784393427; l=3371;
 i=phil@phil.gs; s=20260718; h=from:subject:message-id;
 bh=RJONytuVPEF8KRx8GQSxnlP2Nh3ufeXxVoFTncrVWgw=;
 b=fStWjfKfZN8N+MV+QaMhd7vh0PD9OUo+okXzntBHYJFjqoGO4L0Kzp/SL+K9plwNoEW2CyXVv
 ZhHCPPKE9xCCB59tnS9GiKHxbWFaLxQ4oyHAhK7UP22swYZx6fNSkgq
X-Developer-Key: i=phil@phil.gs; a=ed25519;
 pk=08BMg1YPtTS5NnKn5I1Mq1ra3MdAg49Awe6OjrC59fs=
X-Endpoint-Received: by B4 Relay for phil@phil.gs/20260718 with auth_id=881
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mmu_destroy_caches() destroys pte_list_desc_cache and
mmu_page_header_cache, but leaves both pointers unchanged.  The pointers
live in kvm.ko, and therefore survive when a vendor module is unloaded
while kvm.ko remains loaded.

If creation of pte_list_desc_cache fails during a subsequent vendor
module load, its assignment sets pte_list_desc_cache to NULL and the
error path calls mmu_destroy_caches().  mmu_page_header_cache still
points to the cache destroyed during the preceding vendor module
unload.  Passing that stale pointer to kmem_cache_destroy() causes a
slab use-after-free.

Reproduce the issue on a v7.1.3 kernel with CONFIG_KASAN=y,
CONFIG_KASAN_GENERIC=y, CONFIG_KVM=m, and CONFIG_KVM_INTEL=m.  A
one-shot test hook forces pte_list_desc_cache to NULL on the second
invocation of kvm_mmu_vendor_module_init():

  1. Load kvm.ko and kvm-intel.ko, creating both caches.
  2. Unload only kvm_intel, leaving kvm.ko loaded.
  3. Reload kvm_intel and force initialization through the -ENOMEM path.

KASAN reports:

  BUG: KASAN: slab-use-after-free in
  kvm_mmu_vendor_module_init+0x5b/0x170 [kvm]
  ...
  kmem_cache_destroy+0x21/0x1d0
  kvm_mmu_vendor_module_init+0x5b/0x170 [kvm]
  ...
  Allocated by task 16817:
  __kmem_cache_create_args+0x12c/0x3b0
  __kmem_cache_create.constprop.0+0xb6/0xf0 [kvm]
  kvm_mmu_vendor_module_init+0x13b/0x170 [kvm]
  ...
  Freed by task 16820:
  kmem_cache_destroy+0x117/0x1d0
  kvm_mmu_vendor_module_exit+0x21/0x30 [kvm]

Clear both pointers immediately after destroying their caches so that
the stored state reflects the caches' lifetime and repeated cleanup is
safe.

With the fix applied, the same injected vendor module reload fails with
-ENOMEM as expected and produces no KASAN report.

Fixes: cb498ea2ce1d ("KVM: Portability: Combine kvm_init and kvm_init_x86")
Cc: stable@vger.kernel.org
Signed-off-by: Phil Rosenthal <phil@phil.gs>
---
Apologies for the extra churn.  The v2 diff was corrupted by my mail
client; v3 is sent through b4 and restores the correct tabs.

Changes in v3:
  - Restore tabs in the diff that were converted to spaces by the mail
    client.
  - Describe the failure as a slab use-after-free rather than a
    double-free.
  - Document the exact one-shot fault-injection reproduction and include
    a shortened KASAN trace.
  - Drop the self-applied Tested-by trailer.

v2: https://lore.kernel.org/r/8292444A-CE2C-4E1C-AE13-5B21D4D1A884@phil.gs/
v1: https://lore.kernel.org/r/3FD1B35F-ECF8-476D-B2F1-6A43E6E0B641@phil.gs/
---
 arch/x86/kvm/mmu/mmu.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/x86/kvm/mmu/mmu.c b/arch/x86/kvm/mmu/mmu.c
index 234d0a95abf534193e8285e61dfb7e0c56ba19ad..ec49ce98a44919012288eb0ac3923939573b96af 100644
--- a/arch/x86/kvm/mmu/mmu.c
+++ b/arch/x86/kvm/mmu/mmu.c
@@ -7574,7 +7574,9 @@ void kvm_mmu_invalidate_mmio_sptes(struct kvm *kvm, u64 gen)
 static void mmu_destroy_caches(void)
 {
 	kmem_cache_destroy(pte_list_desc_cache);
+	pte_list_desc_cache = NULL;
 	kmem_cache_destroy(mmu_page_header_cache);
+	mmu_page_header_cache = NULL;
 }
 
 static void kvm_wake_nx_recovery_thread(struct kvm *kvm)

---
base-commit: 1229e2e57a5c2980ccd457b9b53ea0eed5a22ab3
change-id: 20260718-kvm-mmu-cache-uaf-95523588efaf

Best regards,
-- 
Phil Rosenthal <phil@phil.gs>

