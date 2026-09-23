From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Wed, 23 Sep 2026 03:09:27 +0200
Subject: [PATCH v3 3/4] gpu: nova-core: falcon: Extract PFALCON2 register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v3-3-cd26aa94c021@nanonej.com>
References: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v3-0-cd26aa94c021@nanonej.com>
In-Reply-To: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v3-0-cd26aa94c021@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Alexandre Courbot <acourbot@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5383; i=dev@nanonej.com;
 h=from:subject:message-id; bh=C/nr4kTzUQcwGSPhFgQPt+Y518RKzRQGa9yNT4hu2RY=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqsybTzHFfGwc43L+iL26GzZZQGMr8a+lJMFtTr
 M5pYzO+9jaJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCarMm0wAKCRBmh/EjChUV
 /WCJD/0TEERIbicy571QvrisXhg7Rd85jBQ4hR6VvcJOEafXXaxmNX74cWz3XerE89D2tjcGpnW
 WYaOM4etDSB/HYnl1+FW0OgS66UoeWIhHcDn122iyJfE90SLT2zxxX4TLjXFXoGHu8QV+CmqSk3
 vr9PWfUpRIrrPNABVx4FVZXFzM1RhicPbZv2M5OIIgau0QXHpQ+LTqFdH/DsgeDgPLt6Cioi1yu
 rN66aYM8RTcSd3YreUmfIry1jWP46heK5+RY5bxnYlo5lkKTWfuAdXjkqRJ+I76aM6JvQIuRAxg
 Ucot5IM+zpvCB3XEuQeD/G6dLdBCGGTamWDHd/gv4cdWMSOvAkyyhwxtlNMrn1k8epAzfNuDrBf
 tBkk1R25B0yFM6FpExhwqEXNoOD3dEQe3GEom1Ii8A2UHCP6TJ3g8MK4adL+8VjXUMmrae2n+NW
 vhE4RH7sIXY0pKVf5n4AWWHPlK1Q66hV9VHbGp9Ujek/Ob1Filb/xdec8/hpUMnCozZWmklVSoM
 LR4YzVXLk7thDXAfIYGWV1xv36vYwcDl0mFmhiutY2z2goYmet7GvejT8yGKcYEuWf8UM1/aKOG
 HRjADln6YrlRp5wnnATXseB++MAt1T8eJxVvD7qN5gpQoHY/mYZKVxDjawgcDWQUupPtPSTchQv
 DLycjP59Nm0I4Jg==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move PFALCON2 register definitions from the root regs.rs file into
the falcon module that own them, in the existing falcon/regs.rs file.

This follows the same pattern established by previous commits for
GSP, PDISP, PFB, PBUS, PMC, PFSP and PRISCV registers: register
definitions move to the module that interprets their service,
visibility changes to pub(super).

Suggested-by: Alexandre Courbot <acourbot@nvidia.com>
Suggested-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
 drivers/gpu/nova-core/falcon.rs      |  4 ++--
 drivers/gpu/nova-core/falcon/regs.rs | 33 ++++++++++++++++++++++++++++-----
 drivers/gpu/nova-core/regs.rs        | 26 --------------------------
 3 files changed, 30 insertions(+), 33 deletions(-)

