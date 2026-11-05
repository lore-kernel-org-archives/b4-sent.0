From: Xuheng Li <xuheng@cs.columbia.edu>
Date: Thu, 05 Nov 2026 19:45:21 +0000
Subject: [PATCH] KVM: arm64: Order a later pinner's accesses after the hyp
 mapping
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-pin-barrier-v1-1-04ebf118175a@cs.columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNT3YLMPN2kxCKgpiJdU4s0I2Mjy2RLQwsjJaCOgqLUtMwKsGnRsbW
 1AHAag7RdAAAA
X-Change-ID: 20261105-pin-barrier-58f2329c9182
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oupton@kernel.org>
Cc: Quentin Perret <qperret@google.com>, Will Deacon <will@kernel.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, 
 Mark Rutland <mark.rutland@arm.com>, Fuad Tabba <fuad.tabba@linux.dev>, 
 Joey Gouly <joey.gouly@arm.com>, Steffen Eiden <seiden@linux.ibm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, kvmarm@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Xuheng Li <xuheng@cs.columbia.edu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793907920; l=4979;
 i=xuheng@cs.columbia.edu; s=20261028; h=from:subject:message-id;
 bh=VSD4GLblhd6azQKpEOEzqUEqojO3itNwjO/sVgeUiIo=;
 b=QTSVYgfFMuRB8xUVfGJEOEYn5PHpxm7RURrEUKvrivYUBnG4i8kkVU4ZFZfpoibktyqcqFCLM
 redV+d6YhMKClxjlcRUrICmxiCS1kKQL1FJrXBMRBJVHHUy8JOYyWfy
X-Developer-Key: i=xuheng@cs.columbia.edu; a=ed25519;
 pk=L1HVV+goqxYmEMO/OXakL6uf9isSpgk2QrLlFqyZ2Qs=
X-Endpoint-Received: by B4 Relay for xuheng@cs.columbia.edu/20261028 with auth_id=1349
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 48d848882395 ("KVM: arm64: Defer EL2 stage-1 mapping on
share"), hyp_pin_shared_mem() maps a shared page into the hypervisor's
stage-1 only when its refcount goes from 0 to 1.  The CPU that maps it
runs dsb(ishst); isb() in kvm_pgtable_hyp_map(), which orders that CPU's
own accesses.  A CPU that pins the page later sees refcount >= 1, maps
nothing and runs no barrier.  It then accesses the page through an
address it computed before taking the locks, so nothing orders its
translation after the other CPU's PTE write.  The access can use a
translation performed while the entry was still invalid, and fault.

A host can do this with any pinning hypercall by passing the same page
from two CPUs, for example __pkvm_init_vm() with the same struct kvm:

  CPU A                                CPU B
  -----                                -----
                                       host_kvm = kern_hyp_va_host(x1)
                                       (host_kvm may be translated now,
                                        while its entry is invalid)
  __pkvm_init_vm(host_kvm)
   hyp_pin_shared_mem()
    host/hyp locks
    refcount 0 -> 1
    pkvm_create_mappings_locked()
     kvm_pgtable_hyp_map()
      write the valid PTE
      dsb(ishst); isb()   <- CPU A only
    unlock
                                       __pkvm_init_vm(host_kvm)
                                        hyp_pin_shared_mem()
                                         host/hyp locks
                                         refcount 1 -> 2: no mapping,
                                         no barrier
                                         unlock
                                        READ_ONCE(host_kvm->created_vcpus)
                                         uses the old translation:
                                         translation fault -> hyp_panic()

The lock hand-off orders CPU B's loads and stores after CPU A's PTE
write, but not its translation table walks.  Arm's herd7 model with
-variant vmsa allows the fault for this shape: a mapping made and
completed with DSB; ISB on one CPU, handed over through a
release/acquire, then used on another CPU through an address it already
held.  It forbids the fault once the second CPU runs DSB; ISB after the
acquire.

Make every successful pin end with dsb(ish); isb(), so that the pinning
CPU's later accesses through the range are ordered after the mapping,
whichever pin installed it.

Fixes: 48d848882395 ("KVM: arm64: Defer EL2 stage-1 mapping on share")
Cc: stable@vger.kernel.org
Signed-off-by: Xuheng Li <xuheng@cs.columbia.edu>
---
The fault was found with herd7 (herdtools7 7.58+1) and Arm's AArch64
model with -variant vmsa,fatal.  The test reduces the host/hyp locks to
an acquire of CPU A's release and the pin to its refcount check:

AArch64 pin-maps-nothing
{
pte_x=(valid:0);
0:X2=pte_x; 0:X1=(oa:phy_y);
y=1;
pte_z=(af:1,db:1); pte_r=(af:1,db:1);
0:X8=z; 1:X8=z;
0:X9=r; 1:X9=r;
1:X3=x;
}
 P0               | P1                ;
 MOV W5,#1        | LDAR W7,[X8]      ;
 STR W5,[X9]      | LDR W5,[X9]       ;
 STLR X1,[X2]     | ADD W5,W5,#1      ;
 DSB ISHST        | STR W5,[X9]       ;
 ISB              | CMP W5,#1         ;
 MOV W7,#1        | B.EQ LMAP         ;
 STLR W7,[X8]     | MOV W6,#2         ;
                  | STLR W6,[X8]      ;
                  | L0: LDR W4,[X3]   ;
                  | LMAP:             ;
exists (1:X7=1 /\ 1:X5=2 /\ fault(P1:L0,x))

P0 is the pin that maps x (refcount 0 -> 1, PTE store, dsb(ishst);
isb(), unlock).  P1 takes the lock after P0's unlock, sees refcount 2,
maps nothing, and then loads through the address it already held in X3.

  $ herd7 -variant vmsa,fatal pin-maps-nothing.litmus
  ...
  1:X5=2; 1:X7=1; Fault(P1:L0,x,D-MMU:Translation);
  ...
  Observation pin-maps-nothing Sometimes 1 7

With DSB ISH; ISB on P1 after its acquire and before L0, as this patch
adds, the result is Never (0 6).  It is also Never with
-variant vmsa,fatal,ets2, i.e. on CPUs with FEAT_ETS2.
---
 arch/arm64/kvm/hyp/nvhe/mem_protect.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/kvm/hyp/nvhe/mem_protect.c b/arch/arm64/kvm/hyp/nvhe/mem_protect.c
index d4c332a91..5cb1a1e1f 100644
--- a/arch/arm64/kvm/hyp/nvhe/mem_protect.c
+++ b/arch/arm64/kvm/hyp/nvhe/mem_protect.c
@@ -1210,6 +1210,14 @@ int hyp_pin_shared_mem(void *from, void *to)
 							    PAGE_HYP));
 	}
 
+	/*
+	 * Only the first pin of a page maps it, and that CPU's barriers order
+	 * only its own accesses. Order this CPU's accesses through the range
+	 * after the mapping, whichever pin made it.
+	 */
+	dsb(ish);
+	isb();
+
 unlock:
 	hyp_unlock_component();
 	host_unlock_component();

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261105-pin-barrier-58f2329c9182

Best regards,
-- 
Xuheng Li <xuheng@cs.columbia.edu>

