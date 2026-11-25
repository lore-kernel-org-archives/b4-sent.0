From: Umer Uddin <umer.uddin@mentallysanemainliners.org>
Date: Wed, 25 Nov 2026 16:12:42 +0000
Subject: [PATCH v3 2/2] arm64: dts: exynos: exynos7885-gta3xllte: Enable
 FuelGauge support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-gta3xllte-usb-battery-v3-2-2ef962bf5423@mentallysanemainliners.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795623167; l=1850;
 i=umer.uddin@mentallysanemainliners.org; s=20261109;
 h=from:subject:message-id; bh=1xi6TN0cxIIMdEWPE8CrGdgk4y/rnvekhNW2VzWmKzE=;
 b=Ng7NpeXzQis6U9eUxFGZh4M8hXp50VKddJ3WiOfFHPTupT8MCJ3QsyBkAe3EdtWqSdkJHGCvu
 xJ4XCytoJNYDWRiaQKnl4LFccNYDIGrAK+VgQqbs0pTn2kmIFCoSL/Y
X-Developer-Key: i=umer.uddin@mentallysanemainliners.org; a=ed25519;
 pk=Hsgrt4A72CFTe27AI1AAWlnLsiQrlb4+T+cbrfWDhUA=
X-Endpoint-Received: by B4 Relay for umer.uddin@mentallysanemainliners.org/20261109 with auth_id=1466
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung Galaxy Tab A 10.1 (2019) has a S2MU005 Multi Function Device
(MFD). It contains PMIC, FG and EXTCON. This commit enables the FG, to be
used with a simple battery device to allow for battery percentages to be
reported.

Signed-off-by: Umer Uddin <umer.uddin@mentallysanemainliners.org>
---
 .../arm64/boot/dts/exynos/exynos7885-gta3xllte.dts | 28 ++++++++++++++++++++++
 1 file changed, 28 insertions(+)

diff --git a/arch/arm64/boot/dts/exynos/exynos7885-gta3xllte.dts b/arch/arm64/boot/dts/exynos/exynos7885-gta3xllte.dts
index c71101ed0ba9..466ae0874880 100644
--- a/arch/arm64/boot/dts/exynos/exynos7885-gta3xllte.dts
+++ b/arch/arm64/boot/dts/exynos/exynos7885-gta3xllte.dts
@@ -22,6 +22,13 @@ aliases {
 		serial2 = &serial_2;
 	};
 
+	battery: battery {
+		compatible = "simple-battery";
+		charge-full-design-microamp-hours = <6000000>;
+		voltage-min-design-microvolt = <3300000>;
+		voltage-max-design-microvolt = <4350000>;
+	};
+
 	chosen {
 		ranges;
 		#address-cells = <2>;
@@ -86,6 +93,20 @@ cont_splash_mem: framebuffer@ec000000 {
 	};
 };
 
+&i2c_0 {
+	status = "okay";
+
+	fuel-gauge@3b {
+		compatible = "samsung,s2mu005-fuel-gauge";
+		reg = <0x3b>;
+		interrupt-parent = <&gpa2>;
+		interrupts = <4 IRQ_TYPE_EDGE_BOTH>;
+		pinctrl-0 = <&fuel_irq>;
+		pinctrl-names = "default";
+		monitored-battery = <&battery>;
+	};
+};
+
 &mmc_0 {
 	bus-width = <8>;
 	cap-mmc-highspeed;
@@ -112,6 +133,13 @@ &oscclk {
 };
 
 &pinctrl_alive {
+	fuel_irq: fuel-irq-pins {
+		samsung,pins = "gpa2-4";
+		samsung,pin-function = <EXYNOS_PIN_FUNC_EINT>;
+		samsung,pin-pud = <EXYNOS_PIN_PULL_NONE>;
+		samsung,pin-drv = <EXYNOS5420_PIN_DRV_LV1>;
+	};
+
 	key_power: key-power-pins {
 		samsung,pins = "gpa1-7";
 		samsung,pin-function = <EXYNOS_PIN_FUNC_F>;

-- 
2.56.1

