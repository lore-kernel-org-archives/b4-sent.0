From: Ricardo Pardini <ricardo@pardini.net>
Date: Tue, 30 Dec 2025 21:19:31 +0100
Subject: [PATCH 2/3] arm64: dts: rockchip: Enable the NPU on FriendlyElec
 CM3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251230-arm64-dts-rockchip-rk3588-npu-enablements-v1-2-d38b182a59e3@pardini.net>
References: <20251230-arm64-dts-rockchip-rk3588-npu-enablements-v1-0-d38b182a59e3@pardini.net>
In-Reply-To: <20251230-arm64-dts-rockchip-rk3588-npu-enablements-v1-0-d38b182a59e3@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1367; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=LYtJ7Pl+FdA/I8ghxhk7iPyl3TvBTU0gE+wWAtE6hso=;
 b=owEBbQGS/pANAwAIATteP+Oex+3pAcsmYgBpVDPYbWywt+jyTrZT7MoyS345KuCIUX9AjgsQm
 a71EhpBcliJATMEAAEIAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCaVQz2AAKCRA7Xj/jnsft
 6eLVB/9KYU1PSKxm4IV0JHX+267cedhnc0K/IoGKsPhWJlVt8g7WQG4/+brNEcFClJGlDA0M6ab
 UGabUfRnRQMaUYPn1WniBFk/zO/D5zONLg9+dehlcT8MsDTwzLWa3fD6ja8t1m/oZzuQOCD7KAg
 UDQg3y+bD/9AlElPqmAxNGEBJr9vhe0W/JmI+lBaKYiNQnOZqbbLADyzH+inpZ9BaSSYTpDq2RH
 H2b9+IxE62JJisBI6zDCGkI4hMigQkt5go7HBj4aWRKFIUY4RI4TOwo5VpoH7lBCz0SZkAMpI9i
 YQ2oALRuEMaKhtCOU8jpsHwddcNo+A6kTKgMK1YE1oUOhKKW
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the NPU on FriendlyElec CM3588.
The regulator vdd_npu_s0 was already described.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 .../dts/rockchip/rk3588-friendlyelec-cm3588.dtsi   | 34 ++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588.dtsi
index af431fdcbea7a..46e33e666bb3d 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-friendlyelec-cm3588.dtsi
@@ -264,6 +264,10 @@ &pd_gpu {
 	domain-supply = <&vdd_gpu_s0>;
 };
 
+&pd_npu {
+	domain-supply = <&vdd_npu_s0>;
+};
+
 &pinctrl {
 	gpio-leds {
 		led_sys_pin: led-sys-pin {
@@ -294,6 +298,36 @@ sd_s0_pwr: sd-s0-pwr {
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

