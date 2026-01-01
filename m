From: Ricardo Pardini <ricardo@pardini.net>
Date: Thu, 01 Jan 2026 07:43:10 +0100
Subject: [PATCH v2 2/3] arm64: dts: rockchip: Enable the NPU on
 FriendlyElec CM3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-arm64-dts-rockchip-rk3588-npu-enablements-v2-2-013cf5d5c39d@pardini.net>
References: <20260101-arm64-dts-rockchip-rk3588-npu-enablements-v2-0-013cf5d5c39d@pardini.net>
In-Reply-To: <20260101-arm64-dts-rockchip-rk3588-npu-enablements-v2-0-013cf5d5c39d@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jimmy Hon <honyuenkwun@gmail.com>, Tomeu Vizoso <tomeu@tomeuvizoso.net>, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1738; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=/oDfWXpDVXmpYIy9Sg0dUU5JsZFn82Eu22Dm+M4KcYk=;
 b=owEBbQGS/pANAwAIATteP+Oex+3pAcsmYgBpVheh6Ix5kMNtCOZEa8p5wxVW4TXI1nDb4wTxR
 eVy/gjRLBSJATMEAAEIAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCaVYXoQAKCRA7Xj/jnsft
 6Rw2B/9cyLpVG+UBbhSTB1cTyTqKi+MrY1YtRWkV5VIfAqlzqYg2sVUHh9AekDM/m/e3ElbrYLI
 5D4Ti5xAjF8R3gwRhn8vAjLJ5i6aYsRaiiFz6Sc2bnDGCTEhLLuKU15bH20l/YUzXkV1MZ0a9tx
 ur5I5yevDj2mt/MSxLjawDvI1PPtWq7ejCXnhjOCcQHTjI1uBRSOLA14tmzNucSgbDgMMnPUWML
 vgIEtjjeLoYx5mwhoX68+SGNnpuR3ybXTyLg27CaZuXjBhTrB1dhSifNSoVwu41mHVFVpjSMvfv
 7ltO5HSriyc0h6hGC/cOhRbVtJ0UQ9MV3YeOaugSyN20f2W0
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the NPU on FriendlyElec CM3588.
The regulator vdd_npu_s0 was already in place; since
the NPU power domain supply is now described, remove the
regulator's always-on.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 .../dts/rockchip/rk3588-friendlyelec-cm3588.dtsi   | 35 +++++++++++++++++++++-
 1 file changed, 34 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588.dtsi
index af431fdcbea7a..49cf4b85c4e96 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588.dtsi
@@ -182,7 +182,6 @@ vdd_npu_s0: regulator@42 {
 		reg = <0x42>;
 		fcs,suspend-voltage-selector = <1>;
 		regulator-name = "vdd_npu_s0";
-		regulator-always-on;
 		regulator-boot-on;
 		regulator-min-microvolt = <550000>;
 		regulator-max-microvolt = <950000>;
@@ -264,6 +263,10 @@ &pd_gpu {
 	domain-supply = <&vdd_gpu_s0>;
 };
 
+&pd_npu {
+	domain-supply = <&vdd_npu_s0>;
+};
+
 &pinctrl {
 	gpio-leds {
 		led_sys_pin: led-sys-pin {
@@ -294,6 +297,36 @@ sd_s0_pwr: sd-s0-pwr {
 	};
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
 &saradc {
 	vref-supply = <&avcc_1v8_s0>;
 	status = "okay";

-- 
2.52.0

