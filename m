From: Roadbobek <admin@roadbobek.com>
Subject: [PATCH 0/2] usb/phy: sunxi: Assert reset before deasserting on
 init
Date: Tue, 17 Nov 2026 13:00:41 +0000
Message-Id: <20261117-usb-sunxi-reset-fix-v1-0-c2b76e0e84e1@roadbobek.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDQAyF4atI1g0kIkp7ldLF6ESbLkaZOCLI3
 N3RLr8H7z/AJKoYvKoDomxqOocCflQwfF2YBNUXQ011y8wdJuvRUtgVo5isOOqOnh0RcdOQe0J
 5LlHKfFffn78t9T8Z1isFOZ9oWflAdwAAAA==
X-Change-ID: 20261117-usb-sunxi-reset-fix-d1a0001440a9
To: Bin Liu <b-liu@ti.com>, Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-phy@lists.infradead.org, Roadbobek <admin@roadbobek.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794920443; l=1351;
 i=admin@roadbobek.com; s=20261117; h=from:subject:message-id;
 bh=drgXmTq72phIRmNvyMX2CDu1do9KMGWYoHNHUWHEvOM=;
 b=O92oU708WlHpNSGxF7degjuQB97mTvheQN/ZlYsp/q3UhV1O1Z4f8NqTM9ITdYpochLBYE2i2
 +ib9LHxsVf3A8M3Xui056AQmxxvlvrVW7eKBBCCdThRWSO7dGe+ggya
X-Developer-Key: i=admin@roadbobek.com; a=ed25519;
 pk=TcWSTwITMylwCZLYbw80sv2LQx1zButqiT90TFVvhas=
X-Endpoint-Received: by B4 Relay for admin@roadbobek.com/20261117 with auth_id=1548
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a bootloader such as U-Boot (for example with
CONFIG_USB_MUSB_HOST=y) initializes USB host mode and boots Linux
without stopping USB first, both the MUSB controller and USB0 PHY
reset lines are already deasserted when Linux probes them.

Because reset_control_deassert() alone is a no-op on an already
deasserted reset line, stale hardware register state persists across
boot. On Allwinner A33, MUSB stays wedged in a_wait_bcon with
DevCtl=0x99, Power=0xf0, and a frozen Frame counter even across
hot-unplug and replug.

This two-patch series briefly asserts reset before deasserting it in
both drivers so USB starts cleanly regardless of prior bootloader state:

- Patch 1 asserts glue->rst in sunxi_musb_init().
- Patch 2 asserts phy->reset in sun4i_usb_phy_init().

Tested on an Allwinner A33 Q8 tablet (Laser MID-786).

Signed-off-by: Roadbobek <admin@roadbobek.com>
---
Roadbobek (2):
      usb: musb: sunxi: Assert reset before deasserting on init
      phy: sun4i-usb: Assert reset before deasserting in phy init

 drivers/phy/allwinner/phy-sun4i-usb.c | 2 ++
 drivers/usb/musb/sunxi.c              | 3 +++
 2 files changed, 5 insertions(+)
---
base-commit: 666539eecdf4db623f5e3c3e55cf9f2dfad24aa4
change-id: 20261117-usb-sunxi-reset-fix-d1a0001440a9

Best regards,
--  
Roadbobek <admin@roadbobek.com>

