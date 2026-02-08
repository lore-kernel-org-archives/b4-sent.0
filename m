From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 07 Feb 2026 19:20:00 -0600
Subject: [PATCH] arm64: dts: qcom: sm8550: Add ACD levels for GPU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260207-sm8550-acd-v1-1-53d084c58c9a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDIwNz3eJcC1NTA93E5BTd5NTkVAOjlOTkRJM0JaCGgqLUtMwKsGHRsbW
 1AI38bt5cAAAA
X-Change-ID: 20260207-sm8550-acd-cece02dcca4f
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770513603; l=2274;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=AJWp2fE4/yWQrzLUddHgO6gfebb585G1GONPy/muLhw=;
 b=pO6qzyloSIhZrE7L7BZ09kPG4mxeTZ5xyeRrGPKeKHyyVsiObP/yrrKnbhyyKs7nj3mRqER8/
 jlxmhd5ev69CYzQc9Csl1K8pyzBFHkL5ULH+FHkHIaieqCH4646GUb7
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update GPU node to include acd level values.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/qcom/sm8550.dtsi | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index e3f93f4f412ded9583a6bc9215185a0daf5f1b57..277dd7c4ad6ed7ef1b5370f34abe350d82b14b17 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -2503,48 +2503,56 @@ opp-680000000 {
 					opp-hz = /bits/ 64 <680000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_SVS_L1>;
 					opp-peak-kBps = <16500000>;
+					qcom,opp-acd-level = <0x882e5ffd>;
 				};
 
 				opp-615000000 {
 					opp-hz = /bits/ 64 <615000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_SVS_L0>;
 					opp-peak-kBps = <12449218>;
+					qcom,opp-acd-level = <0xa82f5ffd>;
 				};
 
 				opp-550000000 {
 					opp-hz = /bits/ 64 <550000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_SVS>;
 					opp-peak-kBps = <10687500>;
+					qcom,opp-acd-level = <0xe0285ffd>;
 				};
 
 				opp-475000000 {
 					opp-hz = /bits/ 64 <475000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS_L1>;
 					opp-peak-kBps = <6074218>;
+					qcom,opp-acd-level = <0xe0285ffd>;
 				};
 
 				opp-401000000 {
 					opp-hz = /bits/ 64 <401000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS>;
 					opp-peak-kBps = <6074218>;
+					qcom,opp-acd-level = <0xc02a5ffd>;
 				};
 
 				opp-348000000 {
 					opp-hz = /bits/ 64 <348000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS_D0>;
 					opp-peak-kBps = <6074218>;
+					qcom,opp-acd-level = <0xe02b5ffd>;
 				};
 
 				opp-295000000 {
 					opp-hz = /bits/ 64 <295000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS_D1>;
 					opp-peak-kBps = <6074218>;
+					qcom,opp-acd-level = <0xe02d5ffd>;
 				};
 
 				opp-220000000 {
 					opp-hz = /bits/ 64 <220000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS_D2>;
 					opp-peak-kBps = <2136718>;
+					qcom,opp-acd-level = <0xc02f5ffd>;
 				};
 			};
 		};

---
base-commit: 9845cf73f7db6094c0d8419d6adb848028f4a921
change-id: 20260207-sm8550-acd-cece02dcca4f

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

