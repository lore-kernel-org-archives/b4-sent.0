From: Junhui Liu <liujh2818@outlook.com>
Date: Mon, 30 Dec 2024 11:30:17 +0800
Subject: [PATCH v2 2/8] usb: dwc2: Fix incorrect ULPI_UTMI_SEL bit setting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241230-dwc2-dev-v2-2-12cd9b8a2358@outlook.com>
References: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
In-Reply-To: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
To: Tom Rini <trini@konsulko.com>, Marek Vasut <marex@denx.de>, 
 Lukasz Majewski <lukma@denx.de>, 
 Mattijs Korpershoek <mkorpershoek@baylibre.com>
Cc: u-boot@lists.denx.de, Kongyang Liu <seashell11234455@gmail.com>, 
 Junhui Liu <liujh2818@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735529447; l=2089;
 i=liujh2818@outlook.com; s=20241030; h=from:subject:message-id;
 bh=pqswinryaJy2ie7uN2T0/IbhADb0q8MTVMTB7VwmJqc=;
 b=F23W/kJR3CtCW1wzTFnnZmX8y5CS5SK5SIFr77ZgYBvNj7PI7eTH6shCpJVOUl36DGBhGkAdN
 dMmvkT4gfkPD83NB+qfu8iEDCKeem1nIn2uLJ8Bf2tUY68wTZBYmKG8
X-Developer-Key: i=liujh2818@outlook.com; a=ed25519;
 pk=ApYwI6KD3EjynMw61RqGa6c5BGbStQnKSrbNN+aQqT4=
X-Endpoint-Received: by B4 Relay for liujh2818@outlook.com/20241030 with auth_id=259
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Junhui Liu <liujh2818@outlook.com>

The ULPI_UTMI_SEL bit in the DWC2 driver was set incorrectly. According
to the datasheet [1], this bit should be set to 0 for UTMI interface and 1
for ULPI interface. The existing code had this logic reversed,
causing the interface selection to be incorrect.

This commit corrects the ULPI_UTMI_SEL bit setting to match the
datasheet's description. Referencing the kernel's code [2] also confirms
this fix.

[1] https://rockchip.fr/RK312X%20TRM/chapter-26-usb-otg-2-0.pdf#page=30
[2] https://github.com/torvalds/linux/blob/v6.13-rc3/drivers/usb/dwc2/core.c#L1106

Signed-off-by: Junhui Liu <liujh2818@outlook.com>
---
 drivers/usb/host/dwc2.c | 24 +++++++++++++-----------
 1 file changed, 13 insertions(+), 11 deletions(-)

diff --git a/drivers/usb/host/dwc2.c b/drivers/usb/host/dwc2.c
index b6c8b3d5a6bdf375f1adeb106d4832d92307f0db..609de18faa3abc5f4ecb0c23cf3590966bad7992 100644
--- a/drivers/usb/host/dwc2.c
+++ b/drivers/usb/host/dwc2.c
@@ -402,20 +402,22 @@ static void dwc_otg_core_init(struct udevice *dev)
 	 * soft reset so only program the first time. Do a soft reset
 	 * immediately after setting phyif.
 	 */
-	usbcfg &= ~(DWC2_GUSBCFG_ULPI_UTMI_SEL | DWC2_GUSBCFG_PHYIF);
-	usbcfg |= DWC2_PHY_TYPE << DWC2_GUSBCFG_ULPI_UTMI_SEL_OFFSET;
-
-	if (usbcfg & DWC2_GUSBCFG_ULPI_UTMI_SEL) {	/* ULPI interface */
+#if (DWC2_PHY_TYPE == DWC2_PHY_TYPE_ULPI)
+	usbcfg |= DWC2_GUSBCFG_ULPI_UTMI_SEL;
+	usbcfg &= ~DWC2_GUSBCFG_PHYIF;
 #ifdef DWC2_PHY_ULPI_DDR
-		usbcfg |= DWC2_GUSBCFG_DDRSEL;
+	usbcfg |= DWC2_GUSBCFG_DDRSEL;
 #else
-		usbcfg &= ~DWC2_GUSBCFG_DDRSEL;
-#endif
-	} else {	/* UTMI+ interface */
+	usbcfg &= ~DWC2_GUSBCFG_DDRSEL;
+#endif /* DWC2_PHY_ULPI_DDR */
+#elif (DWC2_PHY_TYPE == DWC2_PHY_TYPE_UTMI)
+	usbcfg &= ~DWC2_GUSBCFG_ULPI_UTMI_SEL;
 #if (DWC2_UTMI_WIDTH == 16)
-		usbcfg |= DWC2_GUSBCFG_PHYIF;
-#endif
-	}
+	usbcfg |= DWC2_GUSBCFG_PHYIF;
+#else
+	usbcfg &= ~DWC2_GUSBCFG_PHYIF;
+#endif /* DWC2_UTMI_WIDTH */
+#endif /* DWC2_PHY_TYPE */
 
 	writel(usbcfg, &regs->global_regs.gusbcfg);
 

-- 
2.39.2

