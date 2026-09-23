From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Wed, 23 Sep 2026 03:09:25 +0200
Subject: [PATCH v3 1/4] gpu: nova-core: Extract PFSP register definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v3-1-cd26aa94c021@nanonej.com>
References: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v3-0-cd26aa94c021@nanonej.com>
In-Reply-To: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v3-0-cd26aa94c021@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Alexandre Courbot <acourbot@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5168; i=dev@nanonej.com;
 h=from:subject:message-id; bh=iNKHZoLfFLYw78c3GCijvpikUhWdYQcglLUTmZXVb7g=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqsybTOg8K2k1eDtvN4HAihSEd33PtgzTiuScGb
 4oQpTLDsaCJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCarMm0wAKCRBmh/EjChUV
 /VdQD/9SlZG2q/Kw2H+7ua6pQDXZIWU1+X6Io6/Gy+OU5LN63fEqOk/lN2HjaD2bhDcHH8T0EB6
 RKJDdc2asWAIanHtsKgkvqTp3ajH/vY5zPSnSjglX4Kn0mT2BNmpt2NoSnd7CZw/Dv+45HvBk6w
 6FNk/4S+WUa+CjgnOVntFowhZcBnJBe68bftMlR0Nc+2HOqakGDq0FULgktwkhfimvgeEjBoAZK
 QWpq1UZQwVH6ISmJ+EcZU/29egG9aBPeI7iHMuqxHklDfrCEvYdav/6AGmHPSAPhLVgEoLwOCy/
 tB8zJPySvcuAqoA7YLHHgcw+PbwC/BdyNdV8i+SdJ3PDEFEVXfRclMzOcm07iD3kcDFlc2OKKit
 CVYpvRAgtj5JSmP8Ql/UjILcWJqwmAwcyGcxeXzXLfDjZfRwoJjHcPPXVBelWUaQJ01x/n1Nyfx
 qmOZGycHc+6rD2xguDE9Uoy29nhCOor8iBbxM6kKla/g0n7b91WAclF6IGCZJPSNSSBt/sskjUc
 kXHem16KJZn/iWA/vjj4ntAak81au0dQjfW9XuYPBcprFLK6sC04IVGjFn/ED75BQa1WCcjFeQU
 QlecYz3F2ZCfsph9lObeXOeGivPS5mHgG+nsioo5WtM36QH4Gr6OLzgqTkifjEMJ/eG12f5n8R7
 Zq/3jA0VgT7nPXw==
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
module, they are re-exported in falcon/regs.rs so falcon code can use
a single regs:: prefix.
Once the PFALCON family moves out of the root module, these
re-exports will become plain definitions.

Suggested-by: Alexandre Courbot <acourbot@nvidia.com>
Suggested-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
 drivers/gpu/nova-core/falcon.rs      |  4 ++--
 drivers/gpu/nova-core/falcon/fsp.rs  |  6 +++---
 drivers/gpu/nova-core/falcon/regs.rs | 42 ++++++++++++++++++++++++++++++++++++
 drivers/gpu/nova-core/regs.rs        | 23 --------------------
 4 files changed, 47 insertions(+), 28 deletions(-)

diff --git a/drivers/gpu/nova-core/falcon.rs b/drivers/gpu/nova-core/falcon.rs
index 9015de965a53..1900d642baa1 100644
--- a/drivers/gpu/nova-core/falcon.rs
+++ b/drivers/gpu/nova-core/falcon.rs
@@ -31,13 +31,13 @@
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
index 85f9c8c5d60e..2bd8674f27a1 100644
--- a/drivers/gpu/nova-core/falcon/fsp.rs
+++ b/drivers/gpu/nova-core/falcon/fsp.rs
@@ -17,7 +17,7 @@
     },
     prelude::*,
     sizes::SZ_1K,
-    time::Delta,
+    time::Delta, //
 };
 
 use crate::{
@@ -26,11 +26,11 @@
         NovaRegisters, //
     },
     falcon::{
+        regs,
         Falcon,
         FalconEngine, //
     },
-    num,
-    regs, //
+    num, //
 };
 
 /// FSP message timeout in milliseconds.
diff --git a/drivers/gpu/nova-core/falcon/regs.rs b/drivers/gpu/nova-core/falcon/regs.rs
new file mode 100644
index 000000000000..336f065929db
--- /dev/null
+++ b/drivers/gpu/nova-core/falcon/regs.rs
@@ -0,0 +1,42 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use crate::driver::NovaRegisters;
+use kernel::io::register;
+
+// FSP (Foundation Security Processor) queue registers for Hopper/Blackwell Chain of Trust.
+// These registers manage falcon EMEM communication queues.
+
+register! {
+    base: NovaRegisters;
+
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
index 9978fb2803b0..693b5148b1d8 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -372,29 +372,6 @@ pub(crate) fn mem_scrubbing_done(self) -> bool {
     }
 }
 
-// FSP (Foundation Security Processor) queue registers for Hopper/Blackwell Chain of Trust.
-// These registers manage falcon EMEM communication queues.
-
-register! {
-    base: NovaRegisters;
-
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

