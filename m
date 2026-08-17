From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Mon, 17 Aug 2026 22:04:47 +0200
Subject: [PATCH] gpu: nova-core: Extract FUSE registers definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260817-b4-extract-fuse-registers-to-gpu-mod-v1-1-c4924070bbb0@nanonej.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23NSwqDMBSF4a1Ixr2QhzTqVoqDmFxtCj56kxRB3
 HvTWmgHHf5wON/GApLHwJpiY4QPH/w85RCngtmrmQYE73IzyeWZV0JDVwKukYyN0KeAQDj4EJE
 CxBmGJcE4OxBOcSf62ijNWb5aCHu/vplLe3RI3Q1tfH1/FoT3lP14zL58Uxw4L3/xZbT/bV0rR
 Ml1ZaRi7b4/AaB8s4vjAAAA
X-Change-ID: 20260817-b4-extract-fuse-registers-to-gpu-mod-1d30d1f9a370
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Alexandre Courbot <acourbot@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6957; i=dev@nanonej.com;
 h=from:subject:message-id; bh=TEU3cGdfr+0GsbAb4FDIovW/u3AWeIqXEMHGfNEojoU=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqg2lf1ctcM1fOoXqnXns/xyOEyIi9J+nyLlPLR
 Cn+mqLhPKOJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCaoNpXwAKCRBmh/EjChUV
 /eE2D/0eLW6yf5bwty+dotJUzHYlwaA7/HPEFsBGLyEhw08Tn0WSAnaUAgGYirdItO25j5Ihowg
 tOfe9zBnHXLNQMQERfBsO+PuSCFOyFoXO6N4TqOnmz9SV4wxH4OqiZpNwszQmdj0rhtB5Xo4vtc
 oZi5B25PhDItCqlPPLbW98bcdAJzYTi5WIWhNF5N3zg9TJ6WkIMWPcROZvtUrdhwqiynU+T9N6U
 PD1lVxiJ0QYAJMLxcpIN4X3rzFzBSzyrSPyt7GFJZGXOWjp+gxmk4kQfK1Hx40le/diaR8wHG53
 PXBXKobDFp93UFecq5pGJ5//7mpUajPKS2s1lRG4AmL4p/yAw9m1EhkcqVibPzZ6jpaa4klrwH5
 5fFzpgZP7lodtnxDld3Bo2oBdegLK7OUIUmRE94tmRqEkKv0sPxHWv6Z22KOtD0Ntspt9GToveh
 rvcsQIero237HsT5w5bctHf157QY+9MLY/dscCf3DWOuSPKtY1EYnqAPwddjqM7ROezg1PaaIvi
 nnQtIc8YoVSx01FfMAJ1kLz5pDmO2qj1lw9HHohMBaONtXdnUcZAUwj/NkekBG/4RUT1ES98vHG
 PvB9YwPKk/w/azFWnlgXYVA0+Z1K3q5h5M0Lv+845ljb4E0zaTx1fzYqXx4LtQxUnzGkGsy4WD/
 kFqM+BXxR24ejPg==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move FUSE register definitions from the root regs.rs file into the
gpu module that own them, in the existing gpu/regs.rs file.

This follows the same pattern established by previous commits for
GSP, PDISP, PFB, PBUS and PMC registers: register definitions move to
the module that owns them, visibility changes to pub(super), and
cross-module access is provided via pub(crate) helper functions.

Since gal102.rs (outside the gpu module) also reads fuse registers to
infer fuse version, a pub(crate) helper function fuse_ucode_version()
is added in gpu.rs to provide that information without exposing the
register type directly.

Suggested-by: Alexandre Courbot <acourbot@nvidia.com>
Suggested-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
I got several doubts regarding this patch:
- I didn't touch the comment in falcon/hal/ga102.rs:71 cause I didn't
  know if this information should stay there
- I'm not sure if the re-export of NV_FUSE_OPT_FPF_SIZE in gpu.rs is the
  right way to keep the read in gal102.rs or if I should also make an
