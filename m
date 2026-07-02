From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Fri, 03 Jul 2026 00:07:23 +0200
Subject: [PATCH 08/12] arm64: dts: rockchip: rk3588s-nanopi: remove
 always-on from vdd_npu_s0 reg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260703-nanopi-m6-v1-8-8344a1559519@gmail.com>
References: <20260703-nanopi-m6-v1-0-8344a1559519@gmail.com>
In-Reply-To: <20260703-nanopi-m6-v1-0-8344a1559519@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783030102; l=747;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=xYuB/QxuBX7PA9bPdFQENsiRAGCOhRcwISiBdc/4PZo=;
 b=XXX6wpdDlGpIjN86dtfOJlnfD2E00S9bclySieflzzF9RhrlyPTGIg1J+Zh5MKBA1fCfbz4O3
 UstTJAAHtD/AF8uaxvYHaGabcPHyQnLw3J2NdrBr7KzZTZxpSSBbalO
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the NPU is hooked up on these the always-on isn't needed anymore.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
index bcb2f5d63a61..463cfeddf270 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
@@ -258,7 +258,6 @@ vdd_npu_s0: regulator@42 {
 		regulator-max-microvolt = <950000>;
 		regulator-ramp-delay = <2300>;
 		regulator-boot-on;
-		regulator-always-on;
 		vin-supply = <&vcc5v0_sys>;
 
 		regulator-state-mem {

-- 
2.55.0

