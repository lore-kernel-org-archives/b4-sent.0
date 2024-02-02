From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 03 Feb 2024 07:01:55 +0800
Subject: [PATCH 2/3] usb: dwc3: replace argument mode with child ofnode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240203-hisi-dwc3-v1-2-448050c7b690@outlook.com>
References: <20240203-hisi-dwc3-v1-0-448050c7b690@outlook.com>
In-Reply-To: <20240203-hisi-dwc3-v1-0-448050c7b690@outlook.com>
To: Marek Vasut <marex@denx.de>, Tom Rini <trini@konsulko.com>, 
 Sean Anderson <sean.anderson@seco.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706914914; l=2458;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=fQ5QzLzIEP736TZtMfCMIaL07xA0BFdi1MT0kuti3Io=;
 b=srurWlm0t/x9iDhboAy+9ZAk7JMDkr6dHaCL93HafrQ3rCjJzO+zoRTK9GNSa0llUqiJnDFVT
 3bFIdzp5XmNBPSQbW+o0MI6iqhhwJp4TXlw3NcbTOSHeGVvNNJ+0Cot
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

child ofnode is more useful and can be used to query a lot of other
props of child device. dr_mode can be also queried from it.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/usb/dwc3/dwc3-generic.c | 12 ++++--------
 drivers/usb/dwc3/dwc3-generic.h |  3 +--
 2 files changed, 5 insertions(+), 10 deletions(-)

diff --git a/drivers/usb/dwc3/dwc3-generic.c b/drivers/usb/dwc3/dwc3-generic.c
index 6fb2de8a5a..d892042b91 100644
--- a/drivers/usb/dwc3/dwc3-generic.c
+++ b/drivers/usb/dwc3/dwc3-generic.c
@@ -272,8 +272,7 @@ U_BOOT_DRIVER(dwc3_generic_host) = {
 };
 #endif
 
-void dwc3_imx8mp_glue_configure(struct udevice *dev, int index,
-				enum usb_dr_mode mode)
+void dwc3_imx8mp_glue_configure(struct udevice *dev, ofnode child, int index)
 {
 /* USB glue registers */
 #define USB_CTRL0		0x00
@@ -323,8 +322,7 @@ struct dwc3_glue_ops imx8mp_ops = {
 	.glue_configure = dwc3_imx8mp_glue_configure,
 };
 
-void dwc3_ti_glue_configure(struct udevice *dev, int index,
-			    enum usb_dr_mode mode)
+void dwc3_ti_glue_configure(struct udevice *dev, ofnode child, int index)
 {
 #define USBOTGSS_UTMI_OTG_STATUS		0x0084
 #define USBOTGSS_UTMI_OTG_OFFSET		0x0480
@@ -348,6 +346,7 @@ enum dwc3_omap_utmi_mode {
 	u32 reg;
 	u32 utmi_mode;
 	u32 utmi_status_offset = USBOTGSS_UTMI_OTG_STATUS;
+	enum usb_dr_mode mode = usb_get_dr_mode(child);
 
 	struct dwc3_glue_data *glue = dev_get_plat(dev);
 	void *base = map_physmem(glue->regs, 0x10000, MAP_NOCACHE);
@@ -577,12 +576,9 @@ int dwc3_glue_probe(struct udevice *dev)
 	}
 
 	while (child) {
-		enum usb_dr_mode dr_mode;
-
-		dr_mode = usb_get_dr_mode(dev_ofnode(child));
 		device_find_next_child(&child);
 		if (ops && ops->glue_configure)
-			ops->glue_configure(dev, index, dr_mode);
+			ops->glue_configure(dev, dev_ofnode(child), index);
 		index++;
 	}
 
diff --git a/drivers/usb/dwc3/dwc3-generic.h b/drivers/usb/dwc3/dwc3-generic.h
index 40902c8923..46c14a338b 100644
--- a/drivers/usb/dwc3/dwc3-generic.h
+++ b/drivers/usb/dwc3/dwc3-generic.h
@@ -22,8 +22,7 @@ struct dwc3_glue_data {
 
 struct dwc3_glue_ops {
 	int (*glue_get_ctrl_dev)(struct udevice *parent, ofnode *node);
-	void (*glue_configure)(struct udevice *dev, int index,
-			       enum usb_dr_mode mode);
+	void (*glue_configure)(struct udevice *parent, ofnode node, int index);
 };
 
 int dwc3_glue_bind(struct udevice *parent);

-- 
2.43.0