helper to get its value
- Then, as I'm not quite sure to understand the exact purpose of the
code I'm not sure of the `fuse_ucode_version` naming and the comment
explaining what it do
---
 drivers/gpu/nova-core/falcon/hal/ga102.rs | 17 ++++-------------
 drivers/gpu/nova-core/gpu.rs              | 31 ++++++++++++++++++++++++++++++-
 drivers/gpu/nova-core/gpu/regs.rs         | 18 ++++++++++++++++++
 drivers/gpu/nova-core/regs.rs             | 18 ------------------
 4 files changed, 52 insertions(+), 32 deletions(-)

diff --git a/drivers/gpu/nova-core/falcon/hal/ga102.rs b/drivers/gpu/nova-core/falcon/hal/ga102.rs
index 7600ee07ca2e..590e30218527 100644
--- a/drivers/gpu/nova-core/falcon/hal/ga102.rs
+++ b/drivers/gpu/nova-core/falcon/hal/ga102.rs
@@ -7,7 +7,6 @@
     io::{
         poll::read_poll_timeout,
         register::{
-            Array,
             WithBase, //
         },
         Io, //
@@ -26,7 +25,8 @@
         FalconModSelAlgo,
         PeregrineCoreSelect, //
     },
-    regs,
+    gpu,
+    regs, //
 };
 
 use super::FalconHal;
