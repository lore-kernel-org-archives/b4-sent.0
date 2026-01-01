From: Ricardo Pardini <ricardo@pardini.net>
Date: Thu, 01 Jan 2026 07:43:09 +0100
Subject: [PATCH v2 1/3] arm64: dts: rockchip: Enable the NPU on NanoPC
 T6/T6-LTS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-arm64-dts-rockchip-rk3588-npu-enablements-v2-1-013cf5d5c39d@pardini.net>
References: <20260101-arm64-dts-rockchip-rk3588-npu-enablements-v2-0-013cf5d5c39d@pardini.net>
In-Reply-To: <20260101-arm64-dts-rockchip-rk3588-npu-enablements-v2-0-013cf5d5c39d@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jimmy Hon <honyuenkwun@gmail.com>, Tomeu Vizoso <tomeu@tomeuvizoso.net>, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1717; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=shFG9R6+v5sNoFpWnfg7ZTJoiZw4vZTXsI7KdVCsRTs=;
 b=owEBbQGS/pANAwAIATteP+Oex+3pAcsmYgBpVheh7MFP/7SozKGqT+2LoTktB4u2fxOXWTiDT
 nu3Y1cAdY6JATMEAAEIAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCaVYXoQAKCRA7Xj/jnsft
 6RNOB/9efcvKbL7zz3E+rnkdD2iazUZI9FmPbkEcR0H0nBk7FFKDdaHiRhWoIepZ9nFKMk6y7zo
 Hho6TSDexjkPswr+1LqKX1DlBAAKnn9gHxjAWJqHDSu3rZK7RcgmXoUa3YA+OwpgalGbhH5jnzt
 keZqSoZiJo2AOp+zyPLmxn4sbT0gqV86turDQk4iwh+CxuxWSO4kZn7BozCUIJxwWBO9dLx4Mk7
 YhQ4g2KrNSZeuEyX/kulvAI51pG4ASPI2JWXUtGzN76AwQq28h/Zz+HILHfI54I/c1/rTsI+EYb
 JuNHoUYGO+C4/aaXY6E7Qf+xUlmF1D9RWO5FZDvvjtPh8jBY
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the NPU on FriendlyElec NanoPC T6/T6-LTS boards.
The regulator vdd_npu_s0 was already in place; since
the NPU power domain supply is now described, remove the
regulator's always-on.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi | 36 +++++++++++++++++++++-
 1 file changed, 35 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
index fafeabe9adf9e..90e7fe254491b 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
@@ -458,7 +458,6 @@ vdd_npu_s0: regulator@42 {
 		reg = <0x42>;
 		fcs,suspend-voltage-selector = <1>;
 		regulator-name = "vdd_npu_s0";
-		regulator-always-on;
 		regulator-boot-on;
 		regulator-min-microvolt = <550000>;
 		regulator-max-microvolt = <950000>;
@@ -629,6 +628,10 @@ &pd_gpu {
 	domain-supply = <&vdd_gpu_s0>;
 };
 
+&pd_npu {
+	domain-supply = <&vdd_npu_s0>;
+};
+
 &pinctrl {
 	gpio-leds {
 		sys_led_pin: sys-led-pin {
@@ -706,6 +709,37 @@ &pwm1 {
 	status = "okay";
 };
 
+&rknn_core_0 {
+	npu-supply = <&vdd_npu_s0>;
+	sram-supply = <&vdd_npu_s0>;
+	status = "okay";
+};
+
+&rknn_core_1 {
+	npu-supply = <&vdd_npu_s0>;
+	sram-supply = <&vdd_npu_s0>;
+	status = "okay";
+};
+
+&rknn_core_2 {
+	npu-supply = <&vdd_npu_s0>;
+	sram-supply = <&vdd_npu_s0>;
+	status = "okay";
+};
+
+&rknn_mmu_0 {
+	status = "okay";
+};
+
+&rknn_mmu_1 {
+	status = "okay";
+};
+
+&rknn_mmu_2 {
+	status = "okay";
+};
+
+
 &saradc {
 	vref-supply = <&avcc_1v8_s0>;
 	status = "okay";

-- 
2.52.0

