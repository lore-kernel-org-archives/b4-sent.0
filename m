From: Ivan Pfarher <ipfarher@gmail.com>
Date: Fri, 20 Nov 2026 12:40:46 +0100
Subject: [PATCH 2/4] arm64: dts: allwinner: h5: orangepi-zero-plus2: Add
 AP6212 Bluetooth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-orangepi-zero-plus2-fixes-v1-2-ecd792189f27@gmail.com>
References: <20261120-orangepi-zero-plus2-fixes-v1-0-ecd792189f27@gmail.com>
In-Reply-To: <20261120-orangepi-zero-plus2-fixes-v1-0-ecd792189f27@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, Ivan Pfarher <ipfarher@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795174845; l=2073;
 i=ipfarher@gmail.com; s=20261120; h=from:subject:message-id;
 bh=N+gCZKSFdjvJNosqW8VyXfcloLRjV1OkNZSQDadOkiI=;
 b=tPfPEbATNv3mq+JDkKPCdtxG1k6VqvAhezObKAw6Yhbn9XisANtaKSEEGKFjIVb+0f4xtEo0b
 W/VY2mu9j1PDB5pZlH6mVg2X4CnPeiiXqlDLPeTr2H3lhmcb/StPSvF
X-Developer-Key: i=ipfarher@gmail.com; a=ed25519;
 pk=3DMYyz/xl+KRAx2TNGJpheG+5QUm7lqHhKXFqVu2TmY=
X-Endpoint-Received: by B4 Relay for ipfarher@gmail.com/20261120 with auth_id=1582
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

UART1 is connected to the Bluetooth part of the AP6212 module, but the
controller itself is not described, so nothing powers it up and the
kernel never registers it.

Add it as a serdev child of UART1. BT_REG_ON is connected to PA10:
on the board, driving PA10 low makes the controller drop CTS and stop
answering, driving it high brings it back. It uses the same RTC LPO
clock as the WiFi part. The wake-up lines are not described because
they could not be identified.

Tested on an Orange Pi Zero Plus2 (H5) running Linux 6.6.160 with this
change applied: hci_bcm powers the controller, loads
brcm/BCM43430A1.hcd, switches the UART to 1.5 Mbaud and the adapter
works with BlueZ (scan finds nearby devices):

  Bluetooth: hci0: BCM43430A1 'brcm/BCM43430A1.hcd' Patch
  Bluetooth: hci0: BCM43438A1 26MHz AP6212A1_CL1 BT4.0 OTP-BD-0034

Build-tested only against current mainline.

This problem was investigated, and the patch drafted, in an interactive
session with an AI coding assistant (Claude by Anthropic). The submitter
reviewed the change and ran the tests described above.

Signed-off-by: Ivan Pfarher <ipfarher@gmail.com>
---
 .../boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts      | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts b/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts
index 34d6c1468..5697251b9 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h5-orangepi-zero-plus2.dts
@@ -128,7 +128,18 @@
 &uart1 {
 	pinctrl-names = "default";
 	pinctrl-0 = <&uart1_pins>, <&uart1_rts_cts_pins>;
+	uart-has-rtscts;
 	status = "okay";
+
+	bluetooth {
+		compatible = "brcm,bcm43438-bt";
+		max-speed = <1500000>;
+		clocks = <&rtc CLK_OSC32K_FANOUT>;
+		clock-names = "lpo";
+		vbat-supply = <&reg_vcc3v3>;
+		vddio-supply = <&reg_vcc3v3>;
+		shutdown-gpios = <&pio 0 10 GPIO_ACTIVE_HIGH>; /* PA10 */
+	};
 };
 
 &usb_otg {

-- 
2.43.0

