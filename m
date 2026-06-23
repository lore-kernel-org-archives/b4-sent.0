From: Esteban Urrutia <esteuwu@proton.me>
Date: Mon, 22 Jun 2026 20:54:24 -0400
Subject: [PATCH 3/8] arm64: dts: qcom: sm8450: Modify GPU operating points
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260622-sm8450-qol-v1-3-37e2ee8df9da@proton.me>
References: <20260622-sm8450-qol-v1-0-37e2ee8df9da@proton.me>
In-Reply-To: <20260622-sm8450-qol-v1-0-37e2ee8df9da@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, "Joerg Roedel (AMD)" <joro@8bytes.org>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 iommu@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-phy@lists.infradead.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782176157; l=1067;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=UC8G+Beo5Ny4qD1bWQkjh6S3TFmJKL1P3wTRFImBETw=;
 b=V0HqhO1u+vHE2WkQyZ8w53tz9nq5vyJwjoEMcNSnSh9lQeJePF45vUwQO1oEV5l9C03S56ym5
 yuN/x2btOijA7GTkYxTOpmiR7wyBg3PEFIHlzEQG2lD3ssBubBG0T7a
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These frecuencies don't exist in downstream device trees.
Both 220MHz and 285MHz belong to SM8475, and I'm not sure where 317MHz
came from.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 arch/arm64/boot/dts/qcom/sm8450.dtsi | 15 ---------------
 1 file changed, 15 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8450.dtsi b/arch/arm64/boot/dts/qcom/sm8450.dtsi
index e34e3c05bf74..5e331a25e22a 100644
--- a/arch/arm64/boot/dts/qcom/sm8450.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8450.dtsi
@@ -2495,21 +2495,6 @@ opp-350000000 {
 					opp-hz = /bits/ 64 <350000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS>;
 				};
-
-				opp-317000000 {
-					opp-hz = /bits/ 64 <317000000>;
-					opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS>;
-				};
-
-				opp-285000000 {
-					opp-hz = /bits/ 64 <285000000>;
-					opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS_D1>;
-				};
-
-				opp-220000000 {
-					opp-hz = /bits/ 64 <220000000>;
-					opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS_D1>;
-				};
 			};
 		};
 

-- 
2.54.0

