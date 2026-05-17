From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Sun, 17 May 2026 20:14:21 +0700
Subject: [PATCH v3 2/4] arm64: dts: qcom: sm8550: add labels for thermal
 zones
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260517-pocketds-v3-2-d5910c801756@gmail.com>
References: <20260517-pocketds-v3-0-d5910c801756@gmail.com>
In-Reply-To: <20260517-pocketds-v3-0-d5910c801756@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779023659; l=3018;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=CXTAgnet4ppJsOM7v8NkuaJ4ZX4sBruKC6TxmpiZmV8=;
 b=NsRfos64bslkmHERiEcrL2qI3n4M3NDysI9tqF7HNYPOlfVqpx54/3Orbw+Ftm9uA6/m46Fy7
 hpcvZVJ/TjbBsXZjPIPjn+4lhOQ9I4QJH74kfrP0UDMmTvGAsuQ3kmv
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add labels for the cpuss, cpu and gpuss thermal zones so board files
can extend them with trip points and cooling maps through the &label
override syntax, instead of redeclaring the zones by path.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
 arch/arm64/boot/dts/qcom/sm8550.dtsi | 26 +++++++++++++-------------
 1 file changed, 13 insertions(+), 13 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index 912525e9bca6..a9c678fc9cb2 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -5764,7 +5764,7 @@ reset-mon-config {
 			};
 		};
 
-		cpuss0-thermal {
+		cpuss0_thermal: cpuss0-thermal {
 			thermal-sensors = <&tsens0 1>;
 
 			trips {
@@ -5782,7 +5782,7 @@ reset-mon-config {
 			};
 		};
 
-		cpuss1-thermal {
+		cpuss1_thermal: cpuss1-thermal {
 			thermal-sensors = <&tsens0 2>;
 
 			trips {
@@ -5800,7 +5800,7 @@ reset-mon-config {
 			};
 		};
 
-		cpuss2-thermal {
+		cpuss2_thermal: cpuss2-thermal {
 			thermal-sensors = <&tsens0 3>;
 
 			trips {
@@ -5818,7 +5818,7 @@ reset-mon-config {
 			};
 		};
 
-		cpuss3-thermal {
+		cpuss3_thermal: cpuss3-thermal {
 			thermal-sensors = <&tsens0 4>;
 
 			trips {
@@ -6028,7 +6028,7 @@ cpu6_bottom_crit: cpu-critical {
 			};
 		};
 
-		cpu7-top-thermal {
+		cpu7_top_thermal: cpu7-top-thermal {
 			thermal-sensors = <&tsens0 13>;
 
 			trips {
@@ -6536,7 +6536,7 @@ reset-mon-config {
 			};
 		};
 
-		gpuss-0-thermal {
+		gpuss0_thermal: gpuss-0-thermal {
 			polling-delay-passive = <10>;
 
 			thermal-sensors = <&tsens2 1>;
@@ -6569,7 +6569,7 @@ trip-point2 {
 			};
 		};
 
-		gpuss-1-thermal {
+		gpuss1_thermal: gpuss-1-thermal {
 			polling-delay-passive = <10>;
 
 			thermal-sensors = <&tsens2 2>;
@@ -6602,7 +6602,7 @@ trip-point2 {
 			};
 		};
 
-		gpuss-2-thermal {
+		gpuss2_thermal: gpuss-2-thermal {
 			polling-delay-passive = <10>;
 
 			thermal-sensors = <&tsens2 3>;
@@ -6635,7 +6635,7 @@ trip-point2 {
 			};
 		};
 
-		gpuss-3-thermal {
+		gpuss3_thermal: gpuss-3-thermal {
 			polling-delay-passive = <10>;
 
 			thermal-sensors = <&tsens2 4>;
@@ -6668,7 +6668,7 @@ trip-point2 {
 			};
 		};
 
-		gpuss-4-thermal {
+		gpuss4_thermal: gpuss-4-thermal {
 			polling-delay-passive = <10>;
 
 			thermal-sensors = <&tsens2 5>;
@@ -6701,7 +6701,7 @@ trip-point2 {
 			};
 		};
 
-		gpuss-5-thermal {
+		gpuss5_thermal: gpuss-5-thermal {
 			polling-delay-passive = <10>;
 
 			thermal-sensors = <&tsens2 6>;
@@ -6734,7 +6734,7 @@ trip-point2 {
 			};
 		};
 
-		gpuss-6-thermal {
+		gpuss6_thermal: gpuss-6-thermal {
 			polling-delay-passive = <10>;
 
 			thermal-sensors = <&tsens2 7>;
@@ -6767,7 +6767,7 @@ trip-point2 {
 			};
 		};
 
-		gpuss-7-thermal {
+		gpuss7_thermal: gpuss-7-thermal {
 			polling-delay-passive = <10>;
 
 			thermal-sensors = <&tsens2 8>;

-- 
2.54.0

