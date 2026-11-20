From: Ivan Pfarher <ipfarher@gmail.com>
Date: Fri, 20 Nov 2026 12:40:47 +0100
Subject: [PATCH 3/4] arm64: dts: allwinner: h5: orangepi-zero-plus2: Fix
 USB peripheral mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-orangepi-zero-plus2-fixes-v1-3-ecd792189f27@gmail.com>
References: <20261120-orangepi-zero-plus2-fixes-v1-0-ecd792189f27@gmail.com>
In-Reply-To: <20261120-orangepi-zero-plus2-fixes-v1-0-ecd792189f27@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, Ivan Pfarher <ipfarher@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795174845; l=2079;
 i=ipfarher@gmail.com; s=20261120; h=from:subject:message-id;
 bh=xNp8GjP59av7t0jD0DKAR+qLGNBv0iVBKlMlHOJX/bQ=;
 b=LYdIeAg0Z6D9hFAlocH2PSZCyaBHHy6WLerO7QNpZyL8gPTX5MGhRlVA/p/PhMwtgBawPihCa
 rdmDDcSs/jAA4Ylcsg0pIyPD2nV8r7aCpwj4HNwPn8qfRJX8icDs9kq
X-Developer-Key: i=ipfarher@gmail.com; a=ed25519;
 pk=3DMYyz/xl+KRAx2TNGJpheG+5QUm7lqHhKXFqVu2TmY=
X-Endpoint-Received: by B4 Relay for ipfarher@gmail.com/20261120 with auth_id=1582
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The micro USB port is set to dr_mode = "peripheral" because it cannot
supply VBUS, but EHCI0/OHCI0, which share USB PHY 0 with the MUSB
controller, are enabled too.

When they register, usb_add_hcd() asks the shared PHY for host mode
(since commit e671765e521c ("usb: core: Try generic PHY_MODE_USB_HOST
if usb_phy_roothub_set_mode fails")), and phy-sun4i-usb switches PHY 0
to host ("Changing dr_mode to 1"). MUSB then stays in a_wait_vrise, the
UDC stays "not attached", and a gadget never shows up on the host.

The port cannot work as a host on this board anyway, so drop EHCI0 and
OHCI0.

Tested on an Orange Pi Zero Plus2 (H5) running Linux 6.6.160 with this
change applied: g_cdc enumerates on the PC (CDC ECM + ACM), the UDC
state is "configured" and MUSB is in b_peripheral. Build-tested only
against current mainline.

The H3 version of the board (sun8i-h3-orangepi-zero-plus2.dts) has the
same setup from the same commit but is not changed here, as it could
not be tested.

This problem was investigated, and the patch drafted, in an interactive
session with an AI coding assistant (Claude by Anthropic). The submitter
reviewed the change and ran the tests described above.

Fixes: 43aad09c7928 ("ARM: dts: orange-pi-zero-plus2: enable USB OTG port")
Signed-off-by: Ivan Pfarher <ipfarher@gmail.com>
---
 arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts | 8 --------
 1 file changed, 8 deletions(-)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts b/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts
index 5697251b9..892723b46 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts
@@ -66,10 +66,6 @@
 	status = "okay";
 };
 
-&ehci0 {
-	status = "okay";
-};
-
 &hdmi {
 	status = "okay";
 };
@@ -115,10 +111,6 @@
 	status = "okay";
 };
 
-&ohci0 {
-	status = "okay";
-};
-
 &uart0 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&uart0_pa_pins>;

-- 
2.43.0

