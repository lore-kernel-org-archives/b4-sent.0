From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Mon, 27 Jul 2026 17:51:52 +0200
Subject: [PATCH v2 2/3] gpu: nova-core: Move PFB registers definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260727-nova-core-regs-split-v2-2-21b5e6e32ea5@nanonej.com>
References: <20260727-nova-core-regs-split-v2-0-21b5e6e32ea5@nanonej.com>
In-Reply-To: <20260727-nova-core-regs-split-v2-0-21b5e6e32ea5@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, daniel.almeida@collabora.com, 
 Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=14488; i=dev@nanonej.com;
 h=from:subject:message-id; bh=xr5w4a/wy5PAYiBxGbjBR9GmBVzfPwBR1s2YeoKgvrQ=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqZ36YU41u5hLWzKcp2lmMvcexdnuCg4wIXyrvS
 /oq8ztZDs+JAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCamd+mAAKCRBmh/EjChUV
 /RNmD/4kgp5zNy3ekTeafhJA6F9xJZ66wb1+AI7ojIYiQXt9H3OJ5y6ZNVz1mFHzNYXY79tJ9eI
 NY+Vhs+dAUTpfremaQgMtN/XTWqVWwAegt21Y0g1+3UafZ3bJtuax5hDvlLBBru2KHvHgkgE4Sb
 +KOP+jEnAWHXF62Ow4JC0SsN+XwbC2CkcoDmsZgcoWwJ/ylyv8h+2jIcliKX+0OAwr20X7iO3mZ
 QVu+T1VpPlTOlqslQslSUpAas0dYILoTs7wT2tW4i0igb89RrV2cKShS2Twm4tsWKiJbCnphS88
 EW01TBMk+J7DkNeHtXizpC5hkMVuwopd6hub+kScN7B3NEUu9dAjHaBqRSk6CZmO3oaecwe+OEv
 g4l67VhVE45HnJLFlJvxWkT82SqxeggtH4Cd47vAMlLUAT5040J3o5+vLuqDABANWC2JsTQ14uF
 5FdJRwb7JK+Ki81f+Lz8YB9/rDQf+V7O/02/MlJiYzwhGOmFS1AeltuEYImbNVAmq5kDc3K/HYB
 E6sU93AtztBRSJD6cuoFvOTubbdLXlQZJ1DAIckZFN3apocLhP1azOA4wXKoqaq8q9HOdn2sTE/
 /dd5aURkV5xGne0XPuqmu2GuvDNuhaFL/exEokTzUX4WLt0ZqnnfLMI+dDOQYD3sXkmHI5xq8Ai
 4+K+cosdo0fPsfQ==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move PFB registers definitions into fb module and update registers
visibility.

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
index 8934efc5f436..9e475efb1150 100644
--- a/drivers/gpu/nova-core/fb.rs
+++ b/drivers/gpu/nova-core/fb.rs
@@ -293,13 +293,13 @@ pub(crate) fn new(
 /// Reads the WPR2 memory region registers and returns the range if set.
 /// Returns `None` if the WPR2 region is not set.
 pub(crate) fn wpr2_range(bar: Bar0<'_>) -> Option<Range<u64>> {
-    let wpr2_hi = bar.read(crate::regs::NV_PFB_PRI_MMU_WPR2_ADDR_HI);
+    let wpr2_hi = bar.read(regs::NV_PFB_PRI_MMU_WPR2_ADDR_HI);
 
     if !wpr2_hi.is_wpr2_set() {
         return None;
     }
 
-    let wpr2_lo = bar.read(crate::regs::NV_PFB_PRI_MMU_WPR2_ADDR_LO);
+    let wpr2_lo = bar.read(regs::NV_PFB_PRI_MMU_WPR2_ADDR_LO);
 
     Some(wpr2_lo.lower_bound()..wpr2_hi.higher_bound())
 }
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
index f629e8e9d5d5..541f163b52d3 100644
--- a/drivers/gpu/nova-core/fb/hal/tu102.rs
+++ b/drivers/gpu/nova-core/fb/hal/tu102.rs
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
 
 /// Shift applied to the sysmem address before it is written into `NV_PFB_NISO_FLUSH_SYSMEM_ADDR`,
@@ -31,7 +33,7 @@ pub(super) fn write_sysmem_flush_page_gm107(bar: Bar0<'_>, addr: u64) -> Result
 }
 
 pub(super) fn display_enabled_gm107(bar: Bar0<'_>) -> bool {
-    !bar.read(regs::gm107::NV_FUSE_STATUS_OPT_DISPLAY)
+    !bar.read(crate::regs::gm107::NV_FUSE_STATUS_OPT_DISPLAY)
         .display_disabled()
 }
 
diff --git a/drivers/gpu/nova-core/fb/regs.rs b/drivers/gpu/nova-core/fb/regs.rs
index b2ec02f584be..95adbe124a30 100644
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
+    /// operations (see [`crate::fb::SysmemFlush`]).
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
index 49591c3dcfa7..d58dc6dd0f04 100644
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

