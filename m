From: Dave Airlie <airlied@redhat.com>
Date: Mon, 23 Nov 2026 12:50:29 +1000
Subject: [PATCH v2 3/3] nova-core: only bind to GPUs when explicitly
 requested
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-nova-nouveau-gsp-v2-3-5e8c27aa8555@redhat.com>
References: <20261123-nova-nouveau-gsp-v2-0-5e8c27aa8555@redhat.com>
In-Reply-To: <20261123-nova-nouveau-gsp-v2-0-5e8c27aa8555@redhat.com>
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 nova-gpu@lists.linux.dev, Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3934; i=airlied@redhat.com;
 h=from:subject:message-id; bh=ktgnVzJ6BELx72lt+TM44DFV7qUNrRVPclg3oukRFbc=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBrA6n6T/ovkwnCH7dJPiz7GYYvvFweCZ0MC47WW
 gXl8tEd3hqJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCawOp+gAKCRAMdPNZecSG
 viicD/9oIepXbyTGfnO64WYJMrkhIvxypKd3ss2vP3ZyOTcc6TVAR8EgjRKKlgZExLay4dG+f5E
 473ODtE3kH+zyhG9/5hoW7PQPNLq5T2e4ZnHLv1szp8iukd+wpu4ep+v6PjRBMdP+HnsCSAhtJV
 /Q1PJPXnYXK1ryNmcHYq55RFjwYZuz29C+PFLs2iG5qTbfgXxy5qOziS0FHQ+hZatH4SwjmFzMn
 pbMAdOjNsOpJKfZfJGej4PULmBx1twfKySk+DlL2D8olFWSMFuGUbKYNGcelLjBsKvlvbOOujkN
 0niPvgE+r13XNUUMOfmp5TixoAFkjm/PED/dCmo8F1r9kOUK4K0/7d7gx65HhKu40IYQ/A++2t3
 ARfvvcg1MHLfy9fSfl86e9N/l3uc7vKZcViBkB+6w3GEmDyWNfxDoeJjJMFQrSFRRBJPOn+j0UX
 nqBgkFXARdtGoDEW7+VwlhQvtaIbGVg1ahO8s6QxvelqEH6cP62TkwnsXy0KGOUan5bgSb5i20p
 eUYetUIgEzTdEX6CiZXc0p6zjUOWc9X0nwe2sG9LlHowv++vBDekwL5FKaZkKidOG4DScWiG7bc
 Ij5xbO059NkMMUqgk288ghtdhoQMxKRDlz1cn5eq917NCcMKKp8a5zEzvEgtQ/HOt0GwEmHYetR
 ARW0vuyD6Ae7ktQ==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nova-core currently binds to every NVIDIA GPU it supports
(GSP-capable, Turing and later GPUs), competing with nouveau for the
same devices.

Add the NOVA_CORE_BIND_GSP Kconfig option (default n) and a bind_gsp
module parameter, defaulting to the Kconfig value and able to override
it in both directions. Unless one of them requests binding, probe()
rejects the GPU with -ENODEV and leaves the device to other drivers,
such as nouveau. The PCI driver still registers, so module autoloading
via modalias keeps working when binding is disabled.

As nova-core is work in progress, the default is to not bind at all.
Developers can enable binding with CONFIG_NOVA_CORE_BIND_GSP=y, or
nova-core.bind_gsp=1 on the kernel command line, combined with
nouveau.bind_gsp=0 (or CONFIG_DRM_NOUVEAU_BIND_GSP=n) so that nouveau
yields the GSP-capable GPUs.
---
 drivers/gpu/nova-core/Kconfig      | 21 +++++++++++++++++++++
 drivers/gpu/nova-core/driver.rs    | 13 +++++++++++++
 drivers/gpu/nova-core/nova_core.rs |  4 ++++
 3 files changed, 38 insertions(+)

diff --git a/drivers/gpu/nova-core/Kconfig b/drivers/gpu/nova-core/Kconfig
index 2e11e46c99c7..058742d50692 100644
--- a/drivers/gpu/nova-core/Kconfig
+++ b/drivers/gpu/nova-core/Kconfig
@@ -30,3 +30,24 @@ config NOVA_CORE_SELFTESTS
 	  logs its failure and lets the probe continue.
 
 	  If unsure, say N.
+
+config NOVA_CORE_BIND_GSP
+	bool "Make nova-core the default driver for GSP-capable GPUs"
+	depends on NOVA_CORE
+	default n
+	help
+	  Make nova-core bind to all NVIDIA GPUs it supports by default.
+
+	  By default nova-core does not bind to any GPU and leaves NVIDIA
+	  GPUs to other drivers, such as nouveau. Say Y here, or boot with
+	  nova-core.bind_gsp=1, to make nova-core claim NVIDIA GPUs
+	  instead.
+
+	  nova-core is work in progress and may not be functional, so this
+	  is intended for nova developers and testers only. When enabled,
+	  nouveau must not bind to the same (GSP-capable) GPUs, i.e.
+	  CONFIG_DRM_NOUVEAU_BIND_GSP=N or nouveau.bind_gsp=0 is required.
+	  Otherwise both drivers compete for the same devices and
+	  whichever is loaded first wins.
+
+	  If unsure, say N.
diff --git a/drivers/gpu/nova-core/driver.rs b/drivers/gpu/nova-core/driver.rs
index d6bc972d47c7..66208a244cab 100644
--- a/drivers/gpu/nova-core/driver.rs
+++ b/drivers/gpu/nova-core/driver.rs
@@ -105,6 +105,19 @@ fn probe<'bound>(
         dev_dbg!(pdev, "Probe Nova Core GPU driver.\n");
 
         try_pin_init!(NovaCore {
+            // Only bind when explicitly requested through the corresponding
+            // Kconfig option or module parameter. By default, leave NVIDIA
+            // GPUs to other drivers, such as nouveau.
+            _: {
+                if !crate::module_parameters::bind_gsp.value() {
+                    dev_info!(
+                        pdev,
+                        "Not binding to GPU; make nova-core the default NVIDIA driver with CONFIG_NOVA_CORE_BIND_GSP=y or nova-core.bind_gsp=1\n"
+                    );
+                    Err(ENODEV)?;
+                }
+            },
+
             _: {
                 pdev.enable_device_mem()?;
                 pdev.set_master();
diff --git a/drivers/gpu/nova-core/nova_core.rs b/drivers/gpu/nova-core/nova_core.rs
index 84f777844592..d18dacad98b6 100644
--- a/drivers/gpu/nova-core/nova_core.rs
+++ b/drivers/gpu/nova-core/nova_core.rs
@@ -97,6 +97,10 @@ fn init(module: &'static kernel::ThisModule) -> impl PinInit<Self, Error> {
             default: false,
             description: "Keep the GSP-RM log buffers in debugfs after their GPU is unbound",
         },
+        bind_gsp: bool {
+            default: cfg!(CONFIG_NOVA_CORE_BIND_GSP),
+            description: "Bind to GSP-capable GPUs, making nova-core the default NVIDIA driver",
+        },
     },
 }
 

-- 
2.56.1

