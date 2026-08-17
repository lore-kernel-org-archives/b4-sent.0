From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Mon, 17 Aug 2026 18:51:08 +0200
Subject: [PATCH v2] gpu: nova-core: Extract PMC registers definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260817-b4-extract-pmc-registers-to-gpu-mod-v2-1-9dd1d599deb4@nanonej.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/5WOQQqDMBBFryJZd0qMVqOr3qO4iHGqEUxkEsUi3
 r3RnqDLB5/3/s48kkHP6mRnhKvxxtkI4pYwPSjbI5guMhNcFFzyHNoccAukdIB50kDYGx+QPAQ
 H/bzA5DooqwxR8FIqkbFomgnfZrsqr+bHfmlH1OFUn4shShx9rhtreu7+K64ppCALzWX1aAtei
 qdV1lkc79pNrDmO4wsvNfip6gAAAA==
X-Change-ID: 20260804-b4-extract-pmc-registers-to-gpu-mod-793ee2078a23
To: Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=9357; i=dev@nanonej.com;
 h=from:subject:message-id; bh=98NidU/GWke4x9fxgV7rWcy4dd8JhZ32lej/Yml+1VA=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqgzwILpHS3vi1dKPyEv7Lg9SY4u5WOwohGrtME
 zfZA2H/IXOJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCaoM8CAAKCRBmh/EjChUV
 /f59EACThr7kbKuHCTQvbWnJWHJBfdiL9tj2afMMGA6nVjrQhPgdeP5W80/V7caj0xSNPtNE/Vv
 rSwF8RBTXFuWp6kSMmnF5ylHXZ+wbYousN/w81L99/nGGkLFOEN0xypTRL0AhIdq0aW+rRZjkoA
 /nM1nYe3uIUpiaF3vXhAC7PBoaGNsSXMgTSBNjOb4ldakLxn9+g84ctAUgLLM1a3BBGBeBhiGZT
 nMYaEojFfwnbSPlaj3O6M7Twit+1vbtOk9fIpeovKtJ6C7EvPOyViej7mcqZK3HarKPphf1BXi6
 ngt66YPV6HUKOgvgvVWBm0cIzvYHSX5CZ1/fdEMeB6CDTcuV+WZMWWB4PVCWCK2W6H0e3LCywVh
 +vfJ/HYxFeHvPFEnh+wO1dTryvaQ3kvYKsU5/oeoIcd4tdakFqxvpvDFmFeFfeqhdHFvnuxpZFq
 Za5MFbkIAlQLGrWqT0JNkIsmDBqIsn75LN5a+/rv7ok4Bfq3JF0Tk6BPA1OIjFPAJEA6vSO/UZr
 kSS21koKsjb/00xzb3HudFO/+li0uNRp7lCRGZtXLMIWkc1K2Ie1Rd7bPnktz0IFySIT4Cd4zNA
 4bYnuKOWMEntIErtlvAnVUbJ5mZ6aI1e0hF2cB4LjVEgTTXu1T2utQIuG6SMJedCIx066mVLQkD
 6GphSHE6L3QzirQ==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move PMC register definitions (NV_PMC_BOOT_0, NV_PMC_BOOT_42) and
their associated implementations from the root regs.rs file into the
gpu module that own them, in the new gpu/regs.rs file.

This follows the same pattern established by previous commits for
GSP, PDISP, PFB, and PBUS registers: register definitions move to
the module that owns them, visibility changes to pub(super), and
cross-module access is provided via pub(crate) helper functions.

Since falcon.rs (outside the gpu module) also reads NV_PMC_BOOT_0 for
its raw value, a pub(crate) helper function boot_0_raw() is added in
gpu.rs to provide that access without exposing the register type
directly.

Suggested-by: Alexandre Courbot <acourbot@nvidia.com>
Suggested-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
Move PMC register definitions (NV_PMC_BOOT_0, NV_PMC_BOOT_42) and
their associated implementations from the root regs.rs file into the
gpu module that own them, in the new gpu/regs.rs file.

This follows the same pattern established by previous commits for
GSP, PDISP, PFB, and PBUS registers: register definitions move to
the module that owns them, visibility changes to pub(super), and
cross-module access is provided via pub(crate) helper functions.

