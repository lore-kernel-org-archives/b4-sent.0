From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Wed, 17 Jun 2026 01:48:15 +0200
Subject: [PATCH 4/5] gpu: nova-core: falcon: Move PRISCV register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-nova-core-regs-split-v1-4-4c7dc4450ea7@nanonej.com>
References: <20260617-nova-core-regs-split-v1-0-4c7dc4450ea7@nanonej.com>
In-Reply-To: <20260617-nova-core-regs-split-v1-0-4c7dc4450ea7@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Antonin Malzieu Ridolfi <dev@nanonej.com>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, daniel.almeida@collabora.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6003; i=dev@nanonej.com;
 h=from:subject:message-id; bh=v4OCMlXZ3ecPhx+D/4mvTfBbeWEY4+on1CP8bUOpD/k=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqMeDJHDKMzgx1ZXRtkmr4t/k9vhODAXxeBRldK
 +Jc/jEM/G6JAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCajHgyQAKCRBmh/EjChUV
 /WP3EACPS8fWDxtyYRP0lE7ZNxOri6TyVdv/yAfDHiYh2aKenPkyzPsRVPep7xgJIBq1ReFZQ+A
 klChdpTC+PBDGYMDaKMcQ+q8ZIfLrVUI44qBZL+daza+W9ybdRhFySnz6itU4C1SQwSRCgucMqB
 BIGq+FPGpVM/tCl/aGdzz+ZWIdWJ+MObXdLpdeY8nCf++AHd13QvyuXPXD+aS5i9bHckXTP9X9l
 ERzE4cIw+eZBkEJdkReCAyylVfOalHexhccdDhgRKPdBYYN5TwLKysHGYNb6B31xy3yPFDDdnbO
 Y/dev9kLglUEurla3ggn8qJ/WizSAVR3722z2CssKDqbc86QhMn+RSBaWSE1VNd0JKULbDQ50fA
 gpeV5CiAvgl7exEzWPpofvQhJz6mdeQpsy/1u9ok58cKBvNy98zbYpl1UDPt50AacUxSzLz7j3C
 l2rjxAyY93bUxGmHG5PsufKidCSMYvn8P7kK667RDsuzbOE9yBUny40ZV7+5i52h678Q4FQoM3V
 w76caE7JwCJ1xQdCBhJz9jTDWNPz4J0c4HXu0rRNFOVBco478c4kvm7FsWnv6RkXA6bRE12ArSE
 SxLUenJg8cvo5qHfjiOac8ySszytk3LaGADNwxS1pcMvcAwvQeedBG2kh/ld8WpCeueRyL4xDT9
 C3kRei6KhRBPdHQ==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move PRISCV register definition into falcon module and update registers
visibility.

Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
 drivers/gpu/nova-core/falcon/hal/ga102.rs |  8 ++++----
 drivers/gpu/nova-core/falcon/hal/tu102.rs |  8 ++++----
 drivers/gpu/nova-core/falcon/regs.rs      | 27 ++++++++++++++++++++++++++-
 drivers/gpu/nova-core/regs.rs             | 28 +---------------------------
 4 files changed, 35 insertions(+), 36 deletions(-)

