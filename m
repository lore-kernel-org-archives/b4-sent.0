From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Wed, 17 Jun 2026 01:48:16 +0200
Subject: [PATCH 5/5] gpu: nova-core: falcon: Move PFSP register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-nova-core-regs-split-v1-5-4c7dc4450ea7@nanonej.com>
References: <20260617-nova-core-regs-split-v1-0-4c7dc4450ea7@nanonej.com>
In-Reply-To: <20260617-nova-core-regs-split-v1-0-4c7dc4450ea7@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Antonin Malzieu Ridolfi <dev@nanonej.com>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, daniel.almeida@collabora.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4371; i=dev@nanonej.com;
 h=from:subject:message-id; bh=e+RPTcJ/xqY9sHKEN1ysB3kpbYR3hnWcV9YH6i5vuxU=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqMeDJ4E5hAWmWx4y3VvMopq0DVgL/2pcl9FH29
 pnFkkAGyDKJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCajHgyQAKCRBmh/EjChUV
 /WflD/9MiIELe1VPjb4tX9A/cmkMlc8bmGDZTnTFXaPhCqJ2oZHQrg0e8fl2/etB4aSdDfuNaHq
 lRMAVOHR0qPlGnonBJjMpEUbsszD0dG9ljDztVPxK3l37+P9qTFqwEfQecv9fYZqAqmvk2aCBFA
 VQPysLVNZY5g06eDg5WYXAVAvpFzUxfCaO3Be6kX8DtNIrvzy+pWXWwpHwlqIXbH67Fs9b0w1QH
 bW07HRiuSDSSd2JtyuNuIDHvIk9MbsAlBjIw6QluvcsFfZ/WfN8bfbSKLxolTLT0Yi/sg+9ULwI
 l/TEih/M0pSM2mlW6qwVfjtP5k+smb4SVlMGwi7dqg/XIoqwnKbGSRptuZamvX9cPRw4GqoYRjl
 kp+XRqdSyp4+S4GQj6sKmtNOktPfru4QsDh6Zt9adxuNT7naC17AsuJ1NlVl2QCWjfPhN5rHKMq
 ztVZNgQcXE+jZK6u2pnizlzPib1TIYPQIDZpfzUC+GaazC74EnJr4Dmr6ZA10NwJ9yyLETaaHuA
 PBLcIPE69xA5S2eE1ve6+M5vv0rg2CXhgzWFbCP8YnWBZ+nBMfzYLjSVeIkqi287oODs3fgPqyW
 MXE/n24lBcU6T/zab3VyK7s50U5fYLzw4bsbdd3F5opurpYRmPbZu7v+Bj1wKFSlF7Sgu8NjBuz
 Vi9E4730HtMp3HA==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move PFSP register definition into falcon module and update registers
visibility.

Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
 drivers/gpu/nova-core/falcon/fsp.rs  | 14 +++++++-------
 drivers/gpu/nova-core/falcon/regs.rs | 21 +++++++++++++++++++++
 drivers/gpu/nova-core/regs.rs        | 21 ---------------------
 3 files changed, 28 insertions(+), 28 deletions(-)

diff --git a/drivers/gpu/nova-core/falcon/fsp.rs b/drivers/gpu/nova-core/falcon/fsp.rs
index 52cdb84ef0e8..547843e6483c 100644
--- a/drivers/gpu/nova-core/falcon/fsp.rs
+++ b/drivers/gpu/nova-core/falcon/fsp.rs
@@ -26,10 +26,10 @@
         Falcon,
         FalconEngine,
         PFalcon2Base,
-        PFalconBase, //
+        PFalconBase,
+        regs, //
     },
-    num,
-    regs, //
+    num, //
 };
 
 /// FSP message timeout in milliseconds.
@@ -61,7 +61,7 @@ fn write_emem(&mut self, bar: Bar0<'_>, data: &[u8]) -> Result {
         // Begin a write burst at offset `0`, auto-incrementing on each write.
         bar.write(
             WithBase::of::<Fsp>(),
-            regs::NV_PFALCON_FALCON_EMEMC::zeroed().with_aincw(true),
+            crate::regs::NV_PFALCON_FALCON_EMEMC::zeroed().with_aincw(true),
         );
 
         for chunk in data.chunks_exact(4) {
@@ -70,7 +70,7 @@ fn write_emem(&mut self, bar: Bar0<'_>, data: &[u8]) -> Result {
             // Write the next 32-bit `value`; hardware advances the offset.
             bar.write(
                 WithBase::of::<Fsp>(),
-                regs::NV_PFALCON_FALCON_EMEMD::zeroed().with_data(value),
+                crate::regs::NV_PFALCON_FALCON_EMEMD::zeroed().with_data(value),
             );
         }
 
@@ -89,12 +89,12 @@ fn read_emem(&mut self, bar: Bar0<'_>, data: &mut [u8]) -> Result {
         // Begin a read burst at offset `0`, auto-incrementing on each read.
         bar.write(
             WithBase::of::<Fsp>(),
-            regs::NV_PFALCON_FALCON_EMEMC::zeroed().with_aincr(true),
+            crate::regs::NV_PFALCON_FALCON_EMEMC::zeroed().with_aincr(true),
         );
 
         for chunk in data.chunks_exact_mut(4) {
             // Read the next 32-bit word; hardware advances the offset.
-            let value = bar.read(regs::NV_PFALCON_FALCON_EMEMD::of::<Fsp>()).data();
+            let value = bar.read(crate::regs::NV_PFALCON_FALCON_EMEMD::of::<Fsp>()).data();
             chunk.copy_from_slice(&value.to_le_bytes());
         }
 
diff --git a/drivers/gpu/nova-core/falcon/regs.rs b/drivers/gpu/nova-core/falcon/regs.rs
index 4d4e69b235fc..81530abfb54c 100644
--- a/drivers/gpu/nova-core/falcon/regs.rs
+++ b/drivers/gpu/nova-core/falcon/regs.rs
@@ -53,3 +53,24 @@
         0:0     valid => bool;
     }
 }
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
diff --git a/drivers/gpu/nova-core/regs.rs b/drivers/gpu/nova-core/regs.rs
index b21a5adc723a..9069aeff1ee4 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -491,27 +491,6 @@ pub(crate) fn mem_scrubbing_done(self) -> bool {
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
2.54.0

