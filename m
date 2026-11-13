From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 13 Nov 2026 08:59:22 -0800
Subject: [PATCH net-next v11 03/14] net: ethernet: oa_tc6: Move oa_tc6.c to
 its own directory
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-s2500-mac-phy-support-v11-3-7a186141952c@onsemi.com>
References: <20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com>
In-Reply-To: <20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com>
To: Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: Selva Rajagopal <Selvamani.Rajagopal@onsemi.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794589162; l=5322;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=Pd0dXYiMZlEIzgfNTnIo8RTA035x6ymrrjs+dN6mS2Q=;
 b=JRFSyQGbCZ8jGyDjr4z8DPDUdVEu+D5gxL0JIoVbBg//vc00+drFos1SnCzqp/Cg5MsW10X1e
 4yQbYRjTsvVC9DpaiuIDEy6g0Q+Jk3gHno/MyXtokt5eUQwZlmC6g9X
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move oa_tc6.c to its own directory, drivers/net/ethernet/oa_tc6.
File oa_tc6.c is renamed to oa_tc6_main.c to maintain the kernel
module's name as oa_tc6. This will facilitate adding more files
to support other features defined by OPEN Alliance 10BASE-T1x
Serial Interface specification.

This patch series adds two files, one for hardware
timestamp related functions and one for PTP related APIs.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v11
  - Mentioned the renaming of oa_tc6.c in the commit message
changes in v10
  - Kernel module restored to oa_tc6.ko from oa_tc6_mod.ko
changes in v9
  - Changed MAINTAINERS to add "all files" under oa_tc6
  - Added the missing "if COMPILE_TEST"
  - Added Reviewed by tag
changes in v8
  - No change
changes in v7
  - No change
changes in v6
  - No change
changes in v5
  - No change
changes in v4
  - Removed reference to onsemi in Kconfig files
changes in v3
  - Moved oa_tc6.c to its own, oa_tc6 directory under ethernet.
  - First patch
---
 MAINTAINERS                                             |  2 +-
 drivers/net/ethernet/Kconfig                            | 12 +-----------
 drivers/net/ethernet/Makefile                           |  2 +-
 drivers/net/ethernet/oa_tc6/Kconfig                     | 15 +++++++++++++++
 drivers/net/ethernet/oa_tc6/Makefile                    |  7 +++++++
 drivers/net/ethernet/{oa_tc6.c => oa_tc6/oa_tc6_main.c} |  0
 6 files changed, 25 insertions(+), 13 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 4a4c26694ba7..028fa967674e 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -21043,7 +21043,7 @@ M:	Parthiban Veerasooran <parthiban.veerasooran@microchip.com>
 L:	netdev@vger.kernel.org
 S:	Maintained
 F:	Documentation/networking/oa-tc6-framework.rst
