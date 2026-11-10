From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 10:39:06 +0000
Subject: [PATCH 3/3] arm64: dts: rockchip: Mark the Orange Pi 5/5B Type-C
 port self-powered
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-tcpm-attach-reboot-v1-3-7657cc1e2dca@gmail.com>
References: <20261110-tcpm-attach-reboot-v1-0-7657cc1e2dca@gmail.com>
In-Reply-To: <20261110-tcpm-attach-reboot-v1-0-7657cc1e2dca@gmail.com>
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794307143; l=1209;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=z+vxGhU01KVE5a3ZqBJ+uJfWrWfvjtfbECzmzBJv814=;
 b=xRGXBDxcq1rtQtvPBSmY6c9nPZGec9E/oqmuDrREyarhSKPghY6jUNc9pw5Z7FO5MVhqW8bgx
 x3+AsXJbZyeCCMfqsaVtE742F0t4NQQBol9+ZKjFUGtI6E1xkkfMeMb
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The board is powered from its separate power-only USB-C input. The
FUSB302 port's VBUS comes from vcc5v0_sys through a load switch, so the
board never runs from this port's VBUS.

Without self-powered, tcpm keeps Rp on CC during PORT_RESET (error
recovery), because opening CC on a port-powered device would remove its
own supply. With self-powered, the port opens CC for tErrorRecovery
whenever it resets, including at boot. A partner left in a stale state
by a warm reboot then sees a real detach.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
index 6e081bc06cfe..b621fc8638c7 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
@@ -117,6 +117,7 @@ usb_con: connector {
 				<PDO_FIXED(5000, 1000, PDO_FIXED_USB_COMM)>;
 			source-pdos =
 				<PDO_FIXED(5000, 3000, PDO_FIXED_USB_COMM)>;
+			self-powered;
 			try-power-role = "source";
 
 			ports {

-- 
2.55.0