Since falcon.rs (outside the gpu module) also reads NV_PMC_BOOT_0 for
its raw value, a pub(crate) helper function boot_0_raw() is added in
gpu.rs to provide that access without exposing the register type
directly.
---
Changes in v2:
- Fix unused import warning
- Add forgotten `Suggested-by` tags to the commit
- Link to v1: https://patch.msgid.link/20260804-b4-extract-pmc-registers-to-gpu-mod-v1-1-86c0895b6072@nanonej.com
---
 drivers/gpu/nova-core/falcon.rs   |  2 +-
 drivers/gpu/nova-core/gpu.rs      |  7 +++-
 drivers/gpu/nova-core/gpu/regs.rs | 82 +++++++++++++++++++++++++++++++++++++++
 drivers/gpu/nova-core/regs.rs     | 76 ------------------------------------
 4 files changed, 89 insertions(+), 78 deletions(-)

diff --git a/drivers/gpu/nova-core/falcon.rs b/drivers/gpu/nova-core/falcon.rs
index 65cb12d26e2b..11c1008b7d1e 100644
--- a/drivers/gpu/nova-core/falcon.rs
+++ b/drivers/gpu/nova-core/falcon.rs
@@ -394,7 +394,7 @@ pub(crate) fn reset(&self) -> Result {
 
         self.bar.write(
             WithBase::of::<E>(),
-            regs::NV_PFALCON_FALCON_RM::from(self.bar.read(regs::NV_PMC_BOOT_0).into_raw()),
+            regs::NV_PFALCON_FALCON_RM::from(crate::gpu::boot_0_raw(self.bar)),
         );
 
         Ok(())
diff --git a/drivers/gpu/nova-core/gpu.rs b/drivers/gpu/nova-core/gpu.rs
index 42a4cd7971fa..9e4232645a7e 100644
--- a/drivers/gpu/nova-core/gpu.rs
+++ b/drivers/gpu/nova-core/gpu.rs
@@ -29,11 +29,11 @@
         Gsp,
         GspBootContext, //
     },
-    regs,
     vgpu::VgpuManager, //
 };
 
 mod hal;
+mod regs;
 
 macro_rules! define_chipset {
     ({ $($variant:ident = $value:expr),* $(,)* }) =>
@@ -414,3 +414,8 @@ pub(crate) fn new(
         })
     }
 }
+
+/// Reads the boot0 register and returns its raw value.
+pub(crate) fn boot_0_raw(bar: Bar0<'_>) -> u32 {
+    bar.read(regs::NV_PMC_BOOT_0).into_raw()
+}
diff --git a/drivers/gpu/nova-core/gpu/regs.rs b/drivers/gpu/nova-core/gpu/regs.rs
new file mode 100644
index 000000000000..1c4db9625250
--- /dev/null
+++ b/drivers/gpu/nova-core/gpu/regs.rs
@@ -0,0 +1,82 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use kernel::{
+    io::register,
+    prelude::*, //
+};
+
+use super::{
+    Architecture,
+    Chipset, //
+};
+
+// PMC
+
+register! {
+    /// Basic revision information about the GPU.
+    pub(super) NV_PMC_BOOT_0(u32) @ 0x00000000 {
+        /// Lower bits of the architecture.
+        28:24   architecture_0;
+        /// Implementation version of the architecture.
+        23:20   implementation;
+        /// MSB of the architecture.
+        8:8     architecture_1;
+        /// Major revision of the chip.
+        7:4     major_revision;
+        /// Minor revision of the chip.
+        3:0     minor_revision;
+    }
+
+    /// Extended architecture information.
+    pub(super) NV_PMC_BOOT_42(u32) @ 0x00000a00 {
+        /// Architecture value.
+        29:24   architecture ?=> Architecture;
+        /// Implementation version of the architecture.
+        23:20   implementation;
+        /// Major revision of the chip.
+        19:16   major_revision;
+        /// Minor revision of the chip.
+        15:12   minor_revision;
+    }
+}
+
+impl NV_PMC_BOOT_0 {
+    pub(super) fn is_older_than_fermi(self) -> bool {
+        // From https://github.com/NVIDIA/open-gpu-doc/tree/master/manuals :
+        const NV_PMC_BOOT_0_ARCHITECTURE_GF100: u32 = 0xc;
+
+        // Older chips left arch1 zeroed out. That, combined with an arch0 value that is less than
+        // GF100, means "older than Fermi".
+        self.architecture_1() == 0 && self.architecture_0() < NV_PMC_BOOT_0_ARCHITECTURE_GF100
+    }
+}
+
+impl NV_PMC_BOOT_42 {
+    /// Combines `architecture` and `implementation` to obtain a code unique to the chipset.
+    pub(super) fn chipset(self) -> Result<Chipset> {
+        self.architecture()
+            .map(|arch| {
+                ((arch as u32) << Self::IMPLEMENTATION_RANGE.len())
+                    | u32::from(self.implementation())
+            })
+            .and_then(Chipset::try_from)
+    }
+
+    /// Returns the raw architecture value from the register.
+    fn architecture_raw(self) -> u8 {
+        ((self.into_raw() >> Self::ARCHITECTURE_RANGE.start())
+            & ((1 << Self::ARCHITECTURE_RANGE.len()) - 1)) as u8
+    }
+}
+
+impl kernel::fmt::Display for NV_PMC_BOOT_42 {
+    fn fmt(&self, f: &mut kernel::fmt::Formatter<'_>) -> kernel::fmt::Result {
+        write!(
+            f,
+            "boot42 = 0x{:08x} (architecture 0x{:x}, implementation 0x{:x})",
+            self.inner,
+            self.architecture_raw(),
+            self.implementation()
+        )
+    }
+}
diff --git a/drivers/gpu/nova-core/regs.rs b/drivers/gpu/nova-core/regs.rs
index caeef4d85874..3422b49df7a7 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -7,7 +7,6 @@
         register::WithBase,
         Io, //
     },
