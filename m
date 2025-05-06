From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 06 May 2025 12:09:18 -0500
Subject: [PATCH v2 2/2] phy: tegra: xusb: Default otg mode to peripheral
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250506-xusb-peripheral-v2-2-bfbe00671389@gmail.com>
References: <20250506-xusb-peripheral-v2-0-bfbe00671389@gmail.com>
In-Reply-To: <20250506-xusb-peripheral-v2-0-bfbe00671389@gmail.com>
To: JC Kuo <jckuo@nvidia.com>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-phy@lists.infradead.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746551373; l=1618;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=WY090858pJtzoKww7YaC7Z9JTjET1bec4L1964gg6J4=;
 b=NaDOg+nVQv05p86Ta/79J6j2EU3M3vcxowUBXmQydstuVgGIULGpaJycP9oGlAbZopQhyWfpF
 OWzO8bM+nO6Cp/bxIk33uX0ce/QeUjBV6iUHqoiGfgtc3beuBTn+vi1
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, if usb-role-switch is set and role-switch-default-mode is
not, a xusb port will be inoperable until that port is hotplugged,
because the driver defaults to role none. Instead of requiring all
devices to set the default mode, assume that the port is primarily
intended for use in device mode.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/phy/tegra/xusb.c | 11 ++++-------
 1 file changed, 4 insertions(+), 7 deletions(-)

diff --git a/drivers/phy/tegra/xusb.c b/drivers/phy/tegra/xusb.c
index 79d4814d758d5e1f0e8200d61e131606adbb0e2d..22338f3f24a0794c22544a0e16e0fc706c4fb6d7 100644
--- a/drivers/phy/tegra/xusb.c
+++ b/drivers/phy/tegra/xusb.c
@@ -726,18 +726,15 @@ static int tegra_xusb_setup_usb_role_switch(struct tegra_xusb_port *port)
 
 static void tegra_xusb_parse_usb_role_default_mode(struct tegra_xusb_port *port)
 {
-	enum usb_role role = USB_ROLE_NONE;
+	/* Most switchable usb ports are normally used in device mode */
+	enum usb_role role = USB_ROLE_DEVICE;
 	enum usb_dr_mode mode = usb_get_role_switch_default_mode(&port->dev);
 
 	if (mode == USB_DR_MODE_HOST)
 		role = USB_ROLE_HOST;
-	else if (mode == USB_DR_MODE_PERIPHERAL)
-		role = USB_ROLE_DEVICE;
 
-	if (role != USB_ROLE_NONE) {
-		usb_role_switch_set_role(port->usb_role_sw, role);
-		dev_dbg(&port->dev, "usb role default mode is %s", modes[mode]);
-	}
+	usb_role_switch_set_role(port->usb_role_sw, role);
+	dev_dbg(&port->dev, "usb role default mode is %s", modes[mode]);
 }
 
 static int tegra_xusb_usb2_port_parse_dt(struct tegra_xusb_usb2_port *usb2)

-- 
2.48.1

