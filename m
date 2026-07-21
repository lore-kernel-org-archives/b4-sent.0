From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Tue, 21 Jul 2026 17:41:08 +0200
Subject: [PATCH 2/3] gpu: nova-core: Move PFB registers definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260721-nova-core-regs-split-v1-2-384fa2a42244@nanonej.com>
References: <20260721-nova-core-regs-split-v1-0-384fa2a42244@nanonej.com>
In-Reply-To: <20260721-nova-core-regs-split-v1-0-384fa2a42244@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, daniel.almeida@collabora.com, 
 Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=14293; i=dev@nanonej.com;
 h=from:subject:message-id; bh=F5LTVHjgFJ3uUDHCKOhGSKmExpbgKCjvPw0GmpMTOP0=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqX5Mtt2gsPtSVggbdn9Na86o9+nkrOuPPEplDS
 RbWDTpIelGJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCal+TLQAKCRBmh/EjChUV
 /YdQD/kBgdMGuuN9pmUCgfgYyZCfBzw/UnT6f3LYAxOXBONe8dSl6miJJUypbeMCqsmEpm7LFOq
 +VRCZsnfN+4DEAhSfIXiy+w+fWyFd3osbgLdGIlQ/C43+QoQw8UVpRPoPkq7OZMJquqIb+8kdZN
 5W/cehIBPO3ilAfHISzdBhJUvI/zye3UrBskVNW8Gc7d+HLKarKdSN+rPaVQ12xIaEq+HM04nSh
 90jgmGKw3TwITKbbymxVzPdmdOuyHjTfAa+Urt85SLMmDdY98lcynTD8oKo2h3P0iOF48mdQUNE
 7/s2clcyd6Q4Oow/HRUxBUTyRm8Vb1IkuDGd/0tu4wNwHekhlJuTv21T0ZaIOnJ+NHZfjZd14Wh
 sww4il2DiDZUPqXNnmwDx9y6pSrnF1KiqmBx4efEMRtPILRxxPj84woxTd9C86b1/QoryEJgvdl
 kWSrdCF3fqJscinH1TJ+JeDVvMYnH2O7n+Mcup0578XcMBD99Q0hENIiY4nZ8ydFPk5b8cOz+6K
 GhczdD/g6MKfOyDlMBOsENz6yn0WJCpL13uv/1tDR0nIUEfAITGblRTHqgXVaijX0U/+EcX9ke/
 4JNiAc9hCGZCO/qyOF2+ibA8y8WfTohJ+FenwchqvcHdCgAKwQDfMd3ldwWpK49Qc7xyCVKnmLP
 CGdBpQqHRpDX6nw==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Suggested-by: Alexandre Courbot <acourbot@nvidia.com>
Suggested-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
 drivers/gpu/nova-core/fb.rs           |   4 +-
 drivers/gpu/nova-core/fb/hal/ga100.rs |   8 ++-
 drivers/gpu/nova-core/fb/hal/gb100.rs |   6 +-
 drivers/gpu/nova-core/fb/hal/gb202.rs |   6 +-
 drivers/gpu/nova-core/fb/hal/gh100.rs |   6 +-
 drivers/gpu/nova-core/fb/hal/tu102.rs |   8 ++-
 drivers/gpu/nova-core/fb/regs.rs      | 132 +++++++++++++++++++++++++++++++++-
 drivers/gpu/nova-core/regs.rs         | 127 --------------------------------
 8 files changed, 155 insertions(+), 142 deletions(-)

