From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Mon, 29 Aug 2022 13:49:18 -0400
Subject: [PATCH v3 2/4] arm64: dts: allwinner: h6: Add cooling map for GPU
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
Message-Id: <20220825-test-endpoint-send-2-v3-2-e29bfe9731e0@linuxfoundation.org>
References: <20220825-test-endpoint-send-2-v3-0-e29bfe9731e0@linuxfoundation.org>
In-Reply-To: <20220825-test-endpoint-send-2-v3-0-e29bfe9731e0@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-65ba7
X-Developer-Signature: v=1; a=openpgp-sha256; l=1268;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=8EeB0wWMntMKiDLhAaZ+QQ6lyux+ywxl6EQgii2JRlw=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJJ5/iifblB3cGaLutqz+YD6erNY643vO3cXPzj0b21o+JuC
 VbW5HaUsDGJcDLJiiixl+2I3BRU+9JBL7zGFmcPKBDKEgYtTACaSc4qR4U1f2mKHpbOaGg+UNljznT
 n7p+6084QzYa99OHa0pOrEH2ZkOGL4O7LXxWnV9SNnIzlufU28/XLrrgCuvxtv3nvkfs3wLisA
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
b4 0.10.0-dev-65ba7
