From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH v2 0/2] phy: Add the Siflower SF19A2890 USB 2.0 PHY
Date: Mon, 16 Nov 2026 19:31:31 -0500
Message-Id: <20261116-sf19a2890-usb-phy-v2-0-df3ce9d23f5a@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGOg+2oC/22OQQ6CMBBFr2K6dkxbC1hX3sOwaOkgVQPYlkZCu
 LsFNW5cvsn//81EPDqLnhw3E3EYrbddm4BvN6RqVHtBsCYx4ZTnjFEOvmZS8YOkMHgNfTNCpnU
 uhJS8yChJvd5hbZ/r5rl8sx/0FauwDH0SDh9DkoVfrLE+dG5cP4lsuX6l4o80MqBgNK2UkfsiZ
 +IU8K7UbWcwknKe5xdhdQyo2gAAAA==
X-Change-ID: 20261102-sf19a2890-usb-phy-5bb644992750
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: Chuanhong Guo <gch981213@gmail.com>, linux-mips@vger.kernel.org, 
 linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Conor Dooley <conor.dooley@microchip.com>, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794875503; l=2526;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=KCD1K/RN5VnCsfZu7rP3RZx/6edB+L0TT1Z4KmlF39I=;
 b=WcdohhKHXSOvPKligVFFb1OadZvEoZIDiJQUqATxR0TTAkUhAMRhpnu+IGra/PT827BRGH/kv
 fP+pa6WRHIoDE1zcapecz2lQXoH9+Zaa9VNR0wkfFOKAEZTLL7Z4gqi
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a binding and a driver for the USB 2.0 PHY of the
Siflower SF19A2890, a MIPS SoC for home routers. The PHY takes its
reference clock and its two resets from the USB block's clock and reset
manager, which goes to the clk tree.

The driver is Chuanhong Guo's, from his SF19A2890 branch [1], with my
changes noted.

The SoC support itself (MACH_SIFLOWER_MIPS) goes through the MIPS tree;
until then the driver builds with COMPILE_TEST. The DWC2 part goes to
the USB tree.

Tested on a GL.iNet GL-SFT1200 with the DWC2 patches. With v1 on
v7.4-rc1, a USB stick enumerates at 480 Mb/s and reads at 5.6 MB/s
(5.0 MB/s with the same stick on OpenWrt's 6.18 kernel), and comes back
after unplugging and replugging it twice. v2 takes the resets with the
bulk API, so it was run again, on OpenWrt's 6.18 kernel with the driver
backported: the stick enumerates at 480 Mb/s after a cold and a warm
boot and after reloading dwc2, which powers the PHY off and on, and
comes back after a replug.

[1] https://github.com/981213/linux/commits/siflower-7.1

---
Changes in v2:
- Write my note on Chuanhong's patch as a list.
- Add a MAINTAINERS entry for the driver and its binding, naming the
  driver's file, since drivers/phy/siflower/ will also hold the SF21
  PHY drivers.
- Get and toggle both resets with the reset_control_bulk API (Philipp).
- Word the error messages the same way, name the error labels, include
  <linux/device-id/of.h> instead of <linux/of.h>, and use GPL-2.0-only,
  not the deprecated GPL-2.0 SPDX identifier.
- Patch 1: add Conor's Ack.
- Link to v1: https://patch.msgid.link/20261104-sf19a2890-usb-phy-v1-0-db0cad937614@telaak.dev

---
Chuanhong Guo (1):
      phy: siflower: Add SF19A2890 USB 2.0 PHY driver

Joseph Telaak (1):
      dt-bindings: phy: Add Siflower SF19A2890 USB 2.0 PHY

 .../bindings/phy/siflower,sf19a2890-usb-phy.yaml   |  58 +++++++++
 MAINTAINERS                                        |   7 ++
 drivers/phy/Kconfig                                |   1 +
 drivers/phy/Makefile                               |   1 +
 drivers/phy/siflower/Kconfig                       |  12 ++
 drivers/phy/siflower/Makefile                      |   2 +
 drivers/phy/siflower/phy-sf19a2890-usb.c           | 132 +++++++++++++++++++++
 7 files changed, 213 insertions(+)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261102-sf19a2890-usb-phy-5bb644992750

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

