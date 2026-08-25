From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Wed, 26 Aug 2026 01:44:18 +0200
Subject: [PATCH 1/4] gpu: nova-core: Extract PFSP register definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260826-b4-extract-pfsp-registers-to-falcon-mod-v1-1-38351df09084@nanonej.com>
References: <20260826-b4-extract-pfsp-registers-to-falcon-mod-v1-0-38351df09084@nanonej.com>
In-Reply-To: <20260826-b4-extract-pfsp-registers-to-falcon-mod-v1-0-38351df09084@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Alexandre Courbot <acourbot@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4995; i=dev@nanonej.com;
 h=from:subject:message-id; bh=wqNRbUL7XMnvvIqxJx4lZ57luQxlOACegl3jQUnJo0o=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqjij3/dpP0vSUEuzwVXkj3C1sJoZi6XZeb/ZGM
 OCfZJkiOaGJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCao4o9wAKCRBmh/EjChUV
 /QujEACUpjPN4T/0y6QabTddhhrPY3GIQtRQpv0+HN4RPeq16VPwC4JLyL45LFZ2Tf+mPfpVfcO
 mpQ/fGGXe0UE+C5OtAU1hYuGyARph/n1h5xBJIRlnP91ljwV3NkvblH1ZWq3WFozKLJkkTRmg0K
 3NrELsRpSo3V4gLPQqSbAn8PDKm5FLwz0f6XC8ZbkhvudLuZL4o6W3RxFEUVNaDC3oez9yh5VY7
 +xathCm9aKa4y2nOkIRkX00HqOc/V2xLTzJX5H7Vp35iSLlOna5q32IMzvHFEK0uW8KACt6BC5Y
 LJjU9gkkqiQ3uDvqZqPbTAh8y0NzrJUSf2TxuW//0NGWrWnITkmqDweKv924Q53SkaNHI0VcbA9
 Vo8PqGCtff23ER8NbhbywV0DBPdmEVfwxiomAoMGAqq6eox9GFjG540U5l5neTpfOCepQDM/Eih
 AZughzwPP2XqgjUGhExIA9uxxtvxIHXuHxI44gc6b8rTocAr1LZrBuGYuXLte/3xAiEB8sl8AcW
 8S0+kRccxjLppHaPhzm8k7XrYCqBJ82jDmi0maMZDbFlB6HpP7vvCL1l/hJnve5WCd9HzKzEsYx
 Ny8Lp3s9tySKp/Skfi8FIV+4tvHB0T346DV2QMiVTX5gxPh1IxflowskziXLmunxExRlIx2QpYh
 qiQBUR0HPYKiYIQ==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move PFSP register definitions from the root regs.rs file into the
falcon module that own them, in the new falcon/regs.rs file.

This follows the same pattern established by previous commits for
GSP, PDISP, PFB, PBUS and PMC registers: register definitions move to
the module that interprets their service, visibility changes to
pub(super).

Since PFALCON registers are defined in the root regs.rs but are
also part of the falcon interface, accessed by the whole falcon
module. They are re-exported in falcon/regs.rs so falcon code can use
a single regs:: prefix.
Once the PFALCON family moves out of the root module, these
re-exports will become plain definitions.

Suggested-by: Alexandre Courbot <acourbot@nvidia.com>
Suggested-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
 drivers/gpu/nova-core/falcon.rs      |  4 ++--
 drivers/gpu/nova-core/falcon/fsp.rs  |  6 +++---
 drivers/gpu/nova-core/falcon/regs.rs | 39 ++++++++++++++++++++++++++++++++++++
 drivers/gpu/nova-core/regs.rs        | 21 -------------------
 4 files changed, 44 insertions(+), 26 deletions(-)

diff --git a/drivers/gpu/nova-core/falcon.rs b/drivers/gpu/nova-core/falcon.rs
index 11c1008b7d1e..68658a6e666c 100644
--- a/drivers/gpu/nova-core/falcon.rs
+++ b/drivers/gpu/nova-core/falcon.rs
@@ -32,13 +32,13 @@
     num::{
         self,
         FromSafeCast, //
-    },
-    regs,
+    }, //
 };
 
 pub(crate) mod fsp;
 pub(crate) mod gsp;
 mod hal;
+mod regs;
 pub(crate) mod sec2;
 
 /// Alignment (in bytes) of falcon memory blocks.
