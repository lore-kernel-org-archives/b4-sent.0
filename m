From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Wed, 07 Sep 2022 09:40:47 -0400
Subject: [PATCH v9 2/4] arm64: dts: allwinner: h6: Add cooling map for GPU
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
Message-Id: <20220825-test-endpoint-send-2-v9-2-b88029795c86@linuxfoundation.org>
References: <20220825-test-endpoint-send-2-v9-0-b88029795c86@linuxfoundation.org>
In-Reply-To: <20220825-test-endpoint-send-2-v9-0-b88029795c86@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-1911d
X-Developer-Signature: v=1; a=openpgp-sha256; l=1268;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=sTGpQAEcq+ghGOzIXFPABJJJdl/k3AN65aHFKY1ZW70=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIl5iccefhMVNP7xQTXv92PdE5fE2j5nX/s+M/TGu1dPq3K
 rBdLOkpZGMS4GGTFFFnK9sVuCip86CGX3mMKM4eVCWQIAxenAEzk3RdGhsUJScf8eYofXUlgCP0p/n
 VZh5qj0JkNgXln/wh0Ht4dd4zhf9KDwtAT5+dua82btpP18i7ubJdty/U7l9ftWB5tWbVOjhcA
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

From: Clément Péron <peron.clem@gmail.com>

Add a simple cooling map for the GPU.

Signed-off-by: Clément Péron <peron.clem@gmail.com>
Acked-by: Samuel Holland <samuel@sholland.org>
Signed-off-by: Konstantin Ryabitsev <konstantin@linuxfoundation.org>

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h6.dtsi b/arch/arm64/boot/dts/allwinner/sun50i-h6.dtsi
index 5a28303d3d4c..943ae5374dd6 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h6.dtsi
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h6.dtsi
@@ -186,6 +186,7 @@ gpu: gpu@1800000 {
 			clocks = <&ccu CLK_GPU>, <&ccu CLK_BUS_GPU>;
 			clock-names = "core", "bus";
 			resets = <&ccu RST_BUS_GPU>;
+			#cooling-cells = <2>;
 			status = "disabled";
 		};
 
@@ -1075,6 +1076,27 @@ gpu-thermal {
 			polling-delay-passive = <0>;
 			polling-delay = <0>;
 			thermal-sensors = <&ths 1>;
+
+			trips {
+				gpu_alert: gpu-alert {
+					temperature = <85000>;
+					hysteresis = <2000>;
+					type = "passive";
+				};
+
+				gpu-crit {
+					temperature = <100000>;
+					hysteresis = <0>;
+					type = "critical";
+				};
+			};
+
+			cooling-maps {
+				map0 {
+					trip = <&gpu_alert>;
+					cooling-device = <&gpu THERMAL_NO_LIMIT THERMAL_NO_LIMIT>;
+				};
+			};
 		};
 	};
 };

-- 
b4 0.10.0-dev-1911d
