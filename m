From: Umer Uddin <umer.uddin@mentallysanemainliners.org>
Date: Wed, 25 Nov 2026 16:12:41 +0000
Subject: [PATCH v3 1/2] arm64: dts: exynos: exynos7885-gta3xllte: Enable
 USB support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-gta3xllte-usb-battery-v3-1-2ef962bf5423@mentallysanemainliners.org>
References: <20261125-gta3xllte-usb-battery-v3-0-2ef962bf5423@mentallysanemainliners.org>
In-Reply-To: <20261125-gta3xllte-usb-battery-v3-0-2ef962bf5423@mentallysanemainliners.org>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Umer Uddin <umer.uddin@mentallysanemainliners.org>, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Henri Ommer <henri@ommer.net>, David Virag <virag.david003@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795623167; l=1634;
 i=umer.uddin@mentallysanemainliners.org; s=20261109;
 h=from:subject:message-id; bh=lq3RkQ/cpzRDW2dTSf0wXDxDTq/ch8FNKpY2bDIwhtU=;
 b=xOchDRY8climikJIu/c0kZk8l7G16xlR0c+suCGIHRnwaSkguijrc8Bw7Nod5cCWD+7VwIrDY
 Xxl7rgE3ZIPDXoqr8+oNH+nxhLITY3gptUb6a6MKeQf2yLUpwZSYKbV
X-Developer-Key: i=umer.uddin@mentallysanemainliners.org; a=ed25519;
 pk=Hsgrt4A72CFTe27AI1AAWlnLsiQrlb4+T+cbrfWDhUA=
X-Endpoint-Received: by B4 Relay for umer.uddin@mentallysanemainliners.org/20261109 with auth_id=1466
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung Galaxy Tab A 10.1 (2019) has a USB-C port capable of USB 2.0
speeds, used both as host and device, and is used for charging the
tablet.

The port is controlled by an S2MU005 IC. Until support for it is
added, only USB device functionality is available, so enable the USB
controller and PHY in peripheral mode.

Signed-off-by: Umer Uddin <umer.uddin@mentallysanemainliners.org>
---
 .../arm64/boot/dts/exynos/exynos7885-gta3xllte.dts | 28 ++++++++++++++++++++++
 1 file changed, 28 insertions(+)

diff --git a/arch/arm64/boot/dts/exynos/exynos7885-gta3xllte.dts b/arch/arm64/boot/dts/exynos/exynos7885-gta3xllte.dts
index 03476f8b1200..c71101ed0ba9 100644
--- a/arch/arm64/boot/dts/exynos/exynos7885-gta3xllte.dts
+++ b/arch/arm64/boot/dts/exynos/exynos7885-gta3xllte.dts
@@ -68,6 +68,12 @@ memory@80000000 {
 		      <0x0 0xc0000000 0x40000000>;
 	};
 
+	/* TODO: Remove this once PMIC is implemented */
+	reg_dummy: regulator-0 {
+		compatible = "regulator-fixed";
+		regulator-name = "dummy_reg";
+	};
+
 	reserved-memory {
 		ranges;
 		#address-cells = <2>;
@@ -127,3 +133,25 @@ key_volup: key-volup-pins {
 		samsung,pin-drv = <EXYNOS5420_PIN_DRV_LV1>;
 	};
 };
+
+&usbdrd {
+	vdd10-supply = <&reg_dummy>;
+	vdd33-supply = <&reg_dummy>;
+
+	status = "okay";
+};
+
+&usbdrd_dwc3 {
+	/*
+	 * SoC in theory supports SS but no known device (including this one)
+	 * has it wired up.
+	 */
+	maximum-speed = "high-speed";
+
+	/* Force to peripheral until we have Type-C working */
+	dr_mode = "peripheral";
+};
+
+&usbdrd_phy {
+	status = "okay";
+};

-- 
2.56.1

