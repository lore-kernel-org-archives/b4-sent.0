From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Wed, 26 Aug 2026 01:44:20 +0200
Subject: [PATCH 3/4] gpu: nova-core: falcon: Extract PFALCON2 register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260826-b4-extract-pfsp-registers-to-falcon-mod-v1-3-38351df09084@nanonej.com>
References: <20260826-b4-extract-pfsp-registers-to-falcon-mod-v1-0-38351df09084@nanonej.com>
In-Reply-To: <20260826-b4-extract-pfsp-registers-to-falcon-mod-v1-0-38351df09084@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Alexandre Courbot <acourbot@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5391; i=dev@nanonej.com;
 h=from:subject:message-id; bh=+5srcIuDrPHxo7RqYT2/oVgDi4LJMOur/dkzKD5zi7M=;
 b=kA0DAAoBZofxIwoVFf0ByyZiAGqOKPigEFX4gzYbkVNU+kiYbYKv5cNg0JbSBYH7AAanev+ut
 okCMwQAAQoAHRYhBIO2T7B8kSEvUoUifWaH8SMKFRX9BQJqjij4AAoJEGaH8SMKFRX9zRMP/1Oq
 7PlxuHne//KCaYihnEfDK1WssNGU3vxB8hN0vsxVW3GgZUEcIEQWiENMppW5RZQDVWSl3iCzSJN
 kYEM+dy1hWVkC3l9siEh8oaRVK8pzBuCkijWCgPhSl2ga0TeqQn28/gPNixfd4F3BSd8VClJ677
 4zMI3PSLi7yyxFsDuu+HEWLVOi3JmzhtAJYdjcK9c8I7LQela5nWRzW4PmOQF2Z5pzHUj1qsZlL
 wmxmkDrrM2z9xTkhRONAufvIi7qRb70fFYeOURtqzvTbVQ9o2rStDH7+1yY6tck0JDEV+A0FThy
 lGS8bXJhUhl/SdT7ZmhxJkIvc8SMv1AVSGs/kr0CC8a4+7DFUZIEHxntA6BoGhoxlSopyY6o65D
 hHwzuGBV2V+a7sBQEMArY/UqQ6chSrRfDAVHJpxlJ+8yR3gIDipaLEHdlkUOkilFXWVSoiOQZ0B
 0eiGTbqanMlS0wudrUUKZh5j31NPdJMOPF+MESBgbL/FXPQkajeS8cMQp2IJs38aFS1uYZYCo2L
 JNix5UPxrXXABiDWsEcDazYhJ34/2AStRbYfVn01QP4A2qvYx+4XcewsQpkYtPwr/dbxfWTsgz8
 sIfNvwyBekDPMlil1pZ7uA9D17hKt5hK/oSbgRAmq+GUzk1BdYrHma6d4iDXNJdJED6Wt3BrN5m
 XRhO+
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
 drivers/gpu/nova-core/falcon/regs.rs | 31 ++++++++++++++++++++++++++-----
 drivers/gpu/nova-core/regs.rs        | 24 ------------------------
 3 files changed, 28 insertions(+), 31 deletions(-)

diff --git a/drivers/gpu/nova-core/falcon.rs b/drivers/gpu/nova-core/falcon.rs
index 68658a6e666c..11613a2ccb69 100644
--- a/drivers/gpu/nova-core/falcon.rs
+++ b/drivers/gpu/nova-core/falcon.rs
@@ -95,8 +95,8 @@ pub(crate) enum FalconSecurityModel with TryFrom<Bounded<u32, 2>> {
 
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
index a9e1f75598dd..446a67bdf3dd 100644
--- a/drivers/gpu/nova-core/falcon/regs.rs
+++ b/drivers/gpu/nova-core/falcon/regs.rs
@@ -3,10 +3,33 @@
 use kernel::io::register;
 
 use crate::falcon::{
+    FalconModSelAlgo,
     PFalcon2Base,
     PeregrineCoreSelect, //
 };
 
+// PFALCON2
+
+register! {
+    pub(super) NV_PFALCON2_FALCON_MOD_SEL(u32) @ PFalcon2Base + 0x00000180 {
+        7:0     algo ?=> FalconModSelAlgo;
+    }
+
+    pub(super) NV_PFALCON2_FALCON_BROM_CURR_UCODE_ID(u32) @ PFalcon2Base + 0x00000198 {
+        7:0    ucode_id => u8;
+    }
+
+    pub(super) NV_PFALCON2_FALCON_BROM_ENGIDMASK(u32) @ PFalcon2Base + 0x0000019c {
+        31:0    value => u32;
+    }
+
+    /// OpenRM defines this as a register array, but doesn't specify its size and only uses its
+    /// first element. Be conservative until we know the actual size or need to use more registers.
+    pub(super) NV_PFALCON2_FALCON_BROM_PARAADDR(u32)[1] @ PFalcon2Base + 0x00000210 {
+        31:0    value => u32;
+    }
+}
+
 // PRISCV
 
 register! {
@@ -52,16 +75,14 @@
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
index 5c1cef1c66a1..c9eca3ff911f 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -21,9 +21,7 @@
         FalconFbifMemType,
         FalconFbifTarget,
         FalconMem,
-        FalconModSelAlgo,
         FalconSecurityModel,
-        PFalcon2Base,
         PFalconBase, //
     },
 };
@@ -312,28 +310,6 @@ pub(crate) fn mem_scrubbing_done(self) -> bool {
     }
 }
 
-/* PFALCON2 */
-
-register! {
-    pub(crate) NV_PFALCON2_FALCON_MOD_SEL(u32) @ PFalcon2Base + 0x00000180 {
-        7:0     algo ?=> FalconModSelAlgo;
-    }
-
-    pub(crate) NV_PFALCON2_FALCON_BROM_CURR_UCODE_ID(u32) @ PFalcon2Base + 0x00000198 {
-        7:0    ucode_id => u8;
-    }
-
-    pub(crate) NV_PFALCON2_FALCON_BROM_ENGIDMASK(u32) @ PFalcon2Base + 0x0000019c {
-        31:0    value => u32;
-    }
-
-    /// OpenRM defines this as a register array, but doesn't specify its size and only uses its
-    /// first element. Be conservative until we know the actual size or need to use more registers.
-    pub(crate) NV_PFALCON2_FALCON_BROM_PARAADDR(u32)[1] @ PFalcon2Base + 0x00000210 {
-        31:0    value => u32;
-    }
-}
-
 // The modules below provide registers that are not identical on all supported chips. They should
 // only be used in HAL modules.
 

-- 
2.55.0