-F:	drivers/net/ethernet/oa_tc6.c
+F:	drivers/net/ethernet/oa_tc6/*
 F:	include/linux/oa_tc6.h
 
 OPEN FIRMWARE AND FLATTENED DEVICE TREE
diff --git a/drivers/net/ethernet/Kconfig b/drivers/net/ethernet/Kconfig
index c2b0161d0bec..5758e0fbbca5 100644
--- a/drivers/net/ethernet/Kconfig
+++ b/drivers/net/ethernet/Kconfig
@@ -135,6 +135,7 @@ source "drivers/net/ethernet/netronome/Kconfig"
 source "drivers/net/ethernet/8390/Kconfig"
 source "drivers/net/ethernet/nvidia/Kconfig"
 source "drivers/net/ethernet/nxp/Kconfig"
+source "drivers/net/ethernet/oa_tc6/Kconfig"
 source "drivers/net/ethernet/oki-semi/Kconfig"
 
 config ETHOC
@@ -147,17 +148,6 @@ config ETHOC
 	help
 	  Say Y here if you want to use the OpenCores 10/100 Mbps Ethernet MAC.
 
-config OA_TC6
-	tristate "OPEN Alliance TC6 10BASE-T1x MAC-PHY support" if COMPILE_TEST
-	depends on SPI
-	select PHYLIB
-	help
-	  This library implements OPEN Alliance TC6 10BASE-T1x MAC-PHY
-	  Serial Interface protocol for supporting 10BASE-T1x MAC-PHYs.
-
-	  To know the implementation details, refer documentation in
-	  <file:Documentation/networking/oa-tc6-framework.rst>.
-
 source "drivers/net/ethernet/pasemi/Kconfig"
 source "drivers/net/ethernet/pensando/Kconfig"
 source "drivers/net/ethernet/qlogic/Kconfig"
diff --git a/drivers/net/ethernet/Makefile b/drivers/net/ethernet/Makefile
index a306dae23bcb..e0e86c249e42 100644
--- a/drivers/net/ethernet/Makefile
+++ b/drivers/net/ethernet/Makefile
@@ -72,6 +72,7 @@ obj-$(CONFIG_NET_VENDOR_NETRONOME) += netronome/
 obj-$(CONFIG_NET_VENDOR_NI) += ni/
 obj-$(CONFIG_NET_VENDOR_NVIDIA) += nvidia/
 obj-$(CONFIG_LPC_ENET) += nxp/
+obj-$(CONFIG_OA_TC6) += oa_tc6/
 obj-$(CONFIG_NET_VENDOR_OKI) += oki-semi/
 obj-$(CONFIG_ETHOC) += ethoc.o
 obj-$(CONFIG_NET_VENDOR_PASEMI) += pasemi/
@@ -105,5 +106,4 @@ obj-$(CONFIG_NET_VENDOR_XILINX) += xilinx/
 obj-$(CONFIG_NET_VENDOR_XIRCOM) += xircom/
 obj-$(CONFIG_NET_VENDOR_SYNOPSYS) += synopsys/
 obj-$(CONFIG_NET_VENDOR_PENSANDO) += pensando/
-obj-$(CONFIG_OA_TC6) += oa_tc6.o
 obj-$(CONFIG_NET_VENDOR_ZTE) += zte/
diff --git a/drivers/net/ethernet/oa_tc6/Kconfig b/drivers/net/ethernet/oa_tc6/Kconfig
new file mode 100644
index 000000000000..ec2787eae4b1
--- /dev/null
+++ b/drivers/net/ethernet/oa_tc6/Kconfig
@@ -0,0 +1,15 @@
+# SPDX-License-Identifier: GPL-2.0-only
+#
+# OA TC6 10BASE-T1x MAC-PHY configuration
+#
+
+config OA_TC6
+	tristate "OPEN Alliance TC6 10BASE-T1x MAC-PHY support" if COMPILE_TEST
+	depends on SPI
+	select PHYLIB
+	help
+	  This library implements OPEN Alliance TC6 10BASE-T1x MAC-PHY
+	  Serial Interface protocol for supporting 10BASE-T1x MAC-PHYs.
+
+	  To know the implementation details, refer documentation in
+	  <file:Documentation/networking/oa-tc6-framework.rst>.
diff --git a/drivers/net/ethernet/oa_tc6/Makefile b/drivers/net/ethernet/oa_tc6/Makefile
new file mode 100644
index 000000000000..c51621fae8be
--- /dev/null
+++ b/drivers/net/ethernet/oa_tc6/Makefile
@@ -0,0 +1,7 @@
+# SPDX-License-Identifier: GPL-2.0-only
+#
+# Makefile for OA TC6 10BASE-T1x MAC-PHY
+#
+
+obj-$(CONFIG_OA_TC6) += oa_tc6.o
+oa_tc6-objs := oa_tc6_main.o
diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6/oa_tc6_main.c
similarity index 100%
rename from drivers/net/ethernet/oa_tc6.c
rename to drivers/net/ethernet/oa_tc6/oa_tc6_main.c

-- 
2.43.0

