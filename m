From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:21:53 -0800
Subject: [PATCH 03/36] xen: introduce resource.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-3-87b9a8375b7a@ford.com>
References: <20241126-vuart-ns8250-v1-v1-0-87b9a8375b7a@ford.com>
In-Reply-To: <20241126-vuart-ns8250-v1-v1-0-87b9a8375b7a@ford.com>
To: Jan Beulich <jbeulich@suse.com>, 
 Andrew Cooper <andrew.cooper3@citrix.com>, 
 =?utf-8?q?Roger_Pau_Monn=C3=A9?= <roger.pau@citrix.com>, 
 "Daniel P. Smith" <dpsmith@apertussolutions.com>, 
 Stefano Stabellini <sstabellini@kernel.org>, Julien Grall <julien@xen.org>, 
 Bertrand Marquis <bertrand.marquis@arm.com>, 
 Michal Orzel <michal.orzel@amd.com>, Rahul Singh <rahul.singh@arm.com>, 
 Volodymyr Babchuk <Volodymyr_Babchuk@epam.com>, 
 Alistair Francis <alistair.francis@wdc.com>, 
 Bob Eshleman <bobbyeshleman@gmail.com>, 
 Connor Davis <connojdavis@gmail.com>, 
 Oleksii Kurochko <oleksii.kurochko@gmail.com>, 
 Shawn Anastasio <sanastasio@raptorengineering.com>, 
 Anthony PERARD <anthony.perard@vates.tech>, Juergen Gross <jgross@suse.com>, 
 Christian Lindig <christian.lindig@citrix.com>, 
 David Scott <dave@recoil.org>, 
 =?utf-8?q?Marek_Marczykowski-G=C3=B3recki?= <marmarek@invisiblethingslab.com>
Cc: xen-devel@lists.xenproject.org, Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=4665;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=Q8GpN19knhkzccfTAV4prViqD1gvBrGqV7AxMvPxGlg=;
 b=R204wyNJVDFwtxunVQ6uTri4iQAm0/nHG/UG64/jv9N7oGTk83gB3DKrDKESdQQu1IVN9xlm7
 3k8U0eTtjb9DPHLtDbGKT5MQ/HAPZ4KbuEtGVkcnzKJn04P8qSywJYz
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move resource definitions to a new architecture-agnostic shared header file.

It will be used in follow on NS8250 emulator code to describe legacy
PC COM resources.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/common/device-tree/device-tree.c | 21 +------------------
 xen/drivers/passthrough/arm/smmu.c   | 15 +-------------
 xen/include/xen/resource.h           | 40 ++++++++++++++++++++++++++++++++++++
 3 files changed, 42 insertions(+), 34 deletions(-)

diff --git a/xen/common/device-tree/device-tree.c b/xen/common/device-tree/device-tree.c
index d0528c5825651f7cc9ebca0c949229c9083063c6..e8f810b2fe10890c033ed3a9d4ca627010ad019b 100644
--- a/xen/common/device-tree/device-tree.c
+++ b/xen/common/device-tree/device-tree.c
@@ -24,6 +24,7 @@
 #include <xen/ctype.h>
 #include <asm/setup.h>
 #include <xen/err.h>
+#include <xen/resource.h>
 
 const void *device_tree_flattened;
 dt_irq_xlate_func dt_irq_xlate;
@@ -535,26 +536,6 @@ int dt_child_n_size_cells(const struct dt_device_node *parent)
     return __dt_n_size_cells(parent, true);
 }
 
