From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 03 Feb 2024 07:01:56 +0800
Subject: [PATCH 3/3] usb: dwc3: add glue driver for Hi3798MV200
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240203-hisi-dwc3-v1-3-448050c7b690@outlook.com>
References: <20240203-hisi-dwc3-v1-0-448050c7b690@outlook.com>
In-Reply-To: <20240203-hisi-dwc3-v1-0-448050c7b690@outlook.com>
To: Marek Vasut <marex@denx.de>, Tom Rini <trini@konsulko.com>, 
 Sean Anderson <sean.anderson@seco.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706914914; l=2367;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=s/uGat4mcwI1MhFm8NxotPzNvm6CCqM8lql07wQqGF8=;
 b=5csjwcPLU0HNyGZJ5J6U4IcWGbfoQ3dXdm5Q5+cGpTyjUms39eDS38ZfH17DtVjpVLJtTkeWW
 /ZdE/0hDMQ9A+XI9vp0W1aCKPMigK3e+VENZIc43uU75xKMzm2nOhL6
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It needs some platform-specific operations before generic initialization
code.

If nano PHY is not initialized properly, it must be disabled. Or else
 USB host will complain unable to reset port.

USB2 is always supported, so it's never disabled.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/usb/dwc3/dwc3-generic.c | 40 ++++++++++++++++++++++++++++++++++++++++
 1 file changed, 40 insertions(+)

diff --git a/drivers/usb/dwc3/dwc3-generic.c b/drivers/usb/dwc3/dwc3-generic.c
index d892042b91..a3200ff1ab 100644
--- a/drivers/usb/dwc3/dwc3-generic.c
+++ b/drivers/usb/dwc3/dwc3-generic.c
@@ -419,6 +419,45 @@ struct dwc3_glue_ops rk_ops = {
 	.glue_get_ctrl_dev = dwc3_rk_glue_get_ctrl_dev,
 };
 
+static void dwc3_hi3798mv200_glue_configure(struct udevice *dev, ofnode child, int index)
+{
+#define HI3798MV200_PERI_CTRL_ADDR	0xf8a20000
+#define HI3798MV200_PERI_USB5		0x134
+#define USB3_U3_PORT_DISABLE		BIT(5)
+#define USB3_U2_PORT_DISABLE		BIT(4)
+
+	// Disable super-speed port if maximum speed is high-speed
+	void __iomem *peri_base = map_physmem(HI3798MV200_PERI_CTRL_ADDR, 0x1000, MAP_NOCACHE);
+	enum usb_device_speed speed = usb_get_maximum_speed(child);
+	u32 reg;
+
+	reg = readl(peri_base + HI3798MV200_PERI_USB5);
+	reg &= ~(USB3_U3_PORT_DISABLE | USB3_U2_PORT_DISABLE);
+
+	switch (speed) {
+	case USB_SPEED_LOW:
+	case USB_SPEED_FULL:
+	case USB_SPEED_HIGH:
+		// disable super-speed port
+		reg |= USB3_U3_PORT_DISABLE;
+		pr_info("%s: super-speed port disabled.\n", __func__);
+		break;
+
+	case USB_SPEED_SUPER:
+		break;
+
+	default:
+		pr_warn("%s: unknown speed class %d.\n", __func__, speed);
+	}
+
+	writel(reg, peri_base + HI3798MV200_PERI_USB5);
+	unmap_physmem(peri_base, MAP_NOCACHE);
+}
+
+const struct dwc3_glue_ops hi3798mv200_ops = {
+	.glue_configure = dwc3_hi3798mv200_glue_configure,
+};
+
 static int dwc3_glue_bind_common(struct udevice *parent, ofnode node)
 {
 	const char *name = ofnode_get_name(node);
@@ -611,6 +650,7 @@ static const struct udevice_id dwc3_glue_ids[] = {
 	{ .compatible = "fsl,imx8mp-dwc3", .data = (ulong)&imx8mp_ops },
 	{ .compatible = "fsl,imx8mq-dwc3" },
 	{ .compatible = "intel,tangier-dwc3" },
+	{ .compatible = "hisilicon,hi3798mv200-dwc3", .data = (ulong)&hi3798mv200_ops },
 	{ }
 };
 

-- 
2.43.0

