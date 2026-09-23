From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Wed, 23 Sep 2026 02:41:08 +0200
Subject: [PATCH v2 2/4] gpu: nova-core: falcon: Extract PRISCV register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v2-2-74600fc068c4@nanonej.com>
References: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v2-0-74600fc068c4@nanonej.com>
In-Reply-To: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v2-0-74600fc068c4@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Alexandre Courbot <acourbot@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=7363; i=dev@nanonej.com;
 h=from:subject:message-id; bh=83HrUVKx49I1FnuN+G2/qv9yimAMXRc93HQElDM8cAo=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqsyA1I1GcsmJSnN2+cG9CxGW5pvYzxG7ghjA3b
 kxyH/ws3UWJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCarMgNQAKCRBmh/EjChUV
 /dQQD/9unBePfilzVr/+zDXZA2HuIrtnfms7kaT8KHC588/aQlcXlSS7Kwa65xPF/RyUQMLow5u
 T8DRx+ZsypxpxhBs0LJDrzovOuxtcpHoT2c/3e7epnuJt1CeIfsIqVktDqouVy8zSAeFvxj+tMa
 LDVUFUdp8QmdLPeVpdZ/YYPSZVPA81ag88N5Zp/zxO4xoxa0EzwGYsvJWoKCUQVRVUwJNx0TdlB
 2LNxrQONLXdAkr2FmJEpWTXDBa8Aqe9dHKc23PkcwFgPkJ5UPD94llBLGbeHjSo0jttFh0lLeB7
 IArrvDpYWDqXLV0G5DDpChjDDbnmWAbZ4vBzicXP2npb4v9+NmQFvfbC0ACGMwVyI5u4eDQTaVH
 /Q9tQEqzySpZ3ktjsh620NwzVn34v3E2/phpmXNGGUHn8x4XNq/mu3Ucq+v+SEi7Zpz1hYM5MEN
 GDCm1ya9ZvJlpDvK6Ska0vqgjqJFjasLtTxTWq+Tdt/3gf4GxJh9kv50axMlPVsxRHHOKiVw0a/
 kpnR76KGjBSACYcbM+ejf4fDfoIY3tcVOJAEoKr+ZjM/+LGpl8QN14tY+05UK3v1ALiRNtOBfO/
 +JbDGuYZait+MYUHB48sRsBaK/omdlLp7eNNU+N9e9iF0qt8P6n+SWKLo/lFX62Hs36497uoHeO
 e9XRpXSyDdIB9Jg==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move PRISCV register definitions from the root regs.rs file into the
falcon module that own them, in the existing falcon/regs.rs file.

This follows the same pattern established by previous commits for
GSP, PDISP, PFB, PBUS, PMC and PFSP registers: register definitions
move to the module that interprets their service, visibility changes
to pub(super).

Since PFALCON, PFALCON2 and FUSE registers are defined in the root
regs.rs but are also part of the falcon interface, accessed by the
whole falcon module. They are re-exported in falcon/regs.rs so falcon
code can use a single regs:: prefix.
Once these families moves out of the root module, these re-exports
will become plain definitions.

Suggested-by: Alexandre Courbot <acourbot@nvidia.com>
Suggested-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
 drivers/gpu/nova-core/falcon/hal/ga102.rs |  2 +-
 drivers/gpu/nova-core/falcon/hal/tu102.rs | 12 +++----
 drivers/gpu/nova-core/falcon/regs.rs      | 58 +++++++++++++++++++++++++------
 drivers/gpu/nova-core/regs.rs             | 29 +---------------
 4 files changed, 54 insertions(+), 47 deletions(-)

diff --git a/drivers/gpu/nova-core/falcon/hal/ga102.rs b/drivers/gpu/nova-core/falcon/hal/ga102.rs
index f9a8444cf840..7323579a478d 100644
--- a/drivers/gpu/nova-core/falcon/hal/ga102.rs
+++ b/drivers/gpu/nova-core/falcon/hal/ga102.rs
@@ -18,6 +18,7 @@
     driver::Bar0,
     falcon::{
         hal::LoadMethod,
+        regs, //
         Falcon,
         FalconBromParams,
         FalconEngine,
@@ -25,7 +26,6 @@
         PFalcon2Registers,
         PeregrineCoreSelect, //
     },
