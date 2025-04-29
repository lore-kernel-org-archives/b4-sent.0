From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 29 Apr 2025 16:33:33 -0500
Subject: [PATCH 4/4] arm64: tegra: Add Tegra186 pin controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250429-tegra186-pinctrl-v1-4-722c7c42394e@gmail.com>
References: <20250429-tegra186-pinctrl-v1-0-722c7c42394e@gmail.com>
In-Reply-To: <20250429-tegra186-pinctrl-v1-0-722c7c42394e@gmail.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745962426; l=1340;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=nlBNe2tmaWa/9hjMpL12OUQ3+yLCwSi7g9iNZUe7fx0=;
 b=PHL9o8X4kHc29B9os6pRSftB7NaZVGlgAwJuzza09Hgm8RUkBw/gVAFXOneY0Wf464twm7ADu
 t0sq/QfFL05D93yKmq1qEJgHdHTFEg+uajuCZxr7jmIyD4WRkjHsIWK
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the device tree nodes for the MAIN and AON pin controllers found on
the Tegra186 family of SoCs.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra186.dtsi | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra186.dtsi b/arch/arm64/boot/dts/nvidia/tegra186.dtsi
index 2b3bb5d0af17bd521f87db0484fcbe943dd1a797..576a4d8e0f9dbe4ef43f60b9222c1c03f7440aab 100644
--- a/arch/arm64/boot/dts/nvidia/tegra186.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra186.dtsi
@@ -36,6 +36,12 @@ gpio: gpio@2200000 {
 		interrupt-controller;
 		#gpio-cells = <2>;
 		gpio-controller;
+		gpio-ranges = <&pinmux 0 0 140>;
+	};
+
+	pinmux: pinmux@2430000 {
+		compatible = "nvidia,tegra186-pinmux";
+		reg = <0x0 0x2430000 0x0 0x15000>;
 	};
 
 	ethernet@2490000 {
@@ -1272,10 +1278,16 @@ gpio_aon: gpio@c2f0000 {
 		interrupts = <GIC_SPI 60 IRQ_TYPE_LEVEL_HIGH>;
 		gpio-controller;
 		#gpio-cells = <2>;
+		gpio-ranges = <&pinmux_aon 0 0 47>;
 		interrupt-controller;
 		#interrupt-cells = <2>;
 	};
 
+	pinmux_aon: pinmux@c300000 {
+		compatible = "nvidia,tegra186-pinmux-aon";
+		reg = <0x0 0xc300000 0x0 0x4000>;
+	};
+
 	pwm4: pwm@c340000 {
 		compatible = "nvidia,tegra186-pwm";
 		reg = <0x0 0xc340000 0x0 0x10000>;

-- 
2.48.1

