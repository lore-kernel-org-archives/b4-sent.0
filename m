From: Umer Uddin <umer.uddin@mentallysanemainliners.org>
Date: Thu, 19 Nov 2026 19:49:20 +0000
Subject: [PATCH 4/6] arm64: dts: exynos: Enable USB in Exynos7885
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-gta3xllte-usb-battery-v1-4-0cf5f763522e@mentallysanemainliners.org>
References: <20261119-gta3xllte-usb-battery-v1-0-0cf5f763522e@mentallysanemainliners.org>
In-Reply-To: <20261119-gta3xllte-usb-battery-v1-0-0cf5f763522e@mentallysanemainliners.org>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, 
 Umer Uddin <umer.uddin@mentallysanemainliners.org>, 
 David Virag <virag.david003@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795117759; l=2109;
 i=umer.uddin@mentallysanemainliners.org; s=20261109;
 h=from:subject:message-id; bh=Z90I+ZgSvTHKtQhv8fIplgrzwo46zX8M8n1SBbl4siw=;
 b=3uCw2rXhAwhlB/yoGbbyMLAd57ifkF6WctONIGReP8/YmugqWx5fu4psFBPq3Bx8x5tOarECl
 a+5rCl4oaMmCTLelMQ+e1AUcZ92OorKL2QuSVSdNSETRD7DIDGAUU8f
X-Developer-Key: i=umer.uddin@mentallysanemainliners.org; a=ed25519;
 pk=Hsgrt4A72CFTe27AI1AAWlnLsiQrlb4+T+cbrfWDhUA=
X-Endpoint-Received: by B4 Relay for umer.uddin@mentallysanemainliners.org/20261109 with auth_id=1466
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: David Virag <virag.david003@gmail.com>

Add USB controller and USB PHY controller nodes to Exynos7885 SoC DTSI.

The SoC theoretically supports USB3 SuperSpeed, but is not implemented
in any known device. The vendor kernel also stubs out USB3 functions, so
we do not support it.

It is though, perfectly capable of USB 2.0 high-speed mode, both as host
and device.

Signed-off-by: David Virag <virag.david003@gmail.com>
[Umer Uddin: Rebased onto krzk for-next branch]
Signed-off-by: Umer Uddin <umer.uddin@mentallysanemainliners.org>
---
 arch/arm64/boot/dts/exynos/exynos7885.dtsi | 43 ++++++++++++++++++++++++++++++
 1 file changed, 43 insertions(+)

diff --git a/arch/arm64/boot/dts/exynos/exynos7885.dtsi b/arch/arm64/boot/dts/exynos/exynos7885.dtsi
index 6b994b487107..142542245cb1 100644
--- a/arch/arm64/boot/dts/exynos/exynos7885.dtsi
+++ b/arch/arm64/boot/dts/exynos/exynos7885.dtsi
@@ -480,6 +480,49 @@ i2c_7: i2c@11cd0000 {
 
 			status = "disabled";
 		};
+
+		usbdrd: usb@13600000 {
+			compatible = "samsung,exynos7885-dwusb3",
+				     "samsung,exynos850-dwusb3";
+			ranges = <0x0 0x13600000 0x10000>;
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			clocks = <&cmu_fsys CLK_FSYS_USB30DRD_BUS_CLK_EARLY>,
+				 <&cmu_fsys CLK_FSYS_USB30DRD_REF_CLK>;
+			clock-names = "bus_early", "ref";
+
+			status = "disabled";
+
+			usbdrd_dwc3: usb@0 {
+				compatible = "snps,dwc3";
+				reg = <0x0 0x10000>;
+				interrupts = <GIC_SPI 135 IRQ_TYPE_LEVEL_HIGH>;
+
+				phys = <&usbdrd_phy 0>;
+				phy-names = "usb2-phy";
+
+				/*
+				 * SoC in theory supports SS but no device has it.
+				 * Actual capabilities unknown.
+				 */
+				maximum-speed = "high-speed";
+			};
+		};
+
+		usbdrd_phy: phy@135d0000 {
+			compatible = "samsung,exynos7885-usbdrd-phy";
+			reg = <0x135d0000 0x100>;
+			#phy-cells = <1>;
+
+			clocks = <&cmu_fsys CLK_FSYS_USB30DRD_ACLK_20PHYCTRL>,
+				 <&cmu_fsys CLK_FSYS_USB20PHY_CLKCORE>;
+			clock-names = "phy", "ref";
+
+			samsung,pmu-syscon = <&pmu_system_controller>;
+
+			status = "disabled";
+		};
 	};
 };
 

-- 
2.56.1