-    regs,
 };
 
 use super::FalconHal;
diff --git a/drivers/gpu/nova-core/falcon/hal/tu102.rs b/drivers/gpu/nova-core/falcon/hal/tu102.rs
index 7fc6e83c2566..068258c69fd9 100644
--- a/drivers/gpu/nova-core/falcon/hal/tu102.rs
+++ b/drivers/gpu/nova-core/falcon/hal/tu102.rs
@@ -11,14 +11,12 @@
     time::Delta, //
 };
 
-use crate::{
-    falcon::{
-        hal::LoadMethod,
-        Falcon,
-        FalconBromParams,
-        FalconEngine, //
-    },
+use crate::falcon::{
+    hal::LoadMethod,
     regs, //
+    Falcon,
+    FalconBromParams,
+    FalconEngine,
 };
 
 use super::FalconHal;
diff --git a/drivers/gpu/nova-core/falcon/regs.rs b/drivers/gpu/nova-core/falcon/regs.rs
index 5ccb10946ec4..2ac71a7a4ec2 100644
--- a/drivers/gpu/nova-core/falcon/regs.rs
+++ b/drivers/gpu/nova-core/falcon/regs.rs
@@ -3,6 +3,37 @@
 use crate::driver::NovaRegisters;
 use kernel::io::register;
 
+use crate::falcon::{
+    PFalcon2Registers,
+    PeregrineCoreSelect, //
+};
+
+// PRISCV
+
+register! {
+    base: PFalcon2Registers;
+
+    /// RISC-V status register for debug (Turing and GA100 only).
+    /// Reflects current RISC-V core status.
+    pub(super) NV_PRISCV_RISCV_CORE_SWITCH_RISCV_STATUS(u32) @ 0x00000240 {
+        /// RISC-V core active/inactive status.
+        0:0     active_stat => bool;
+    }
+
+    /// GA102 and later.
+    pub(super) NV_PRISCV_RISCV_CPUCTL(u32) @ 0x00000388 {
+        7:7     active_stat => bool;
+        4:4     halted => bool;
+    }
+
+    /// GA102 and later.
+    pub(super) NV_PRISCV_RISCV_BCR_CTRL(u32) @ 0x00000668 {
+        8:8     br_fetch => bool;
+        4:4     core_select => PeregrineCoreSelect;
+        0:0     valid => bool;
+    }
+}
+
 // FSP (Foundation Security Processor) queue registers for Hopper/Blackwell Chain of Trust.
 // These registers manage falcon EMEM communication queues.
 
@@ -26,17 +57,22 @@
     }
 }
 
