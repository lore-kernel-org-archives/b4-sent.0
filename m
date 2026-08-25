From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Wed, 26 Aug 2026 01:44:19 +0200
Subject: [PATCH 2/4] gpu: nova-core: falcon: Extract PRISCV register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260826-b4-extract-pfsp-registers-to-falcon-mod-v1-2-38351df09084@nanonej.com>
References: <20260826-b4-extract-pfsp-registers-to-falcon-mod-v1-0-38351df09084@nanonej.com>
In-Reply-To: <20260826-b4-extract-pfsp-registers-to-falcon-mod-v1-0-38351df09084@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Alexandre Courbot <acourbot@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=7318; i=dev@nanonej.com;
 h=from:subject:message-id; bh=bX0B3Voxms/whW42qQyonw4PJ52AO9nzIiHe/Qc+KFY=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqjij4TocfUQf7uDpWfkaD9KGQetyuehQkIzWLZ
 Z9xRYBZ/y2JAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCao4o+AAKCRBmh/EjChUV
 /VfjD/9FvSjEirtIPPEje0SBiUKJpDtcs70n754oeVdCXT6YiVTQ0MhpKr4TbcedDXvXDCYVYG2
 6xDMAcSwAwyixCveysiCGKLFRvQxLSaFSBiw2te1uMWE6tUcMR+i3okTNssRljAVLHZkpgvLHSP
 O7oy4Rs26o0+eVRS5g1my2zOxEK6zU+Hv6e8RGjB9vRTSMZMx8VV6NtU8vm+JjCpfdVFKlDpzX7
 fPovjo1QmHfJDsZGNrDbXPzazpUMN3/if6nerepWQ2xCl09Zaw8Rzlr+1o+4FyK4+axsBPO3XZS
 +cZdvERcygtF0Hv00ifA/qkTQl4pjrL5YI1V4GrN1UOANzgJQFzRo0UDZOOOt9PwDGX8xAS+Im8
 9t+Yfa7i2rKI+cGTZIstKcLM9C/Xd29tSdIIaKJQgwyXLTQfqd95XtDXa0OCC4jw7ZRWdab1VYA
 6gizyCXJHZ70zfQ771Zqre7E0PfvkFRVCWSh/HLOrmOCuCQiyEQteU1VIalP9NkGeBhUqdPcaJp
 G7QYThoku0FGZHqt9JF9fvEa1IfBKyl1Yz0eiQ5ywxRucdrl5SgkZl5xkBuQs28EFbMU41zdYH0
 BMf/BMnO6WKYN6nUMBF9ldVvhRar7peTeFGU0RjXhXmAHIMgxcAagZ1VHLgQbOHjG+aIzLWcZOM
 uDzvXxsZqPKPLZg==
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
 drivers/gpu/nova-core/falcon/hal/ga102.rs |  4 +--
 drivers/gpu/nova-core/falcon/hal/tu102.rs | 12 +++----
 drivers/gpu/nova-core/falcon/regs.rs      | 56 +++++++++++++++++++++++++------
 drivers/gpu/nova-core/regs.rs             | 27 +--------------
 4 files changed, 53 insertions(+), 46 deletions(-)

diff --git a/drivers/gpu/nova-core/falcon/hal/ga102.rs b/drivers/gpu/nova-core/falcon/hal/ga102.rs
index 7600ee07ca2e..7586f80388b0 100644
--- a/drivers/gpu/nova-core/falcon/hal/ga102.rs
+++ b/drivers/gpu/nova-core/falcon/hal/ga102.rs
@@ -20,13 +20,13 @@
     driver::Bar0,
     falcon::{
         hal::LoadMethod,
+        regs, //
         Falcon,
         FalconBromParams,
         FalconEngine,
         FalconModSelAlgo,
-        PeregrineCoreSelect, //
+        PeregrineCoreSelect,
     },
-    regs,
 };
 
 use super::FalconHal;
diff --git a/drivers/gpu/nova-core/falcon/hal/tu102.rs b/drivers/gpu/nova-core/falcon/hal/tu102.rs
index 5291598fedf7..fb624b925f49 100644
--- a/drivers/gpu/nova-core/falcon/hal/tu102.rs
+++ b/drivers/gpu/nova-core/falcon/hal/tu102.rs
@@ -12,14 +12,12 @@
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
index 96e1f0f1df5a..a9e1f75598dd 100644
--- a/drivers/gpu/nova-core/falcon/regs.rs
+++ b/drivers/gpu/nova-core/falcon/regs.rs
@@ -2,6 +2,35 @@
 
 use kernel::io::register;
 
+use crate::falcon::{
+    PFalcon2Base,
+    PeregrineCoreSelect, //
+};
+
+// PRISCV
+
+register! {
+    /// RISC-V status register for debug (Turing and GA100 only).
+    /// Reflects current RISC-V core status.
+    pub(super) NV_PRISCV_RISCV_CORE_SWITCH_RISCV_STATUS(u32) @ PFalcon2Base + 0x00000240 {
+        /// RISC-V core active/inactive status.
+        0:0     active_stat => bool;
+    }
+
+    /// GA102 and later.
+    pub(super) NV_PRISCV_RISCV_CPUCTL(u32) @ PFalcon2Base + 0x00000388 {
+        7:7     active_stat => bool;
+        4:4     halted => bool;
+    }
+
+    /// GA102 and later.
+    pub(super) NV_PRISCV_RISCV_BCR_CTRL(u32) @ PFalcon2Base + 0x00000668 {
+        8:8     br_fetch => bool;
+        4:4     core_select => PeregrineCoreSelect;
+        0:0     valid => bool;
+    }
+}
+
 // FSP (Foundation Security Processor) queue registers for Hopper/Blackwell Chain of Trust.
 // These registers manage falcon EMEM communication queues.
 
@@ -23,17 +52,22 @@
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
index 0404fb82aa7e..5c1cef1c66a1 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -24,8 +24,7 @@
         FalconModSelAlgo,
         FalconSecurityModel,
         PFalcon2Base,
-        PFalconBase,
-        PeregrineCoreSelect, //
+        PFalconBase, //
     },
 };
 
@@ -335,30 +334,6 @@ pub(crate) fn mem_scrubbing_done(self) -> bool {
     }
 }
 
-// PRISCV
-
-register! {
-    /// RISC-V status register for debug (Turing and GA100 only).
-    /// Reflects current RISC-V core status.
-    pub(crate) NV_PRISCV_RISCV_CORE_SWITCH_RISCV_STATUS(u32) @ PFalcon2Base + 0x00000240 {
-        /// RISC-V core active/inactive status.
-        0:0     active_stat => bool;
-    }
-
-    /// GA102 and later.
-    pub(crate) NV_PRISCV_RISCV_CPUCTL(u32) @ PFalcon2Base + 0x00000388 {
-        7:7     active_stat => bool;
-        4:4     halted => bool;
-    }
-
-    /// GA102 and later.
-    pub(crate) NV_PRISCV_RISCV_BCR_CTRL(u32) @ PFalcon2Base + 0x00000668 {
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

