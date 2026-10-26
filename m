From: Dave Airlie <airlied@redhat.com>
Date: Mon, 26 Oct 2026 13:50:36 +1000
Subject: [PATCH] gpu: nova-core: make bar1 optional
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-nova-bar1-option-v1-1-8b43585881a3@redhat.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDINbNyy9L1E1KLDLUzS8oASrWNTEwTzNMM7FMSzFMVgJqKyhKTcusABs
 ZHVtbCwDUigH0YgAAAA==
X-Change-ID: 20261026-nova-bar1-option-407f1f49fd1c
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Alexandre Courbot <acourbot@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Benno Lossin <lossin@kernel.org>, Gary Guo <gary@garyguo.net>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=6274; i=airlied@redhat.com;
 h=from:subject:message-id; bh=dnbs8MiQY9p4YqWZ5cbaKv+lRKOcVPL0FWNe0TMwC5o=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq3s4Q/TNd+lWgDL8MspWTCvRZdcoGJ8ZHKMrs0
 8RTzD3Xr4iJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCat7OEAAKCRAMdPNZecSG
 vn8XD/9Gu8KXT5NpE4TThSzqSJmeOiOMyIvBslZfD8V6j8z4vsTmwBXNBPSZqEJC0N0Lwx17rp8
 kGevMXV0Lb1UpdDzi5u49puaMFZqT7zVnr93J5/ENpZalhA5snHN5p2CHWl/59y+gzNyYWQv4lU
 AdtqZfOMcoaNxiTmghwws6/vFBI04mjNu+2e/x5YvFBabj01IzDmk/482Hiylw+J5vWw87asemX
 56HpZQMGoRkmned+u0un1g/miCqJ4WeA/IoznfDA5XjyM6jZ6NiYNCh+gP2pCfeHnp47ivBQDfR
 htJD2SPOeX8AWKzz/K3fFGBFdwXWMAqWQuTT06krbu0VHoX7EhQXc6YjJY5G/5GByFO4aUIqXPG
 i0pxAy24p6X7BLKV+Ulv25WLHSj8ncBvavoB0KLBtH6XL1lUgFvvpcb3k3vqxeccbS+UcOpX73J
 TygHuJdgmKHMqPVn/frsyn2cNpMMk2U2zmIbzCEk6IOaZa/UliTp+NTwd0lyEwedpBS/4gCsToQ
 B/IrBChJYNbNqQp3UFO3IYXoW2pLKjoPvUSrVoOGxwQ0EO+iGcbfcQPRul+JKycNl9FcYIPAwvF
 SSI6yc0a0Q6U1bR7MkkO7XYCVcrC8celjW2x49enzU45/Uxr4xoHsYpocxRgnkDgZ1okEYzlmFE
 +o3T09YDUDcMXsQ==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Not all devices have BAR1 so make it optional.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 drivers/gpu/nova-core/driver.rs      | 15 ++++++++++++---
 drivers/gpu/nova-core/gpu.rs         | 37 ++++++++++++++++++++----------------
 drivers/gpu/nova-core/mm.rs          |  2 +-
 drivers/gpu/nova-core/mm/bar_user.rs |  7 ++++++-
 4 files changed, 40 insertions(+), 21 deletions(-)

diff --git a/drivers/gpu/nova-core/driver.rs b/drivers/gpu/nova-core/driver.rs
index 560a70c4f5a7..ccf26008abe8 100644
--- a/drivers/gpu/nova-core/driver.rs
+++ b/drivers/gpu/nova-core/driver.rs
@@ -37,7 +37,7 @@ pub(crate) struct NovaCore<'bound> {
     #[pin]
     pub(crate) gpu: Gpu<'bound>,
     bar: pci::Bar<'bound, BAR0_SIZE>,
-    bar1: pci::Bar<'bound>,
+    bar1: Option<pci::Bar<'bound>>,
 }
 
 pub(crate) struct NovaCoreDriver;
@@ -112,7 +112,11 @@ fn probe<'bound>(
 
             bar1: {
                 let bar1_idx = bar1_resource_index(pdev)?;
-                pdev.iomap_region(bar1_idx, c"nova-core/bar1")?
+                if pdev.resource_len(bar1_idx)? == 0 {
+                    None
+                } else {
+                    Some(pdev.iomap_region(bar1_idx, c"nova-core/bar1")?)
+                }
             },
 
             // Run self-tests that do not depend on the `Gpu` instance.
@@ -135,7 +139,12 @@ fn probe<'bound>(
                 // SAFETY: `bar` is initialized above, pinned, and outlives `gpu`.
                 unsafe { &*core::ptr::from_ref(bar) },
                 // SAFETY: `bar1` is initialized above, pinned, and outlives `gpu`.
