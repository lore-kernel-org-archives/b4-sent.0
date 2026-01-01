From: Ricardo Pardini <ricardo@pardini.net>
Date: Thu, 01 Jan 2026 07:43:11 +0100
Subject: [PATCH v2 3/3] arm64: dts: rockchip: Enable the NPU on Turing RK1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-arm64-dts-rockchip-rk3588-npu-enablements-v2-3-013cf5d5c39d@pardini.net>
References: <20260101-arm64-dts-rockchip-rk3588-npu-enablements-v2-0-013cf5d5c39d@pardini.net>
In-Reply-To: <20260101-arm64-dts-rockchip-rk3588-npu-enablements-v2-0-013cf5d5c39d@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jimmy Hon <honyuenkwun@gmail.com>, Tomeu Vizoso <tomeu@tomeuvizoso.net>, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1656; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=U3z//lMNVVVOhXu8sqy/9jYcCMBg51abWkRs/utgick=;
 b=owEBbQGS/pANAwAIATteP+Oex+3pAcsmYgBpVheiY0StyS1yWbqibJ/lLj41BFqKPrn8jEIN/
 /nbEkfbD6GJATMEAAEIAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCaVYXogAKCRA7Xj/jnsft
 6fuvCACpI1CWwJDHaE1NTbe+IO8QAYbUZwnQuwNNo19Dm7GvkaycTb6dxNh5wn76FwoB+JQYgeg
 rqwr+RyXuYCA7RgjEI3rLz8AR+357Y132Nv2CiL6ZwbHZhbu7emxVtgXfnAQQ7m/nBASZAKx/+k
 dkQIhO8epwFyoWdLBM+q1CcoXMjXT1O20AwQlDAo5G/Juz+hu7mkgAMe/j3arbveszy3Uuq4ZJA
 S3pPcZ28jB4LYM/WY/g6iXeDz55I+caW62uanaJroSjMgLiPUAYq/FYa9x3a+qsqPBY4Zjp7gim
 eBACVKgZNHFZP6Veq+d1mQt0VwMQB21Hi9ElXBG9q0oTTJIy
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the NPU on Turing RK1.
The regulator vdd_npu_s0 was already in place; since
the NPU power domain supply is now described, remove the
regulator's always-on.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 .../arm64/boot/dts/rockchip/rk3588-turing-rk1.dtsi | 35 +++++++++++++++++++++-
 1 file changed, 34 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-turing-rk1.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-turing-rk1.dtsi
index 6daea8961fdd6..b11d24dcc1806 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-turing-rk1.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-turing-rk1.dtsi
@@ -171,7 +171,6 @@ vdd_npu_s0: regulator@42 {
 		reg = <0x42>;
 		fcs,suspend-voltage-selector = <1>;
 		regulator-name = "vdd_npu_s0";
-		regulator-always-on;
 		regulator-boot-on;
 		regulator-min-microvolt = <550000>;
 		regulator-max-microvolt = <950000>;
@@ -293,6 +292,10 @@ &pd_gpu {
 	domain-supply = <&vdd_gpu_s0>;
 };
 
+&pd_npu {
+	domain-supply = <&vdd_npu_s0>;
+};
+
 &pinctrl {
 	fan {
 		fan_int: fan-int {
@@ -333,6 +336,36 @@ &pwm0 {
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
 &sdhci {
 	bus-width = <8>;
 	no-sdio;

-- 
2.52.0

