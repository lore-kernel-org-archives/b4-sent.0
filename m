From: Ricardo Pardini <ricardo@pardini.net>
Date: Tue, 30 Dec 2025 21:19:30 +0100
Subject: [PATCH 1/3] arm64: dts: rockchip: Enable the NPU on NanoPC
 T6/T6-LTS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251230-arm64-dts-rockchip-rk3588-npu-enablements-v1-1-d38b182a59e3@pardini.net>
References: <20251230-arm64-dts-rockchip-rk3588-npu-enablements-v1-0-d38b182a59e3@pardini.net>
In-Reply-To: <20251230-arm64-dts-rockchip-rk3588-npu-enablements-v1-0-d38b182a59e3@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1346; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=+QiHWgqrqCvAOEg9ZYrtyyD9Tb3C3HqtujZ2zGhDDrA=;
 b=owEBbQGS/pANAwAIATteP+Oex+3pAcsmYgBpVDPYgaaZKkBzk5d1Kj1a5IICn5fE5aQRqf38z
 EgnUptOBG2JATMEAAEIAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCaVQz2AAKCRA7Xj/jnsft
 6SqoB/9N+rz+MEY6VoUs2Bu5JmiCmkTLSYSQ1vx7/Z7MNRq5hPaQFpYyJS21PQaubUXdeiqK8wy
 rmCwpXRMgyRZqOzJCMtzi1ujM8LgE1dJpYA2qriq+joLRWMYjVSNJeuA2XM6YJbwohD9eyge3X2
 waBMxjEBtXGOfwqco+U/KHT25sj2m+oTmXzZy6XR70XRsKyVZ55u2KnXYxaw97d598fkRAb3VaM
 tsqvrrYm8+ntXs+UxH3i9Q4NWrjbkTy1b9FJZttfwr8Q3sVikDw0Gl+EMBO3S/Ut1dVfmCzwFZk
 IfUp7KGg3dK6B+B8BspLcwNgYF29fKccdRuvhpdyAh6tnQRR
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the NPU on FriendlyElec NanoPC T6/T6-LTS boards.
The regulator vdd_npu_s0 was already described.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi | 35 ++++++++++++++++++++++
 1 file changed, 35 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
index fafeabe9adf9e..93bd479118e92 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi
@@ -629,6 +629,10 @@ &pd_gpu {
 	domain-supply = <&vdd_gpu_s0>;
 };
 
+&pd_npu {
+	domain-supply = <&vdd_npu_s0>;
+};
+
 &pinctrl {
 	gpio-leds {
 		sys_led_pin: sys-led-pin {
@@ -706,6 +710,37 @@ &pwm1 {
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

