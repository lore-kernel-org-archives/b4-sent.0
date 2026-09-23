From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Wed, 23 Sep 2026 02:41:09 +0200
Subject: [PATCH v2 3/4] gpu: nova-core: falcon: Extract PFALCON2 register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v2-3-74600fc068c4@nanonej.com>
References: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v2-0-74600fc068c4@nanonej.com>
In-Reply-To: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v2-0-74600fc068c4@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Alexandre Courbot <acourbot@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5383; i=dev@nanonej.com;
 h=from:subject:message-id; bh=uEjCwLXuSou0KLOnr17VjrbR1J6zpqA3OL9keelx+JA=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqsyA1WPk3r22tbiTc08Ipyaqe63YCsfhqMWBuq
 u0FpMQ6jCWJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCarMgNQAKCRBmh/EjChUV
 /U+VD/oD6pYIEx8Ek+Kjg6U1l9aj/07OO07kVC8jIQRPXAwMaia7p6iQwCm5QGYSUh4r3mhgsFb
 pCTHQheSFvqndX9Lmkwo/j3Rgp/cAUMPq6Amt1bnIKjMNgS+HG3p/S1NiKl+N6MrwxYl/7US/bh
 /ZGqHz9+grS/U4KozevWzBsTS8dK0d0bxhDsQNG8eVHQmUcLkZoUgiuwKDJSY2FRiQJ45JHFdw9
 rQ5VLHUXtcNq7rMV9/xSg0zmu2+2f8z2ver9qSL4nROE6vM7Navgp0Kbv7T3JxeYRK8hqVRaeMl
 c1aXuiEip1YebDc8PC41hPh0z/0PJtAn7gd2Pfn0mGNpHjRo5Ed3SZLsqmvLA6MawN9HAcDTV1S
 P+2u4rIKGYNevLBnJx11eG/qk9S2P0p7K3pLw+rYi0dtmxZSb8SJovW1sOIb0AjfD5QKvjp+zkU
 8vAGSVJmoRNi7bJRWNh7TxK47iay5xIqRcOP1y9NZ+VOJrO3l0/zbwKqlp7CckpWvehfyG97hZ1
 KxTiDuF6H2AGw93Udf2f3FjE17K5oSQPwXFnDbYHCEaVLIx0tpDLtmq9zX6+2gO/GkWAWix0Rhs
 Z2KqmkuiwFUQDPW86JOrGxAtcwktWaXF0ctEy1e0VbTEjs7Dcfv5a1ywYUAqkwgM3jhxs5SbDyX
 EerA/9KJHLWjC7g==
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
index 2ac71a7a4ec2..09ebaf5424d9 100644
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