-    prelude::*,
     sizes::SizeConstants,
     time, //
 };
@@ -28,83 +27,8 @@
         PFalconBase,
         PeregrineCoreSelect, //
     },
-    gpu::{
-        Architecture,
-        Chipset, //
-    },
 };
 
-// PMC
-
-register! {
-    /// Basic revision information about the GPU.
-    pub(crate) NV_PMC_BOOT_0(u32) @ 0x00000000 {
-        /// Lower bits of the architecture.
-        28:24   architecture_0;
-        /// Implementation version of the architecture.
-        23:20   implementation;
-        /// MSB of the architecture.
-        8:8     architecture_1;
-        /// Major revision of the chip.
-        7:4     major_revision;
-        /// Minor revision of the chip.
-        3:0     minor_revision;
-    }
-
-    /// Extended architecture information.
-    pub(crate) NV_PMC_BOOT_42(u32) @ 0x00000a00 {
-        /// Architecture value.
-        29:24   architecture ?=> Architecture;
-        /// Implementation version of the architecture.
-        23:20   implementation;
-        /// Major revision of the chip.
-        19:16   major_revision;
-        /// Minor revision of the chip.
-        15:12   minor_revision;
-    }
-}
-
-impl NV_PMC_BOOT_0 {
-    pub(crate) fn is_older_than_fermi(self) -> bool {
-        // From https://github.com/NVIDIA/open-gpu-doc/tree/master/manuals :
-        const NV_PMC_BOOT_0_ARCHITECTURE_GF100: u32 = 0xc;
-
-        // Older chips left arch1 zeroed out. That, combined with an arch0 value that is less than
-        // GF100, means "older than Fermi".
-        self.architecture_1() == 0 && self.architecture_0() < NV_PMC_BOOT_0_ARCHITECTURE_GF100
-    }
-}
-
-impl NV_PMC_BOOT_42 {
-    /// Combines `architecture` and `implementation` to obtain a code unique to the chipset.
-    pub(crate) fn chipset(self) -> Result<Chipset> {
-        self.architecture()
-            .map(|arch| {
-                ((arch as u32) << Self::IMPLEMENTATION_RANGE.len())
-                    | u32::from(self.implementation())
-            })
-            .and_then(Chipset::try_from)
-    }
-
-    /// Returns the raw architecture value from the register.
-    fn architecture_raw(self) -> u8 {
-        ((self.into_raw() >> Self::ARCHITECTURE_RANGE.start())
-            & ((1 << Self::ARCHITECTURE_RANGE.len()) - 1)) as u8
-    }
-}
-
-impl kernel::fmt::Display for NV_PMC_BOOT_42 {
-    fn fmt(&self, f: &mut kernel::fmt::Formatter<'_>) -> kernel::fmt::Result {
-        write!(
-            f,
-            "boot42 = 0x{:08x} (architecture 0x{:x}, implementation 0x{:x})",
-            self.inner,
-            self.architecture_raw(),
-            self.implementation()
-        )
-    }
-}
-
 // PBUS
 
 register! {

---
base-commit: 4c9ba407018e8deb06dbc643112bac8f40404f95
change-id: 20260804-b4-extract-pmc-registers-to-gpu-mod-793ee2078a23

Best regards,
--  
Antonin Malzieu Ridolfi <dev@nanonej.com>