diff --git a/drivers/gpu/nova-core/falcon.rs b/drivers/gpu/nova-core/falcon.rs
index 1900d642baa1..60cbd742bad7 100644
--- a/drivers/gpu/nova-core/falcon.rs
+++ b/drivers/gpu/nova-core/falcon.rs
@@ -94,8 +94,8 @@ pub(crate) enum FalconSecurityModel with TryFrom<Bounded<u32, 2>> {
 
 bounded_enum! {
     /// Signing algorithm for a given firmware, used in the
-    /// [`crate::regs::NV_PFALCON2_FALCON_MOD_SEL`] register. It is passed to the Falcon Boot ROM
-    /// (BROM) as a parameter.
+    /// [`crate::falcon::regs::NV_PFALCON2_FALCON_MOD_SEL`] register. It is passed to the Falcon
+    /// Boot ROM (BROM) as a parameter.
     #[derive(Debug, Copy, Clone)]
     pub(crate) enum FalconModSelAlgo with TryFrom<Bounded<u32, 8>> {
         /// AES.
diff --git a/drivers/gpu/nova-core/falcon/regs.rs b/drivers/gpu/nova-core/falcon/regs.rs
index ac4a02405927..205baf1b8b23 100644
--- a/drivers/gpu/nova-core/falcon/regs.rs
+++ b/drivers/gpu/nova-core/falcon/regs.rs
@@ -4,10 +4,35 @@
 use kernel::io::register;
 
 use crate::falcon::{
+    FalconModSelAlgo,
     PFalcon2Registers,
     PeregrineCoreSelect, //
 };
 
+// PFALCON2
+
+register! {
+    base: PFalcon2Registers;
+
+    pub(super) NV_PFALCON2_FALCON_MOD_SEL(u32) @ 0x00000180 {
+        7:0     algo ?=> FalconModSelAlgo;
+    }
+
+    pub(super) NV_PFALCON2_FALCON_BROM_CURR_UCODE_ID(u32) @ 0x00000198 {
+        7:0    ucode_id => u8;
+    }
+
+    pub(super) NV_PFALCON2_FALCON_BROM_ENGIDMASK(u32) @ 0x0000019c {
+        31:0    value => u32;
+    }
+
+    /// OpenRM defines this as a register array, but doesn't specify its size and only uses its
+    /// first element. Be conservative until we know the actual size or need to use more registers.
+    pub(super) NV_PFALCON2_FALCON_BROM_PARAADDR(u32)[1] @ 0x00000210 {
+        31:0    value => u32;
+    }
+}
+
 // PRISCV
 
 register! {
@@ -57,16 +82,14 @@
     }
 }
 
-// PFALCON, PFALCON2 and FUSE registers are defined in the root `regs.rs` but
-// are part of the falcon interface, accessed by the whole falcon module. They
+// PFALCON and FUSE registers are defined in the root `regs.rs` but are
+// part of the falcon interface, accessed by the whole falcon module. They
 // are re-exported here so falcon code can use a single `regs::` prefix.
 // Once these families move out of the root module, these re-exports become
 // plain definitions.
 pub(super) use crate::regs::{
     NV_FUSE_OPT_FPF_GSP_UCODE1_VERSION, NV_FUSE_OPT_FPF_NVDEC_UCODE1_VERSION,
-    NV_FUSE_OPT_FPF_SEC2_UCODE1_VERSION, NV_FUSE_OPT_FPF_SIZE,
-    NV_PFALCON2_FALCON_BROM_CURR_UCODE_ID, NV_PFALCON2_FALCON_BROM_ENGIDMASK,
-    NV_PFALCON2_FALCON_BROM_PARAADDR, NV_PFALCON2_FALCON_MOD_SEL, NV_PFALCON_FALCON_BOOTVEC,
+    NV_FUSE_OPT_FPF_SEC2_UCODE1_VERSION, NV_FUSE_OPT_FPF_SIZE, NV_PFALCON_FALCON_BOOTVEC,
     NV_PFALCON_FALCON_CPUCTL, NV_PFALCON_FALCON_CPUCTL_ALIAS, NV_PFALCON_FALCON_DMACTL,
     NV_PFALCON_FALCON_DMATRFBASE, NV_PFALCON_FALCON_DMATRFBASE1, NV_PFALCON_FALCON_DMATRFCMD,
     NV_PFALCON_FALCON_DMATRFFBOFFS, NV_PFALCON_FALCON_DMATRFMOFFS, NV_PFALCON_FALCON_DMEMC,
diff --git a/drivers/gpu/nova-core/regs.rs b/drivers/gpu/nova-core/regs.rs
index 0a168b53236d..13ccfd429e05 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -21,9 +21,7 @@
         FalconFbifMemType,
         FalconFbifTarget,
         FalconMem,
-        FalconModSelAlgo,
         FalconSecurityModel,
-        PFalcon2Registers,
         PFalconRegisters, //
     },
     mm::tlb::TlbAckMode, //
@@ -321,30 +319,6 @@ pub(crate) fn mem_scrubbing_done(self) -> bool {
     }
 }
 
-/* PFALCON2 */
-
-register! {
-    base: PFalcon2Registers;
-
-    pub(crate) NV_PFALCON2_FALCON_MOD_SEL(u32) @ 0x00000180 {
-        7:0     algo ?=> FalconModSelAlgo;
-    }
-
-    pub(crate) NV_PFALCON2_FALCON_BROM_CURR_UCODE_ID(u32) @ 0x00000198 {
-        7:0    ucode_id => u8;
-    }
-
-    pub(crate) NV_PFALCON2_FALCON_BROM_ENGIDMASK(u32) @ 0x0000019c {
-        31:0    value => u32;
-    }
-
-    /// OpenRM defines this as a register array, but doesn't specify its size and only uses its
-    /// first element. Be conservative until we know the actual size or need to use more registers.
-    pub(crate) NV_PFALCON2_FALCON_BROM_PARAADDR(u32)[1] @ 0x00000210 {
-        31:0    value => u32;
-    }
-}
-
 // The modules below provide registers that are not identical on all supported chips. They should
 // only be used in HAL modules.
 

-- 
2.55.0

