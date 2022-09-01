From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Thu, 01 Sep 2022 10:31:31 -0400
Subject: [PATCH RESEND v7 2/4] arm64: dts: allwinner: h6: Add cooling map for GPU
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
Message-Id: <20220825-test-endpoint-send-2-v7-2-821f03d2f76c@linuxfoundation.org>
References: <20220825-test-endpoint-send-2-v7-0-821f03d2f76c@linuxfoundation.org>
In-Reply-To: <20220825-test-endpoint-send-2-v7-0-821f03d2f76c@linuxfoundation.org>
To: mricon@kernel.org
X-Mailer: b4 0.10.0-dev-b62e0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1268;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=N6BMCPPt40hZgLU8mRNFqaWA6VfJGiCgEstBAYxPMkA=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIFDjlpvq9Z8+PkKZ9PJ8O3Ms0K3soU+SLwsNy+RZ03Wadv
 vm6/s6OUhUGMi0FWTJGlbF/spqDChx5y6T2mMHNYmUCGMHBxCsBE2J0ZGebca5wsse/EPvWbQTMzi2
 4997KaHLnkcOkO9S0zzk5/e7GFkeGg/gPz2JUfS/UWLn8oNe3wu3m8h/PbJrMLN+Usmnf6uwkjAA==
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
b4 0.10.0-dev-b62e0