diff --git a/drivers/gpu/nova-core/falcon/fsp.rs b/drivers/gpu/nova-core/falcon/fsp.rs
index 0437180b8829..c2bc61ecc07c 100644
--- a/drivers/gpu/nova-core/falcon/fsp.rs
+++ b/drivers/gpu/nova-core/falcon/fsp.rs
@@ -23,13 +23,13 @@
 
 use crate::{
     falcon::{
+        regs, //
         Falcon,
         FalconEngine,
         PFalcon2Base,
-        PFalconBase, //
+        PFalconBase,
     },
-    num,
-    regs, //
+    num, //
 };
 
 /// FSP message timeout in milliseconds.
diff --git a/drivers/gpu/nova-core/falcon/regs.rs b/drivers/gpu/nova-core/falcon/regs.rs
new file mode 100644
index 000000000000..96e1f0f1df5a
--- /dev/null
+++ b/drivers/gpu/nova-core/falcon/regs.rs
@@ -0,0 +1,39 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use kernel::io::register;
+
+// FSP (Foundation Security Processor) queue registers for Hopper/Blackwell Chain of Trust.
+// These registers manage falcon EMEM communication queues.
+
+register! {
+    pub(super) NV_PFSP_QUEUE_HEAD(u32)[8] @ 0x008f2c00 {
+        31:0    address => u32;
+    }
+
+    pub(super) NV_PFSP_QUEUE_TAIL(u32)[8] @ 0x008f2c04 {
+        31:0    address => u32;
+    }
+
+    pub(super) NV_PFSP_MSGQ_HEAD(u32)[8] @ 0x008f2c80 {
+        31:0    val => u32;
+    }
+
+    pub(super) NV_PFSP_MSGQ_TAIL(u32)[8] @ 0x008f2c84 {
+        31:0    val => u32;
+    }
+}
+
+// PFALCON registers are defined in the root `regs.rs` but are part of the falcon
+// interface, accessed by the whole falcon module. They are re-exported here so
+// falcon code can use a single `regs::` prefix.
+// Once the PFALCON family moves out of the root module, these re-exports become
+// plain definitions.
+pub(super) use crate::regs::{
+    NV_PFALCON_FALCON_BOOTVEC, NV_PFALCON_FALCON_CPUCTL, NV_PFALCON_FALCON_CPUCTL_ALIAS,
+    NV_PFALCON_FALCON_DMACTL, NV_PFALCON_FALCON_DMATRFBASE, NV_PFALCON_FALCON_DMATRFBASE1,
+    NV_PFALCON_FALCON_DMATRFCMD, NV_PFALCON_FALCON_DMATRFFBOFFS, NV_PFALCON_FALCON_DMATRFMOFFS,
+    NV_PFALCON_FALCON_DMEMC, NV_PFALCON_FALCON_DMEMD, NV_PFALCON_FALCON_EMEMC,
+    NV_PFALCON_FALCON_EMEMD, NV_PFALCON_FALCON_IMEMC, NV_PFALCON_FALCON_IMEMD,
+    NV_PFALCON_FALCON_IMEMT, NV_PFALCON_FALCON_MAILBOX0, NV_PFALCON_FALCON_MAILBOX1,
+    NV_PFALCON_FALCON_OS, NV_PFALCON_FALCON_RM, NV_PFALCON_FBIF_CTL, NV_PFALCON_FBIF_TRANSCFG,
+};
diff --git a/drivers/gpu/nova-core/regs.rs b/drivers/gpu/nova-core/regs.rs
index 3422b49df7a7..0404fb82aa7e 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -359,27 +359,6 @@ pub(crate) fn mem_scrubbing_done(self) -> bool {
     }
 }
 
-// FSP (Foundation Security Processor) queue registers for Hopper/Blackwell Chain of Trust.
-// These registers manage falcon EMEM communication queues.
-
-register! {
-    pub(crate) NV_PFSP_QUEUE_HEAD(u32)[8] @ 0x008f2c00 {
-        31:0    address => u32;
-    }
-
-    pub(crate) NV_PFSP_QUEUE_TAIL(u32)[8] @ 0x008f2c04 {
-        31:0    address => u32;
-    }
-
-    pub(crate) NV_PFSP_MSGQ_HEAD(u32)[8] @ 0x008f2c80 {
-        31:0    val => u32;
-    }
-
-    pub(crate) NV_PFSP_MSGQ_TAIL(u32)[8] @ 0x008f2c84 {
-        31:0    val => u32;
-    }
-}
-
 // The modules below provide registers that are not identical on all supported chips. They should
 // only be used in HAL modules.
 

-- 
2.55.0