diff --git a/drivers/gpu/nova-core/fb.rs b/drivers/gpu/nova-core/fb.rs
index 864a34ca20b8..59e715b73479 100644
--- a/drivers/gpu/nova-core/fb.rs
+++ b/drivers/gpu/nova-core/fb.rs
@@ -275,8 +275,8 @@ pub(crate) fn new(chipset: Chipset, bar: Bar0<'_>, gsp_fw: &GspFirmware) -> Resu
 /// Returns `None` if the WPR2 region is not set.
 pub(crate) fn wpr2_range(bar: Bar0<'_>) -> Option<Range<u64>> {
     let (wpr2_lo, wpr2_hi) = (
-        bar.read(crate::regs::NV_PFB_PRI_MMU_WPR2_ADDR_LO),
-        bar.read(crate::regs::NV_PFB_PRI_MMU_WPR2_ADDR_HI),
+        bar.read(regs::NV_PFB_PRI_MMU_WPR2_ADDR_LO),
+        bar.read(regs::NV_PFB_PRI_MMU_WPR2_ADDR_HI),
     );
 
     if !wpr2_hi.is_wpr2_set() {
diff --git a/drivers/gpu/nova-core/fb/hal/ga100.rs b/drivers/gpu/nova-core/fb/hal/ga100.rs
index 3cc1caf361c7..d13c9a826eef 100644
--- a/drivers/gpu/nova-core/fb/hal/ga100.rs
+++ b/drivers/gpu/nova-core/fb/hal/ga100.rs
@@ -9,8 +9,10 @@
 
 use crate::{
     driver::Bar0,
-    fb::hal::FbHal,
-    regs, //
+    fb::{
+        hal::FbHal,
+        regs, //
+    },
 };
 
 use super::tu102::FLUSH_SYSMEM_ADDR_SHIFT;
@@ -41,7 +43,7 @@ pub(super) fn write_sysmem_flush_page_ga100(bar: Bar0<'_>, addr: u64) {
 }
 
 pub(super) fn display_enabled_ga100(bar: Bar0<'_>) -> bool {
-    !bar.read(regs::ga100::NV_FUSE_STATUS_OPT_DISPLAY)
+    !bar.read(crate::regs::ga100::NV_FUSE_STATUS_OPT_DISPLAY)
         .display_disabled()
 }
 
diff --git a/drivers/gpu/nova-core/fb/hal/gb100.rs b/drivers/gpu/nova-core/fb/hal/gb100.rs
index 6e0eba101ca1..ec55ec3fc7e1 100644
--- a/drivers/gpu/nova-core/fb/hal/gb100.rs
+++ b/drivers/gpu/nova-core/fb/hal/gb100.rs
@@ -22,9 +22,11 @@
 
 use crate::{
     driver::Bar0,
-    fb::hal::FbHal,
+    fb::{
+        hal::FbHal,
+        regs, //
+    },
     num::usize_into_u32,
-    regs, //
 };
 
 struct Gb100;
diff --git a/drivers/gpu/nova-core/fb/hal/gb202.rs b/drivers/gpu/nova-core/fb/hal/gb202.rs
index b78e0970f66d..69ba35d2ea08 100644
--- a/drivers/gpu/nova-core/fb/hal/gb202.rs
+++ b/drivers/gpu/nova-core/fb/hal/gb202.rs
@@ -12,8 +12,10 @@
 
 use crate::{
     driver::Bar0,
-    fb::hal::FbHal,
-    regs, //
+    fb::{
+        hal::FbHal,
+        regs, //
+    },
 };
 
 struct Gb202;
diff --git a/drivers/gpu/nova-core/fb/hal/gh100.rs b/drivers/gpu/nova-core/fb/hal/gh100.rs
index d39fe99537ed..2867ae058d0a 100644
--- a/drivers/gpu/nova-core/fb/hal/gh100.rs
+++ b/drivers/gpu/nova-core/fb/hal/gh100.rs
@@ -10,8 +10,10 @@
 
 use crate::{
     driver::Bar0,
-    fb::hal::FbHal,
-    regs, //
+    fb::{
+        hal::FbHal,
+        regs, //
+    },
 };
 
 struct Gh100;
diff --git a/drivers/gpu/nova-core/fb/hal/tu102.rs b/drivers/gpu/nova-core/fb/hal/tu102.rs
index f629e8e9d5d5..2ef04ccb550c 100644
--- a/drivers/gpu/nova-core/fb/hal/tu102.rs
+++ b/drivers/gpu/nova-core/fb/hal/tu102.rs
@@ -9,8 +9,10 @@
 
 use crate::{
     driver::Bar0,
-    fb::hal::FbHal,
-    regs, //
+    fb::{
+        hal::FbHal, //
+        regs,
+    },
 };
 
 /// Shift applied to the sysmem address before it is written into `NV_PFB_NISO_FLUSH_SYSMEM_ADDR`,
@@ -31,7 +33,7 @@ pub(super) fn write_sysmem_flush_page_gm107(bar: Bar0<'_>, addr: u64) -> Result
 }
 
 pub(super) fn display_enabled_gm107(bar: Bar0<'_>) -> bool {
-    !bar.read(regs::gm107::NV_FUSE_STATUS_OPT_DISPLAY)
+    !bar.read(crate::regs::gm107::NV_FUSE_STATUS_OPT_DISPLAY)
         .display_disabled()
 }
 
diff --git a/drivers/gpu/nova-core/fb/regs.rs b/drivers/gpu/nova-core/fb/regs.rs
index b2ec02f584be..b2baa4a2a85f 100644
--- a/drivers/gpu/nova-core/fb/regs.rs
+++ b/drivers/gpu/nova-core/fb/regs.rs
@@ -1,6 +1,9 @@
 // SPDX-License-Identifier: GPL-2.0
 
-use kernel::io::register;
+use kernel::{
+    io::register,
+    sizes::SizeConstants, //
+};
 
 // PDISP
 
@@ -23,3 +26,130 @@ pub(super) fn vga_workspace_addr(self) -> Option<u64> {
         }
     }
 }
+
+// PFB
+
+register! {
+    /// Low bits of the physical system memory address used by the GPU to perform sysmembar
+    /// operations (see [`super::fb::SysmemFlush`]).
+    pub(super) NV_PFB_NISO_FLUSH_SYSMEM_ADDR(u32) @ 0x00100c10 {
+        31:0    adr_39_08;
+    }
+
+    /// High bits of the physical system memory address used by the GPU to perform sysmembar
+    /// operations.
+    pub(super) NV_PFB_NISO_FLUSH_SYSMEM_ADDR_HI(u32) @ 0x00100c40 {
+        23:0    adr_63_40;
+    }
+
+    pub(super) NV_PFB_PRI_MMU_LOCAL_MEMORY_RANGE(u32) @ 0x00100ce0 {
+        30:30   ecc_mode_enabled => bool;
+        9:4     lower_mag;
+        3:0     lower_scale;
+    }
+
+    pub(super) NV_PFB_PRI_MMU_WPR2_ADDR_LO(u32) @ 0x001fa824 {
+        /// Bits 12..40 of the lower (inclusive) bound of the WPR2 region.
+        31:4    lo_val;
+    }
+
+    pub(super) NV_PFB_PRI_MMU_WPR2_ADDR_HI(u32) @ 0x001fa828 {
+        /// Bits 12..40 of the higher (exclusive) bound of the WPR2 region.
+        31:4    hi_val;
+    }
+}
+
+/// Base of the GB10x HSHUB0 register window (`NV_HSHUB0_PRIV_BASE` in Open RM).
+///
+/// The base is provided by the GB10x framebuffer HAL.
+pub(super) struct Hshub0Base(());
+
+register! {
+    // GB10x sysmem flush registers, relative to the HSHUB0 base. GB10x routes sysmembar
+    // through a primary and an EG (egress) pair that must both be programmed to the same
+    // address. Hardware ignores bits 7:0 of each LO register. The boot path uses a fixed
+    // HSHUB0 base, so the multiple runtime-discovered HSHUB bases are not needed here.
+    pub(super) NV_PFB_HSHUB_PCIE_FLUSH_SYSMEM_ADDR_LO(u32) @ Hshub0Base + 0x00000e50 {
+        31:0    adr => u32;
+    }
+
+    pub(super) NV_PFB_HSHUB_PCIE_FLUSH_SYSMEM_ADDR_HI(u32) @ Hshub0Base + 0x00000e54 {
+        19:0    adr;
+    }
+
+    pub(super) NV_PFB_HSHUB_EG_PCIE_FLUSH_SYSMEM_ADDR_LO(u32) @ Hshub0Base + 0x000006c0 {
+        31:0    adr => u32;
+    }
+
+    pub(super) NV_PFB_HSHUB_EG_PCIE_FLUSH_SYSMEM_ADDR_HI(u32) @ Hshub0Base + 0x000006c4 {
+        19:0    adr;
+    }
+}
+
+register! {
+    // GB20x FBHUB0 sysmem flush registers. Unlike the older
+    // NV_PFB_NISO_FLUSH_SYSMEM_ADDR registers, which encode the address with an
+    // 8-bit right-shift, these take the raw address split into lower and upper
+    // halves. Hardware ignores bits 7:0 of the LO register.
+    pub(super) NV_PFB_FBHUB0_PCIE_FLUSH_SYSMEM_ADDR_LO(u32) @ 0x008a1d58 {
+        31:0    adr => u32;
+    }
+
+    pub(super) NV_PFB_FBHUB0_PCIE_FLUSH_SYSMEM_ADDR_HI(u32) @ 0x008a1d5c {
+        19:0    adr;
+    }
+}
+
+register! {
+    /// Low bits of the physical system memory address used by the GPU to perform
+    /// sysmembar operations on Hopper.
+    ///
+    /// Like the GB20x FBHUB0 registers, and unlike the Ampere
+    /// `NV_PFB_NISO_FLUSH_SYSMEM_ADDR` registers (which encode the address with an
+    /// 8-bit right-shift), these take the raw address split into lower and upper
+    /// halves. Hardware ignores bits 7:0 of the LO register.
+    pub(super) NV_PFB_FBHUB_PCIE_FLUSH_SYSMEM_ADDR_LO(u32) @ 0x00100a34 {
+        31:0    adr => u32;
+    }
+
+    /// High bits of the physical system memory address used by the GPU to perform
+    /// sysmembar operations on Hopper.
+    pub(super) NV_PFB_FBHUB_PCIE_FLUSH_SYSMEM_ADDR_HI(u32) @ 0x00100a38 {
+        19:0    adr;
+    }
+}
+
+impl NV_PFB_PRI_MMU_LOCAL_MEMORY_RANGE {
+    /// Returns the usable framebuffer size, in bytes.
+    pub(super) fn usable_fb_size(self) -> u64 {
+        let size = (u64::from(self.lower_mag()) << u64::from(self.lower_scale())) * u64::SZ_1M;
+
+        if self.ecc_mode_enabled() {
+            // Remove the amount of memory reserved for ECC (one per 16 units).
+            size / 16 * 15
+        } else {
+            size
+        }
+    }
+}
+
+impl NV_PFB_PRI_MMU_WPR2_ADDR_LO {
+    /// Returns the lower (inclusive) bound of the WPR2 region.
+    pub(super) fn lower_bound(self) -> u64 {
+        u64::from(self.lo_val()) << 12
+    }
+}
+
+impl NV_PFB_PRI_MMU_WPR2_ADDR_HI {
+    /// Returns the higher (exclusive) bound of the WPR2 region.
+    ///
+    /// A value of zero means the WPR2 region is not set.
+    pub(super) fn higher_bound(self) -> u64 {
+        u64::from(self.hi_val()) << 12
+    }
+
+    /// Returns whether the WPR2 region is currently set.
+    pub(super) fn is_wpr2_set(self) -> bool {
+        self.hi_val() != 0
+    }
+}
diff --git a/drivers/gpu/nova-core/regs.rs b/drivers/gpu/nova-core/regs.rs
index 397124f245ee..f7304b27ae0c 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -116,133 +116,6 @@ fn fmt(&self, f: &mut kernel::fmt::Formatter<'_>) -> kernel::fmt::Result {
     }
 }
 