-                unsafe { &*core::ptr::from_ref(bar1) },
+                unsafe {
+                    match bar1 {
+                        None => None,
+                        Some(bar1) => Some(&*core::ptr::from_ref(bar1)),
+                    }
+                },
             ).pin_chain(|_gpu| {
                 #[cfg(CONFIG_NOVA_CORE_SELFTESTS)]
                 _gpu.run_selftests(pdev);
diff --git a/drivers/gpu/nova-core/gpu.rs b/drivers/gpu/nova-core/gpu.rs
index 4e59072cab50..79018aff37f3 100644
--- a/drivers/gpu/nova-core/gpu.rs
+++ b/drivers/gpu/nova-core/gpu.rs
@@ -394,9 +394,8 @@ pub(crate) struct Gpu<'gpu> {
     /// Must be kept declared *before* `gsp_resources`, so that its components are dropped while
     /// the GSP is still operational.
     mm: GpuMm<'gpu>,
-    /// BAR1 user interface for CPU access to GPU virtual memory.
-    #[pin]
-    bar_user: BarUser<'gpu>,
+    /// BAR1 user interface for CPU access to GPU virtual memory, if the device has BAR1.
+    bar_user: Option<Pin<KBox<BarUser<'gpu>>>>,
     /// GSP and its resources.
     #[pin]
     gsp_resources: GspResources<'gpu>,
@@ -448,7 +447,7 @@ impl<'gpu> Gpu<'gpu> {
     pub(crate) fn new<'a>(
         pdev: &'gpu pci::Device<device::Core<'a>>,
         bar: Bar0<'gpu>,
-        bar1: Bar1<'gpu>,
+        bar1: Option<Bar1<'gpu>>,
     ) -> impl PinInit<Self, Error> + use<'gpu, 'a> {
         let dev = pdev.as_ref();
 
@@ -580,17 +579,23 @@ pub(crate) fn new<'a>(
             },
 
             // Create BAR1 user interface for CPU access to GPU virtual memory.
-            bar_user <- {
-                let pdb_addr = VramAddress::from_raw(gsp_static_info.bar1_pde_base);
-                let bar1_idx = crate::driver::bar1_resource_index(pdev)?;
-                let bar1_size = pdev.resource_len(bar1_idx)?;
-
-                BarUser::new(
-                    pdb_addr,
-                    gsp_resources.spec.chipset,
-                    bar1_size,
-                    bar1,
-                )
+            bar_user: match bar1 {
+                None => None,
+                Some(bar1) => Some({
+                    let pdb_addr = VramAddress::from_raw(gsp_static_info.bar1_pde_base);
+                    let bar1_idx = crate::driver::bar1_resource_index(pdev)?;
+                    let bar1_size = pdev.resource_len(bar1_idx)?;
+
+                    KBox::pin_init(
+                        BarUser::new(
+                            pdb_addr,
+                            gsp_resources.spec.chipset,
+                            bar1_size,
+                            bar1,
+                        ),
+                        GFP_KERNEL,
+                    )?
+                }),
             },
         })
     }
@@ -623,7 +628,7 @@ pub(crate) fn run_selftests(self: Pin<&mut Self>, pdev: &pci::Device<device::Bou
             dev,
             this.mm,
             regions,
-            &this.bar_user,
+            this.bar_user.as_deref(),
             this.gsp_static_info.bar1_pde_base,
             this.spec.chipset,
         ) {
diff --git a/drivers/gpu/nova-core/mm.rs b/drivers/gpu/nova-core/mm.rs
index 8a934c55169f..557bf76c2f5b 100644
--- a/drivers/gpu/nova-core/mm.rs
+++ b/drivers/gpu/nova-core/mm.rs
@@ -308,7 +308,7 @@ pub(crate) fn run(
         dev: &device::Device<device::Bound>,
         mm: &mut GpuMm<'_>,
         usable_fb_regions: &[Range<u64>],
-        bar_user: &bar_user::BarUser<'_>,
+        bar_user: Option<&bar_user::BarUser<'_>>,
         bar1_pdb: u64,
         chipset: Chipset,
     ) -> Result {
diff --git a/drivers/gpu/nova-core/mm/bar_user.rs b/drivers/gpu/nova-core/mm/bar_user.rs
index 6e9384f06f43..205082df27bc 100644
--- a/drivers/gpu/nova-core/mm/bar_user.rs
+++ b/drivers/gpu/nova-core/mm/bar_user.rs
@@ -184,7 +184,7 @@ fn drop(&mut self) {
 pub(crate) fn run_self_test(
     dev: &device::Device<device::Bound>,
     mm: &mut GpuMm<'_>,
-    bar_user: &BarUser<'_>,
+    bar_user: Option<&BarUser<'_>>,
     bar1_pdb: u64,
     chipset: Chipset,
 ) -> Result {
@@ -202,6 +202,11 @@ pub(crate) fn run_self_test(
         },
     };
 
+    let Some(bar_user) = bar_user else {
+        dev_info!(dev, "MM: Self-test SKIPPED - no BAR1\n");
+        return Ok(());
+    };
+
     // Test patterns.
     const PATTERN_PRAMIN: u32 = 0xDEAD_BEEF;
     const PATTERN_BAR1: u32 = 0xCAFE_BABE;

---
base-commit: 3497a403264b094ebd61b8b755165d56e7d9dc37
change-id: 20261026-nova-bar1-option-407f1f49fd1c

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

