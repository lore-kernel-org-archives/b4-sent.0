From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 05 Sep 2025 13:48:35 -0500
Subject: [PATCH RFC 12/13] dmaengine: sdxi: Add Kconfig and Makefile
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250905-sdxi-base-v1-12-d0341a1292ba@amd.com>
References: <20250905-sdxi-base-v1-0-d0341a1292ba@amd.com>
In-Reply-To: <20250905-sdxi-base-v1-0-d0341a1292ba@amd.com>
To: Vinod Koul <vkoul@kernel.org>
Cc: Wei Huang <wei.huang2@amd.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, linux-pci@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dmaengine@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757098129; l=3113;
 i=nathan.lynch@amd.com; s=20241010; h=from:subject:message-id;
 bh=ouNlAF3ey9kkPHIHkTAL8nkSqeI8aY290db9HnPAHSw=;
 b=9QEgbeZtoY02av3vXIAReneK8LIym6iDIavrtDdkJoaGAe+hK8loAznGg4DdNdfkul4tka+N0
 gEXJrStJhE2APqhhM6Crk3tgkYiLF4lmaIzYy1L6gpxa4Mx6/56hMGo
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=ZR637UTGg5YLDj56cxFeHdYoUjPMMFbcijfOkAmAnbc=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20241010 with auth_id=241
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SDXI Kconfig that includes debug and unit test options in addition
to the usual tristate. SDXI_DEBUG seems necessary because
DMADEVICES_DEBUG makes dmatest too verbose.

One goal is to keep the bus-agnostic portions of the driver buildable
without PCI(_MSI), in case non-PCI SDXI implementations come along
later.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/Kconfig       |  2 ++
 drivers/dma/Makefile      |  1 +
 drivers/dma/sdxi/Kconfig  | 23 +++++++++++++++++++++++
 drivers/dma/sdxi/Makefile | 17 +++++++++++++++++
 4 files changed, 43 insertions(+)

diff --git a/drivers/dma/Kconfig b/drivers/dma/Kconfig
index 05c7c7d9e5a4e52a8ad7ada8c8b9b1a6f9d875f6..cccf00b73e025944681b03cffe441c372526d3f3 100644
--- a/drivers/dma/Kconfig
+++ b/drivers/dma/Kconfig
@@ -774,6 +774,8 @@ source "drivers/dma/fsl-dpaa2-qdma/Kconfig"
 
 source "drivers/dma/lgm/Kconfig"
 
+source "drivers/dma/sdxi/Kconfig"
+
 source "drivers/dma/stm32/Kconfig"
 
 # clients
diff --git a/drivers/dma/Makefile b/drivers/dma/Makefile
index a54d7688392b1a0e956fa5d23633507f52f017d9..ae4154595e1a6250b441a90078e9df3607d3d1dd 100644
--- a/drivers/dma/Makefile
+++ b/drivers/dma/Makefile
@@ -85,6 +85,7 @@ obj-$(CONFIG_XGENE_DMA) += xgene-dma.o
 obj-$(CONFIG_ST_FDMA) += st_fdma.o
 obj-$(CONFIG_FSL_DPAA2_QDMA) += fsl-dpaa2-qdma/
 obj-$(CONFIG_INTEL_LDMA) += lgm/
+obj-$(CONFIG_SDXI) += sdxi/
 
 obj-y += amd/
 obj-y += mediatek/
diff --git a/drivers/dma/sdxi/Kconfig b/drivers/dma/sdxi/Kconfig
new file mode 100644
index 0000000000000000000000000000000000000000..c9757cffb5f64fbc175ded8d0c9d751f0a22b6df
--- /dev/null
+++ b/drivers/dma/sdxi/Kconfig
@@ -0,0 +1,23 @@
+config SDXI
+	tristate "SDXI support"
+	select DMA_ENGINE
+	select DMA_VIRTUAL_CHANNELS
+	select PACKING
+	help
+	  Enable support for Smart Data Accelerator Interface (SDXI)
+	  Platform Data Mover devices. SDXI is a vendor-neutral
+	  standard for a memory-to-memory data mover and acceleration
+	  interface.
+
+config SDXI_DEBUG
+	bool "SDXI driver debug"
+	default DMADEVICES_DEBUG
+	depends on SDXI != n
+	help
+	  Enable debug output from the SDXI driver. This is an option
+	  for use by developers and most users should say N here.
+
+config SDXI_KUNIT_TEST
+       tristate "SDXI unit tests" if !KUNIT_ALL_TESTS
+       depends on SDXI && KUNIT
+       default KUNIT_ALL_TESTS
diff --git a/drivers/dma/sdxi/Makefile b/drivers/dma/sdxi/Makefile
new file mode 100644
index 0000000000000000000000000000000000000000..c67e475689b45d6260fe970fb4afcc25f8f9ebc1
--- /dev/null
+++ b/drivers/dma/sdxi/Makefile
@@ -0,0 +1,17 @@
+# SPDX-License-Identifier: GPL-2.0
+
+ccflags-$(CONFIG_SDXI_DEBUG) += -DDEBUG
+
+obj-$(CONFIG_SDXI) += sdxi.o
+
+sdxi-objs += \
+	context.o     \
+	descriptor.o  \
+	device.o      \
+	dma.o         \
+	enqueue.o     \
+	error.o
+
+sdxi-$(CONFIG_PCI_MSI) += pci.o
+
+obj-$(CONFIG_SDXI_KUNIT_TEST) += descriptor_kunit.o

-- 
2.39.5