@@ -59,7 +59,7 @@ fn signature_reg_fuse_version_ga102(
 ) -> Result<u32> {
     // Each engine has 16 ucode version registers numbered from 1 to 16.
     let ucode_idx = match usize::from(ucode_id) {
-        ucode_id @ 1..=regs::NV_FUSE_OPT_FPF_SIZE => ucode_id - 1,
+        ucode_id @ 1..=gpu::NV_FUSE_OPT_FPF_SIZE => ucode_id - 1,
         _ => {
             dev_err!(dev, "invalid ucode id {:#x}\n", ucode_id);
             return Err(EINVAL);
@@ -68,16 +68,7 @@ fn signature_reg_fuse_version_ga102(
 
     // `ucode_idx` is guaranteed to be in the range [0..15], making the `read` calls provable valid
     // at build-time.
-    let reg_fuse_version: u16 = if engine_id_mask & 0x0001 != 0 {
-        bar.read(regs::NV_FUSE_OPT_FPF_SEC2_UCODE1_VERSION::at(ucode_idx))
-            .data()
-    } else if engine_id_mask & 0x0004 != 0 {
-        bar.read(regs::NV_FUSE_OPT_FPF_NVDEC_UCODE1_VERSION::at(ucode_idx))
-            .data()
-    } else if engine_id_mask & 0x0400 != 0 {
-        bar.read(regs::NV_FUSE_OPT_FPF_GSP_UCODE1_VERSION::at(ucode_idx))
-            .data()
-    } else {
+    let Some(reg_fuse_version) = gpu::fuse_ucode_version(bar, engine_id_mask, ucode_idx) else {
         dev_err!(dev, "unexpected engine_id_mask {:#x}\n", engine_id_mask);
         return Err(EINVAL);
     };
diff --git a/drivers/gpu/nova-core/gpu.rs b/drivers/gpu/nova-core/gpu.rs
index 9e4232645a7e..746a7dec8906 100644
--- a/drivers/gpu/nova-core/gpu.rs
+++ b/drivers/gpu/nova-core/gpu.rs
@@ -6,7 +6,10 @@
     device,
     dma::Device,
     fmt,
-    io::Io,
+    io::{
+        register::Array,
+        Io, //
+    },
     num::Bounded,
     pci,
     prelude::*,
@@ -35,6 +38,8 @@
 mod hal;
 mod regs;
 
+pub(crate) use regs::NV_FUSE_OPT_FPF_SIZE;
+
 macro_rules! define_chipset {
     ({ $($variant:ident = $value:expr),* $(,)* }) =>
     {
@@ -419,3 +424,27 @@ pub(crate) fn new(
 pub(crate) fn boot_0_raw(bar: Bar0<'_>) -> u32 {
     bar.read(regs::NV_PMC_BOOT_0).into_raw()
 }
+
+/// Returns the fuse version matching `engine_id_mask`,
+/// at the given `ucode_idx`.
+/// Returns `None` if no engine matches `engine_id_mask`.
+pub(crate) fn fuse_ucode_version(
+    bar: Bar0<'_>,
+    engine_id_mask: u16,
+    ucode_idx: usize,
+) -> Option<u16> {
+    let version = if engine_id_mask & 0x0001 != 0 {
+        bar.read(regs::NV_FUSE_OPT_FPF_SEC2_UCODE1_VERSION::at(ucode_idx))
+            .data()
+    } else if engine_id_mask & 0x0004 != 0 {
+        bar.read(regs::NV_FUSE_OPT_FPF_NVDEC_UCODE1_VERSION::at(ucode_idx))
+            .data()
+    } else if engine_id_mask & 0x0400 != 0 {
+        bar.read(regs::NV_FUSE_OPT_FPF_GSP_UCODE1_VERSION::at(ucode_idx))
+            .data()
+    } else {
+        return None;
+    };
+
+    Some(version)
+}
diff --git a/drivers/gpu/nova-core/gpu/regs.rs b/drivers/gpu/nova-core/gpu/regs.rs
index 1c4db9625250..a6ce4ff44cd1 100644
--- a/drivers/gpu/nova-core/gpu/regs.rs
+++ b/drivers/gpu/nova-core/gpu/regs.rs
@@ -80,3 +80,21 @@ fn fmt(&self, f: &mut kernel::fmt::Formatter<'_>) -> kernel::fmt::Result {
         )
     }
 }
+
+// FUSE
+
+pub(crate) const NV_FUSE_OPT_FPF_SIZE: usize = 16;
+
+register! {
+    pub(super) NV_FUSE_OPT_FPF_NVDEC_UCODE1_VERSION(u32)[NV_FUSE_OPT_FPF_SIZE] @ 0x00824100 {
+        15:0    data => u16;
+    }
+
+    pub(super) NV_FUSE_OPT_FPF_SEC2_UCODE1_VERSION(u32)[NV_FUSE_OPT_FPF_SIZE] @ 0x00824140 {
+        15:0    data => u16;
+    }
+
+    pub(super) NV_FUSE_OPT_FPF_GSP_UCODE1_VERSION(u32)[NV_FUSE_OPT_FPF_SIZE] @ 0x008241c0 {
+        15:0    data => u16;
+    }
+}
diff --git a/drivers/gpu/nova-core/regs.rs b/drivers/gpu/nova-core/regs.rs
index 3422b49df7a7..562499ff6e08 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -94,24 +94,6 @@ pub(crate) fn usable_fb_size(self) -> u64 {
     }
 }
 
-// FUSE
-
-pub(crate) const NV_FUSE_OPT_FPF_SIZE: usize = 16;
-
-register! {
-    pub(crate) NV_FUSE_OPT_FPF_NVDEC_UCODE1_VERSION(u32)[NV_FUSE_OPT_FPF_SIZE] @ 0x00824100 {
-        15:0    data => u16;
-    }
-
-    pub(crate) NV_FUSE_OPT_FPF_SEC2_UCODE1_VERSION(u32)[NV_FUSE_OPT_FPF_SIZE] @ 0x00824140 {
-        15:0    data => u16;
-    }
-
-    pub(crate) NV_FUSE_OPT_FPF_GSP_UCODE1_VERSION(u32)[NV_FUSE_OPT_FPF_SIZE] @ 0x008241c0 {
-        15:0    data => u16;
-    }
-}
-
 // PFALCON
 
 register! {

---
base-commit: 60b5976d1367cd50314e867bc1169e759ab309b9
change-id: 20260817-b4-extract-fuse-registers-to-gpu-mod-1d30d1f9a370
prerequisite-change-id: 20260804-b4-extract-pmc-registers-to-gpu-mod-793ee2078a23

Best regards,
--  
Antonin Malzieu Ridolfi <dev@nanonej.com>