-/*
- * These are defined in Linux where much of this code comes from, but
- * are currently unused outside this file in the context of Xen.
- */
-#define IORESOURCE_BITS         0x000000ff      /* Bus-specific bits */
-
-#define IORESOURCE_TYPE_BITS    0x00001f00      /* Resource type */
-#define IORESOURCE_IO           0x00000100      /* PCI/ISA I/O ports */
-#define IORESOURCE_MEM          0x00000200
-#define IORESOURCE_REG          0x00000300      /* Register offsets */
-#define IORESOURCE_IRQ          0x00000400
-#define IORESOURCE_DMA          0x00000800
-#define IORESOURCE_BUS          0x00001000
-
-#define IORESOURCE_PREFETCH     0x00002000      /* No side effects */
-#define IORESOURCE_READONLY     0x00004000
-#define IORESOURCE_CACHEABLE    0x00008000
-#define IORESOURCE_RANGELENGTH  0x00010000
-#define IORESOURCE_SHADOWABLE   0x00020000
-
 /*
  * Default translator (generic bus)
  */
diff --git a/xen/drivers/passthrough/arm/smmu.c b/xen/drivers/passthrough/arm/smmu.c
index 03d22bce1e497e41834c273f9048b98dcbd48a54..aa6a968b574dce7cc753e8070fad3a6e585cd9e7 100644
--- a/xen/drivers/passthrough/arm/smmu.c
+++ b/xen/drivers/passthrough/arm/smmu.c
@@ -50,6 +50,7 @@
 #include <xen/rbtree.h>
 #include <xen/sched.h>
 #include <xen/sizes.h>
+#include <xen/resource.h>
 #include <asm/atomic.h>
 #include <asm/device.h>
 #include <asm/io.h>
@@ -70,22 +71,8 @@
 #define of_property_read_u32(np, pname, out) (!dt_property_read_u32(np, pname, out))
 #define of_property_read_bool dt_property_read_bool
 #define of_parse_phandle_with_args dt_parse_phandle_with_args
-
-/* Xen: Helpers to get device MMIO and IRQs */
-struct resource
-{
-	paddr_t addr;
-	paddr_t size;
-	unsigned int type;
-};
-
-#define resource_size(res) (res)->size;
-
 #define platform_device dt_device_node
 
-#define IORESOURCE_MEM 0
-#define IORESOURCE_IRQ 1
-
 static struct resource *platform_get_resource(struct platform_device *pdev,
 					      unsigned int type,
 					      unsigned int num)
diff --git a/xen/include/xen/resource.h b/xen/include/xen/resource.h
new file mode 100644
index 0000000000000000000000000000000000000000..4962e17da8387b7f324317482b19cc9fe71433fc
--- /dev/null
+++ b/xen/include/xen/resource.h
@@ -0,0 +1,40 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * System resource description.
+ *
+ * Reference:
+ *   include/linux/ioport.h
+ */
+#if !defined(XEN__RESOURCE_H)
+#define XEN__RESOURCE_H
+
+#define IORESOURCE_BITS         0x000000FFU      /* Bus-specific bits */
+
+#define IORESOURCE_TYPE_BITS    0x00001F00U      /* Resource type */
+#define IORESOURCE_IO           0x00000100U      /* PCI/ISA I/O ports */
+#define IORESOURCE_MEM          0x00000200U
+#define IORESOURCE_REG          0x00000300U      /* Register offsets */
+#define IORESOURCE_IRQ          0x00000400U
+#define IORESOURCE_DMA          0x00000800U
+#define IORESOURCE_BUS          0x00001000U
+
+#define IORESOURCE_PREFETCH     0x00002000U      /* No side effects */
+#define IORESOURCE_READONLY     0x00004000U
+#define IORESOURCE_CACHEABLE    0x00008000U
+#define IORESOURCE_RANGELENGTH  0x00010000U
+#define IORESOURCE_SHADOWABLE   0x00020000U
+
+#define IORESOURCE_UNKNOWN      (~0U)
+
+struct resource {
+    paddr_t addr;
+    paddr_t size;
+    unsigned int type;
+};
+
+#define resource_size(res) (res)->size;
+
+#define foreach_resource(res) \
+    for (; res && res->type != IORESOURCE_UNKNOWN; res++)
+
+#endif /* #if !defined(XEN__RESOURCE_H) */

-- 
2.34.1