-// PFALCON registers are defined in the root `regs.rs` but are part of the falcon
-// interface, accessed by the whole falcon module. They are re-exported here so
-// falcon code can use a single `regs::` prefix.
-// Once the PFALCON family moves out of the root module, these re-exports become
+// PFALCON, PFALCON2 and FUSE registers are defined in the root `regs.rs` but
+// are part of the falcon interface, accessed by the whole falcon module. They
+// are re-exported here so falcon code can use a single `regs::` prefix.
+// Once these families move out of the root module, these re-exports become
 // plain definitions.
 pub(super) use crate::regs::{
-    NV_PFALCON_FALCON_BOOTVEC, NV_PFALCON_FALCON_CPUCTL, NV_PFALCON_FALCON_CPUCTL_ALIAS,
-    NV_PFALCON_FALCON_DMACTL, NV_PFALCON_FALCON_DMATRFBASE, NV_PFALCON_FALCON_DMATRFBASE1,
-    NV_PFALCON_FALCON_DMATRFCMD, NV_PFALCON_FALCON_DMATRFFBOFFS, NV_PFALCON_FALCON_DMATRFMOFFS,
-    NV_PFALCON_FALCON_DMEMC, NV_PFALCON_FALCON_DMEMD, NV_PFALCON_FALCON_EMEMC,
-    NV_PFALCON_FALCON_EMEMD, NV_PFALCON_FALCON_IMEMC, NV_PFALCON_FALCON_IMEMD,
-    NV_PFALCON_FALCON_IMEMT, NV_PFALCON_FALCON_MAILBOX0, NV_PFALCON_FALCON_MAILBOX1,
-    NV_PFALCON_FALCON_OS, NV_PFALCON_FALCON_RM, NV_PFALCON_FBIF_CTL, NV_PFALCON_FBIF_TRANSCFG,
+    NV_FUSE_OPT_FPF_GSP_UCODE1_VERSION, NV_FUSE_OPT_FPF_NVDEC_UCODE1_VERSION,
+    NV_FUSE_OPT_FPF_SEC2_UCODE1_VERSION, NV_FUSE_OPT_FPF_SIZE,
+    NV_PFALCON2_FALCON_BROM_CURR_UCODE_ID, NV_PFALCON2_FALCON_BROM_ENGIDMASK,
+    NV_PFALCON2_FALCON_BROM_PARAADDR, NV_PFALCON2_FALCON_MOD_SEL, NV_PFALCON_FALCON_BOOTVEC,
+    NV_PFALCON_FALCON_CPUCTL, NV_PFALCON_FALCON_CPUCTL_ALIAS, NV_PFALCON_FALCON_DMACTL,
+    NV_PFALCON_FALCON_DMATRFBASE, NV_PFALCON_FALCON_DMATRFBASE1, NV_PFALCON_FALCON_DMATRFCMD,
+    NV_PFALCON_FALCON_DMATRFFBOFFS, NV_PFALCON_FALCON_DMATRFMOFFS, NV_PFALCON_FALCON_DMEMC,
+    NV_PFALCON_FALCON_DMEMD, NV_PFALCON_FALCON_EMEMC, NV_PFALCON_FALCON_EMEMD,
+    NV_PFALCON_FALCON_ENGINE, NV_PFALCON_FALCON_HWCFG2, NV_PFALCON_FALCON_IMEMC,
+    NV_PFALCON_FALCON_IMEMD, NV_PFALCON_FALCON_IMEMT, NV_PFALCON_FALCON_MAILBOX0,
+    NV_PFALCON_FALCON_MAILBOX1, NV_PFALCON_FALCON_OS, NV_PFALCON_FALCON_RM, NV_PFALCON_FBIF_CTL,
+    NV_PFALCON_FBIF_TRANSCFG,
 };
diff --git a/drivers/gpu/nova-core/regs.rs b/drivers/gpu/nova-core/regs.rs
index 693b5148b1d8..0a168b53236d 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -24,8 +24,7 @@
         FalconModSelAlgo,
         FalconSecurityModel,
         PFalcon2Registers,
-        PFalconRegisters,
-        PeregrineCoreSelect, //
+        PFalconRegisters, //
     },
     mm::tlb::TlbAckMode, //
 };
@@ -346,32 +345,6 @@ pub(crate) fn mem_scrubbing_done(self) -> bool {
     }
 }
 
-// PRISCV
-
-register! {
-    base: PFalcon2Registers;
-
-    /// RISC-V status register for debug (Turing and GA100 only).
-    /// Reflects current RISC-V core status.
-    pub(crate) NV_PRISCV_RISCV_CORE_SWITCH_RISCV_STATUS(u32) @ 0x00000240 {
-        /// RISC-V core active/inactive status.
-        0:0     active_stat => bool;
-    }
-
-    /// GA102 and later.
-    pub(crate) NV_PRISCV_RISCV_CPUCTL(u32) @ 0x00000388 {
-        7:7     active_stat => bool;
-        4:4     halted => bool;
-    }
-
-    /// GA102 and later.
-    pub(crate) NV_PRISCV_RISCV_BCR_CTRL(u32) @ 0x00000668 {
-        8:8     br_fetch => bool;
-        4:4     core_select => PeregrineCoreSelect;
-        0:0     valid => bool;
-    }
-}
-
 // The modules below provide registers that are not identical on all supported chips. They should
 // only be used in HAL modules.
 

-- 
2.55.0

