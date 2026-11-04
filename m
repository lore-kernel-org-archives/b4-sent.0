From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH 0/2] phy: Add the Siflower SF19A2890 USB 2.0 PHY
Date: Wed, 04 Nov 2026 02:21:51 -0500
Message-Id: <20261104-sf19a2890-usb-phy-v1-0-db0cad937614@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA/d6moC/y2NQQ6CMBBFr0Jm7STtBNB6FcOCwiDDArBDiYZwd
 6qyfMn772+gHIQV7tkGgVdRmcYE9pJB09fjk1HaxECGSmsNoXbW1XRzBqN6nPsPFt6Xee4cXQs
 DaTcH7uT9az6qP2v0AzfLN3QagV8xnS2ntu8HhjmPYIoAAAA=
X-Change-ID: 20261102-sf19a2890-usb-phy-5bb644992750
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: Chuanhong Guo <gch981213@gmail.com>, linux-mips@vger.kernel.org, 
 linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776917; l=1830;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=5xOxVIa7y4Bncr1tgiFluYq3mT02k/fOAPJuTB3HPwQ=;
 b=gbBiXRjPrS1uOUFkV7WMVTIj0DPUOx577XxDCUirsdq3WthYc+Rf2RJPaWFA3qhopLlPcPJoL
 +v5VjW7c72IDoSNOW2LtIGBw0evDcvdE8A4jxMe4WcLev/7TLEGbaMM
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

The MAINTAINERS entry that covers these files comes with the MIPS series
"MIPS: Add support for the Siflower SF19A2890"; this series applies on
its own. That entry is also why checkpatch's question about updating
MAINTAINERS for the new files is left unanswered here.

Tested on a GL.iNet GL-SFT1200 with the DWC2 patches: a USB stick
enumerates at 480 Mb/s and reads at 5.6 MB/s (5.0 MB/s with the same
stick on OpenWrt's 6.18 kernel), and comes back after unplugging and
replugging it twice.

[1] https://github.com/981213/linux/commits/siflower-7.1

---
Chuanhong Guo (1):
      phy: siflower: Add SF19A2890 USB 2.0 PHY driver

Joseph Telaak (1):
      dt-bindings: phy: Add Siflower SF19A2890 USB 2.0 PHY

 .../bindings/phy/siflower,sf19a2890-usb-phy.yaml   |  58 +++++++++
 drivers/phy/Kconfig                                |   1 +
 drivers/phy/Makefile                               |   1 +
 drivers/phy/siflower/Kconfig                       |  12 ++
 drivers/phy/siflower/Makefile                      |   2 +
 drivers/phy/siflower/phy-sf19a2890-usb.c           | 143 +++++++++++++++++++++
 6 files changed, 217 insertions(+)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261102-sf19a2890-usb-phy-5bb644992750

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