-// PFB
-
-register! {
-    /// Low bits of the physical system memory address used by the GPU to perform sysmembar
-    /// operations (see [`crate::fb::SysmemFlush`]).
-    pub(crate) NV_PFB_NISO_FLUSH_SYSMEM_ADDR(u32) @ 0x00100c10 {
-        31:0    adr_39_08;
-    }
-
-    /// High bits of the physical system memory address used by the GPU to perform sysmembar
-    /// operations.
-    pub(crate) NV_PFB_NISO_FLUSH_SYSMEM_ADDR_HI(u32) @ 0x00100c40 {
-        23:0    adr_63_40;
-    }
-
-    pub(crate) NV_PFB_PRI_MMU_LOCAL_MEMORY_RANGE(u32) @ 0x00100ce0 {
-        30:30   ecc_mode_enabled => bool;
-        9:4     lower_mag;
-        3:0     lower_scale;
-    }
-
-    pub(crate) NV_PFB_PRI_MMU_WPR2_ADDR_LO(u32) @ 0x001fa824 {
-        /// Bits 12..40 of the lower (inclusive) bound of the WPR2 region.
-        31:4    lo_val;
-    }
-
-    pub(crate) NV_PFB_PRI_MMU_WPR2_ADDR_HI(u32) @ 0x001fa828 {
-        /// Bits 12..40 of the higher (exclusive) bound of the WPR2 region.
-        31:4    hi_val;
-    }
-}
-
-/// Base of the GB10x HSHUB0 register window (`NV_HSHUB0_PRIV_BASE` in Open RM).
-///
-/// The base is provided by the GB10x framebuffer HAL.
-pub(crate) struct Hshub0Base(());
-
-register! {
-    // GB10x sysmem flush registers, relative to the HSHUB0 base. GB10x routes sysmembar
-    // through a primary and an EG (egress) pair that must both be programmed to the same
-    // address. Hardware ignores bits 7:0 of each LO register. The boot path uses a fixed
-    // HSHUB0 base, so the multiple runtime-discovered HSHUB bases are not needed here.
-    pub(crate) NV_PFB_HSHUB_PCIE_FLUSH_SYSMEM_ADDR_LO(u32) @ Hshub0Base + 0x00000e50 {
-        31:0    adr => u32;
-    }
-
-    pub(crate) NV_PFB_HSHUB_PCIE_FLUSH_SYSMEM_ADDR_HI(u32) @ Hshub0Base + 0x00000e54 {
-        19:0    adr;
-    }
-
-    pub(crate) NV_PFB_HSHUB_EG_PCIE_FLUSH_SYSMEM_ADDR_LO(u32) @ Hshub0Base + 0x000006c0 {
-        31:0    adr => u32;
-    }
-
-    pub(crate) NV_PFB_HSHUB_EG_PCIE_FLUSH_SYSMEM_ADDR_HI(u32) @ Hshub0Base + 0x000006c4 {
-        19:0    adr;
-    }
-}
-
-register! {
-    // GB20x FBHUB0 sysmem flush registers. Unlike the older
-    // NV_PFB_NISO_FLUSH_SYSMEM_ADDR registers, which encode the address with an
-    // 8-bit right-shift, these take the raw address split into lower and upper
-    // halves. Hardware ignores bits 7:0 of the LO register.
-    pub(crate) NV_PFB_FBHUB0_PCIE_FLUSH_SYSMEM_ADDR_LO(u32) @ 0x008a1d58 {
-        31:0    adr => u32;
-    }
-
-    pub(crate) NV_PFB_FBHUB0_PCIE_FLUSH_SYSMEM_ADDR_HI(u32) @ 0x008a1d5c {
-        19:0    adr;
-    }
-}
-
-register! {
-    /// Low bits of the physical system memory address used by the GPU to perform
-    /// sysmembar operations on Hopper.
-    ///
-    /// Like the GB20x FBHUB0 registers, and unlike the Ampere
-    /// `NV_PFB_NISO_FLUSH_SYSMEM_ADDR` registers (which encode the address with an
-    /// 8-bit right-shift), these take the raw address split into lower and upper
-    /// halves. Hardware ignores bits 7:0 of the LO register.
-    pub(crate) NV_PFB_FBHUB_PCIE_FLUSH_SYSMEM_ADDR_LO(u32) @ 0x00100a34 {
-        31:0    adr => u32;
-    }
-
-    /// High bits of the physical system memory address used by the GPU to perform
-    /// sysmembar operations on Hopper.
-    pub(crate) NV_PFB_FBHUB_PCIE_FLUSH_SYSMEM_ADDR_HI(u32) @ 0x00100a38 {
-        19:0    adr;
-    }
-}
-
-impl NV_PFB_PRI_MMU_LOCAL_MEMORY_RANGE {
-    /// Returns the usable framebuffer size, in bytes.
-    pub(crate) fn usable_fb_size(self) -> u64 {
-        let size = (u64::from(self.lower_mag()) << u64::from(self.lower_scale())) * u64::SZ_1M;
-
-        if self.ecc_mode_enabled() {
-            // Remove the amount of memory reserved for ECC (one per 16 units).
-            size / 16 * 15
-        } else {
-            size
-        }
-    }
-}
-
-impl NV_PFB_PRI_MMU_WPR2_ADDR_LO {
-    /// Returns the lower (inclusive) bound of the WPR2 region.
-    pub(crate) fn lower_bound(self) -> u64 {
-        u64::from(self.lo_val()) << 12
-    }
-}
-
-impl NV_PFB_PRI_MMU_WPR2_ADDR_HI {
-    /// Returns the higher (exclusive) bound of the WPR2 region.
-    ///
-    /// A value of zero means the WPR2 region is not set.
-    pub(crate) fn higher_bound(self) -> u64 {
-        u64::from(self.hi_val()) << 12
-    }
-
-    /// Returns whether the WPR2 region is currently set.
-    pub(crate) fn is_wpr2_set(self) -> bool {
-        self.hi_val() != 0
-    }
-}
-
 // PGC6 register space.
 //
 // `GC6` is a GPU low-power state where VRAM is in self-refresh and the GPU is powered down (except

-- 
2.55.0

