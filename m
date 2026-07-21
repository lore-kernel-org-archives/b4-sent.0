From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Tue, 21 Jul 2026 17:41:09 +0200
Subject: [PATCH 3/3] gpu: nova-core: Move one PBUS register definition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260721-nova-core-regs-split-v1-3-384fa2a42244@nanonej.com>
References: <20260721-nova-core-regs-split-v1-0-384fa2a42244@nanonej.com>
In-Reply-To: <20260721-nova-core-regs-split-v1-0-384fa2a42244@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, daniel.almeida@collabora.com, 
 Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2078; i=dev@nanonej.com;
 h=from:subject:message-id; bh=bO+SB+QdzWlFEnKzthXbRE6mmjHZMmu3RJMJ0HXXY+c=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqX5Mt4IxqTt5dVTWxHBWYyBEDhr7RLWoOGDk3h
 AuNZoGhPPqJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCal+TLQAKCRBmh/EjChUV
 /bprD/9Mkj9a4c8Z0kei+Bm3WJHQ9mUI18uUqtuwOEDF7pOwqtbhcSK0S1PGpmah3//8SUjekR7
 MGa3vJv9Ahg8g8joDzOy5R2RwZWYca7gD3N0Tvw4wqMjD07vO5/3VvLHraGoe/6YtZm+3d41QsO
 hH74Xc6TzQAfUWdN0nr0NG9JLO0MX64aT+v+0UVEMKEZET4VAU8R0VTqflC4WzGreDM8UfTNhWV
 +T1LzXato0K1zUxmKdsWTvz0WqKA/UbydXkTqKmRx70ZFPKTUyQWhLcyXumlQQC8/H+fXTcqS2l
 NeHe/ZrO8dYs/jKS1OPIUrBSynkvusfXOZ45bj4ib+2SuvlGvDvHECBp7vemtldwTqBImIvJ+Ml
 bPyDX7A9P/v8jPMHkv35ViQUimt4PaVCB+nTaK77n94+AxpuJa43v3x+S+xFj6t0ipnYQgEwVkP
 chsIkLSiVLihToVGkukrv8dNq+PxyHYCAz1shRFbIPvav8lW+mCqOiNMg8HqT0PcyykICVFLSkI
 WfTYwMYgS2c5w6bWG9iKhWYyxoKSixWHkd4wfSviTW92GsZy+xXGtx+akLIqGn8Pt6wIUXDLyQa
 fvoJt8Tq4hyiLjJYyiUVvbeIpifbpSXIelWlLW8qXbCkKBb4sulsbYMK+/0wzhwmGpqmC3RXvm9
 VJBMD3eQD6M9ieg==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Suggested-by: Alexandre Courbot <acourbot@nvidia.com>
Suggested-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
 drivers/gpu/nova-core/gsp/hal/tu102.rs |  2 +-
 drivers/gpu/nova-core/gsp/regs.rs      | 11 +++++++++++
 drivers/gpu/nova-core/regs.rs          |  5 -----
 3 files changed, 12 insertions(+), 6 deletions(-)

diff --git a/drivers/gpu/nova-core/gsp/hal/tu102.rs b/drivers/gpu/nova-core/gsp/hal/tu102.rs
index b3242aaeea45..91b995c2ee57 100644
--- a/drivers/gpu/nova-core/gsp/hal/tu102.rs
+++ b/drivers/gpu/nova-core/gsp/hal/tu102.rs
@@ -40,12 +40,12 @@
             GspHal,
             UnloadBundle, //
         },
+        regs,
         sequencer::GspSequencer,
         Gsp,
         GspBootContext,
         GspFwWprMeta, //
     },
-    regs,
     vbios::Vbios, //
 };
 
diff --git a/drivers/gpu/nova-core/gsp/regs.rs b/drivers/gpu/nova-core/gsp/regs.rs
index a76dea3c3ab0..9a48aa87e7fb 100644
--- a/drivers/gpu/nova-core/gsp/regs.rs
+++ b/drivers/gpu/nova-core/gsp/regs.rs
@@ -2,6 +2,8 @@
 
 use kernel::io::register;
 
+use crate::regs::NV_PBUS_SW_SCRATCH;
+
 // PGSP
 
 register! {
@@ -9,3 +11,12 @@
         31:0    address;
     }
 }
+
+// PBUS
+
+register! {
+    /// Scratch register 0xe used as FRTS firmware error code.
+    pub(super) NV_PBUS_SW_SCRATCH_0E_FRTS_ERR(u32) => NV_PBUS_SW_SCRATCH[0xe] {
+        31:16   frts_err_code;
+    }
+}
diff --git a/drivers/gpu/nova-core/regs.rs b/drivers/gpu/nova-core/regs.rs
index f7304b27ae0c..dda3be837f62 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -109,11 +109,6 @@ fn fmt(&self, f: &mut kernel::fmt::Formatter<'_>) -> kernel::fmt::Result {
 
 register! {
     pub(crate) NV_PBUS_SW_SCRATCH(u32)[64] @ 0x00001400 {}
-
-    /// Scratch register 0xe used as FRTS firmware error code.
-    pub(crate) NV_PBUS_SW_SCRATCH_0E_FRTS_ERR(u32) => NV_PBUS_SW_SCRATCH[0xe] {
-        31:16   frts_err_code;
-    }
 }
 
 // PGC6 register space.

-- 
2.55.0

