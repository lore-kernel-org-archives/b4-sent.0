From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:35:56 +0000
Subject: [PATCH RFC 2/2] usb: dwc3: rockchip: Keep the host bus across
 suspend-to-idle on RK3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-dwc3-s2idle-optin-v1-2-842e3f8413d0@gmail.com>
References: <20261112-dwc3-s2idle-optin-v1-0-842e3f8413d0@gmail.com>
In-Reply-To: <20261112-dwc3-s2idle-optin-v1-0-842e3f8413d0@gmail.com>
To: Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Joonhoe Kim <26rote@gmail.com>, Vladyslav Tymoshchuk <tvlad744@gmail.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794472554; l=1952;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=4m0AQqWpGKPZoBJEUVc5orPxlJLCumo8flIRD0Jhzsg=;
 b=1Rei5oJ+08YlofUig3fWgdtvOgiGxs4NW+SWHbbWBF2YWA5RUY2o/c/uuwbP54D2cn4Agdcu9
 3QSGOtXzFlTAWSd5UjP6SG8QkQzPfFOfk5MYpaFOdFQP6HgWvwdCMYE
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On RK3588 nothing powers the USB3 controllers down in suspend-to-idle:
this glue has no system sleep work of its own, the controllers are
either in PD_USB, which has GENPD_FLAG_ACTIVE_WAKEUP and so stays on for
a device on the awake path, or (USB3OTG2) in no power domain at all.
Tearing the core down there only ends the power sessions of the
suspended devices: on an Orange Pi 5 a SanDisk Extreme drive and a card
reader behind a USB3 hub are disconnected and enumerated again after
every resume, which kills a filesystem mounted on them.

Set keep_host_bus_in_s2idle for RK3588, so the core keeps the suspended
bus in suspend-to-idle. RK3576 is left as it is: its second controller
is in PD_PHP, which is switched off in suspend-to-idle.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/usb/dwc3/dwc3-rockchip.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/usb/dwc3/dwc3-rockchip.c b/drivers/usb/dwc3/dwc3-rockchip.c
index 65d17536af14..c96b2ac1a62d 100644
--- a/drivers/usb/dwc3/dwc3-rockchip.c
+++ b/drivers/usb/dwc3/dwc3-rockchip.c
@@ -4,6 +4,7 @@
 #include <linux/platform_device.h>
 #include <linux/phy/rockchip-usbdp.h>
 #include <linux/pm_runtime.h>
+#include <linux/property.h>
 #include "glue.h"
 #include "io.h"
 
@@ -153,6 +154,15 @@ static int dwc3_rockchip_probe(struct platform_device *pdev)
 	probe_data.res = res;
 	probe_data.properties = DWC3_DEFAULT_PROPERTIES;
 
+	/*
+	 * On RK3588 nothing powers the controllers down in suspend-to-idle:
+	 * this glue does not touch them, and they are either in PD_USB, which
+	 * stays on for a device on the awake path, or in no power domain.
+	 * (On RK3576 the second controller is in PD_PHP, which does not.)
+	 */
+	if (device_is_compatible(&pdev->dev, "rockchip,rk3588-dwc3"))
+		probe_data.properties.keep_host_bus_in_s2idle = true;
+
 	return dwc3_core_probe(&probe_data);
 }
 

-- 
2.55.0