diff --git a/drivers/gpu/nova-core/falcon/hal/ga102.rs b/drivers/gpu/nova-core/falcon/hal/ga102.rs
index cc574fef0fbd..3adfa8dd1cfb 100644
--- a/drivers/gpu/nova-core/falcon/hal/ga102.rs
+++ b/drivers/gpu/nova-core/falcon/hal/ga102.rs
@@ -32,17 +32,17 @@
 use super::FalconHal;
 
 fn select_core_ga102<E: FalconEngine>(bar: Bar0<'_>) -> Result {
-    let bcr_ctrl = bar.read(crate::regs::NV_PRISCV_RISCV_BCR_CTRL::of::<E>());
+    let bcr_ctrl = bar.read(regs::NV_PRISCV_RISCV_BCR_CTRL::of::<E>());
     if bcr_ctrl.core_select() != PeregrineCoreSelect::Falcon {
         bar.write(
             WithBase::of::<E>(),
-            crate::regs::NV_PRISCV_RISCV_BCR_CTRL::zeroed()
+            regs::NV_PRISCV_RISCV_BCR_CTRL::zeroed()
                 .with_core_select(PeregrineCoreSelect::Falcon),
         );
 
         // TIMEOUT: falcon core should take less than 10ms to report being enabled.
         read_poll_timeout(
-            || Ok(bar.read(crate::regs::NV_PRISCV_RISCV_BCR_CTRL::of::<E>())),
+            || Ok(bar.read(regs::NV_PRISCV_RISCV_BCR_CTRL::of::<E>())),
             |r| r.valid(),
             Delta::ZERO,
             Delta::from_millis(10),
@@ -138,7 +138,7 @@ fn program_brom(&self, _falcon: &Falcon<E>, bar: Bar0<'_>, params: &FalconBromPa
     }
 
     fn is_riscv_active(&self, bar: Bar0<'_>) -> bool {
-        bar.read(crate::regs::NV_PRISCV_RISCV_CPUCTL::of::<E>())
+        bar.read(regs::NV_PRISCV_RISCV_CPUCTL::of::<E>())
             .active_stat()
     }
 
diff --git a/drivers/gpu/nova-core/falcon/hal/tu102.rs b/drivers/gpu/nova-core/falcon/hal/tu102.rs
index 3aaee3869312..1b06607e1ace 100644
--- a/drivers/gpu/nova-core/falcon/hal/tu102.rs
+++ b/drivers/gpu/nova-core/falcon/hal/tu102.rs
@@ -18,9 +18,9 @@
         hal::LoadMethod,
         Falcon,
         FalconBromParams,
-        FalconEngine, //
+        FalconEngine,
+        regs, //
     },
-    regs, //
 };
 
 use super::FalconHal;
@@ -58,7 +58,7 @@ fn is_riscv_active(&self, bar: Bar0<'_>) -> bool {
     fn reset_wait_mem_scrubbing(&self, bar: Bar0<'_>) -> Result {
         // TIMEOUT: memory scrubbing should complete in less than 10ms.
         read_poll_timeout(
-            || Ok(bar.read(regs::NV_PFALCON_FALCON_DMACTL::of::<E>())),
+            || Ok(bar.read(crate::regs::NV_PFALCON_FALCON_DMACTL::of::<E>())),
             |r| r.mem_scrubbing_done(),
             Delta::ZERO,
             Delta::from_millis(10),
@@ -67,7 +67,7 @@ fn reset_wait_mem_scrubbing(&self, bar: Bar0<'_>) -> Result {
     }
 
     fn reset_eng(&self, bar: Bar0<'_>) -> Result {
-        regs::NV_PFALCON_FALCON_ENGINE::reset_engine::<E>(bar);
+        crate::regs::NV_PFALCON_FALCON_ENGINE::reset_engine::<E>(bar);
         self.reset_wait_mem_scrubbing(bar)?;
 
         Ok(())
diff --git a/drivers/gpu/nova-core/falcon/regs.rs b/drivers/gpu/nova-core/falcon/regs.rs
index be8dbb599fc9..4d4e69b235fc 100644
--- a/drivers/gpu/nova-core/falcon/regs.rs
+++ b/drivers/gpu/nova-core/falcon/regs.rs
@@ -4,7 +4,8 @@
 
 use crate::falcon::{
     PFalcon2Base,
-    FalconModSelAlgo, //
+    FalconModSelAlgo,
+    PeregrineCoreSelect, //
 };
 
 /* PFALCON2 */
@@ -28,3 +29,27 @@
         31:0    value => u32;
     }
 }
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
+        0:0     halted => bool;
+    }
+
+    /// GA102 and later.
+    pub(super) NV_PRISCV_RISCV_BCR_CTRL(u32) @ PFalcon2Base + 0x00000668 {
+        8:8     br_fetch => bool;
+        4:4     core_select => PeregrineCoreSelect;
+        0:0     valid => bool;
+    }
+}
diff --git a/drivers/gpu/nova-core/regs.rs b/drivers/gpu/nova-core/regs.rs
index 0b048086f54f..b21a5adc723a 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -23,9 +23,7 @@
         FalconFbifTarget,
         FalconMem,
         FalconSecurityModel,
-        PFalcon2Base,
-        PFalconBase,
-        PeregrineCoreSelect, //
+        PFalconBase, //
     },
     gpu::{
         Architecture,
@@ -493,30 +491,6 @@ pub(crate) fn mem_scrubbing_done(self) -> bool {
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
-        0:0     halted => bool;
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
 // FSP (Foundation Security Processor) queue registers for Hopper/Blackwell Chain of Trust.
 // These registers manage falcon EMEM communication queues.
 

-- 
2.54.0

