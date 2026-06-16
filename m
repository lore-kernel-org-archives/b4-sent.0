From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Wed, 17 Jun 2026 01:48:12 +0200
Subject: [PATCH 1/5] gpu: nova-core: fb: Move PDISP register definition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-nova-core-regs-split-v1-1-4c7dc4450ea7@nanonej.com>
References: <20260617-nova-core-regs-split-v1-0-4c7dc4450ea7@nanonej.com>
In-Reply-To: <20260617-nova-core-regs-split-v1-0-4c7dc4450ea7@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Antonin Malzieu Ridolfi <dev@nanonej.com>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, daniel.almeida@collabora.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2778; i=dev@nanonej.com;
 h=from:subject:message-id; bh=gfZ8p0lcgJadZ5MMUJuVLlpeInmCNJQIxDjgT106Pck=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqMeDImgHNj1U3GHegI63rytAyZVE1xsHPS2Q2z
 sgomRE6sXSJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCajHgyAAKCRBmh/EjChUV
 /ReoEACYsKid5SSONiRqQ2WbnmeF5NibxXQxRTdhTFqROcLGcn2YyyRQv5aV6R5UjjUGgN/ABSO
 B/cRnUq8oVjdFVd+qcNew3sIPs4LPIFSzseb0kRwA8HekerPUKOpQHJhIdFTSuGxnFVaLB/oc/y
 ASxiEV3NJ5DPG2acTlI4sJgh98UgLpZfeciIMv7ED176uuTABlmlO90E2mJpgPQSoakP0tXoU3K
 rrMcE3/fs/WX1E0QxQfiQWkpjxLy2tOkI3F/9M3dvj6unM1oEOdFoGPuZ3zuw1XhIErw/iBa05f
 UBNAaTUY8jX9SaG1H3dzQanHJW/gI14idHIsh/k3cIf8Yul2WNGdPEi5u78S+/dm9PLowzN62TC
 GJuIUzLqePtnjc019F7eXGtUkxc8nHKZ7Pu2MgOlib72zeGdY0aDeqR3eU6fTAQ+JXFxzVl37Nu
 gyQeYYyaHQBGompzFOqY0YtSOhqLPr/upCbHaOGmzrk+Xy8tgobCyBTX5KGFUxcmG7RkeWTNXTD
 DsV0mW/x/54zpT9wiOmII+IEVZeGq6AY0LcnbRoT4ZsuJlK7dFzCzpK6tBUF8pONF6XOsuh96RZ
 UMGoRp9Q4/9Wpcd9s4IQ/bSq1z20w7XZCwkRp5s/SDuJYUSWkWFw4nyh/lngg5ZD45ZLYsXtTBN
 AmZCT9TFgqIOcKg==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move PDISP register definition into fb module and update register
visibility.

Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
 drivers/gpu/nova-core/fb.rs      |  4 ++--
 drivers/gpu/nova-core/fb/regs.rs | 25 +++++++++++++++++++++++++
 drivers/gpu/nova-core/regs.rs    | 22 ----------------------
 3 files changed, 27 insertions(+), 24 deletions(-)

diff --git a/drivers/gpu/nova-core/fb.rs b/drivers/gpu/nova-core/fb.rs
index 725e428154cf..4385b5d53e85 100644
--- a/drivers/gpu/nova-core/fb.rs
+++ b/drivers/gpu/nova-core/fb.rs
@@ -23,11 +23,11 @@
     firmware::gsp::GspFirmware,
     gpu::Chipset,
     gsp,
-    num::FromSafeCast,
-    regs, //
+    num::FromSafeCast //
 };
 
 mod hal;
+mod regs;
 
 /// Type holding the sysmem flush memory page, a page of memory to be written into the
 /// `NV_PFB_NISO_FLUSH_SYSMEM_ADDR*` registers and used to maintain memory coherency.
diff --git a/drivers/gpu/nova-core/fb/regs.rs b/drivers/gpu/nova-core/fb/regs.rs
new file mode 100644
index 000000000000..b2ec02f584be
--- /dev/null
+++ b/drivers/gpu/nova-core/fb/regs.rs
@@ -0,0 +1,25 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use kernel::io::register;
+
+// PDISP
+
+register! {
+    pub(super) NV_PDISP_VGA_WORKSPACE_BASE(u32) @ 0x00625f04 {
+        /// VGA workspace base address divided by 0x10000.
+        31:8    addr;
+        /// Set if the `addr` field is valid.
+        3:3     status_valid => bool;
+    }
+}
+
+impl NV_PDISP_VGA_WORKSPACE_BASE {
+    /// Returns the base address of the VGA workspace, or `None` if none exists.
+    pub(super) fn vga_workspace_addr(self) -> Option<u64> {
+        if self.status_valid() {
+            Some(u64::from(self.addr()) << 16)
+        } else {
+            None
+        }
+    }
+}
diff --git a/drivers/gpu/nova-core/regs.rs b/drivers/gpu/nova-core/regs.rs
index 73339a0cff99..6a86ac05e59f 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -286,28 +286,6 @@ pub(crate) fn usable_fb_size(self) -> u64 {
     }
 }
 
-// PDISP
-
-register! {
-    pub(crate) NV_PDISP_VGA_WORKSPACE_BASE(u32) @ 0x00625f04 {
-        /// VGA workspace base address divided by 0x10000.
-        31:8    addr;
-        /// Set if the `addr` field is valid.
-        3:3     status_valid => bool;
-    }
-}
-
-impl NV_PDISP_VGA_WORKSPACE_BASE {
-    /// Returns the base address of the VGA workspace, or `None` if none exists.
-    pub(crate) fn vga_workspace_addr(self) -> Option<u64> {
-        if self.status_valid() {
-            Some(u64::from(self.addr()) << 16)
-        } else {
-            None
-        }
-    }
-}
-
 // FUSE
 
 pub(crate) const NV_FUSE_OPT_FPF_SIZE: usize = 16;

-- 
2.54.0

