From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 04 Apr 2025 03:17:29 -0500
Subject: [PATCH] phy: tegra: xusb: Default otg mode to peripheral
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250404-xusb-peripheral-v1-1-99c184b9bf5f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAJiV72cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEwMT3YrS4iTdAqCmgozUosQc3WQT0yRDM2PzNGPjJCWgroKi1LTMCrC
 J0bG1tQD44iNRYQAAAA==
X-Change-ID: 20250404-xusb-peripheral-c45b1637f33b
To: JC Kuo <jckuo@nvidia.com>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-phy@lists.infradead.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743754715; l=1543;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=02vuqpYVHM7yfAaBTJbe6AZ084fOjTN9Ney/idMUyM4=;
 b=Ifh17Js/Rv1KGxy41smqbJVdAi2qz971idOpYHlEA3F0lbHVFg4YbFSKOKSuHaYqYT+88Gfgv
 LSng9B9NDvwArVJDIx7gn8g5nSzee5su96037mRcIZOdi8SV3jsbh71
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, if usb-role-switch is set and role-switch-default-mode is
not, a xusb port will be inoperable until that port is hotplugged,
because the driver defaults to role none. Instead of requiring all
devices to set the default mode, assume that the port is primarily
intended for use in device mode. This assumption already has precedence
in the synopsys dwc3 driver.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/phy/tegra/xusb.c | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/drivers/phy/tegra/xusb.c b/drivers/phy/tegra/xusb.c
index 79d4814d758d5e1f0e8200d61e131606adbb0e2d..c56e83216d0f566a09b67377172fb04c8406f4cf 100644
--- a/drivers/phy/tegra/xusb.c
+++ b/drivers/phy/tegra/xusb.c
@@ -731,13 +731,11 @@ static void tegra_xusb_parse_usb_role_default_mode(struct tegra_xusb_port *port)
 
 	if (mode == USB_DR_MODE_HOST)
 		role = USB_ROLE_HOST;
-	else if (mode == USB_DR_MODE_PERIPHERAL)
+	else
 		role = USB_ROLE_DEVICE;
 
-	if (role != USB_ROLE_NONE) {
-		usb_role_switch_set_role(port->usb_role_sw, role);
-		dev_dbg(&port->dev, "usb role default mode is %s", modes[mode]);
-	}
+	usb_role_switch_set_role(port->usb_role_sw, role);
+	dev_dbg(&port->dev, "usb role default mode is %s", modes[mode]);
 }
 
 static int tegra_xusb_usb2_port_parse_dt(struct tegra_xusb_usb2_port *usb2)

---
base-commit: 91e5bfe317d8f8471fbaa3e70cf66cae1314a516
change-id: 20250404-xusb-peripheral-c45b1637f33b

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

