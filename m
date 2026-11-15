From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 16 Nov 2026 01:49:27 +0530
Subject: [PATCH 1/2] dt-bindings: clock: qcom: sm8450-gpucc: Add Molokai
 GPU clock controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-molokai-gpucc-v1-1-07cb3bf37c78@yahoo.com>
References: <20261116-molokai-gpucc-v1-0-07cb3bf37c78@yahoo.com>
In-Reply-To: <20261116-molokai-gpucc-v1-0-07cb3bf37c78@yahoo.com>
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Taniya Das <taniya.das@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794773966; l=1014;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=e0GmbRVbOneNgtdi0twGJ0KyCrMgnbqGUTQplz7+HHk=;
 b=KeSbHUuS2dURMP2SyRTWeJtBpjccQkUq2fxIYif0kcWMqbjW6DNhetYxb7Nw16hXVcG6n0CAf
 1BEDGnfvLBQAAQOm3gweBZOHEtB2xyRBn0j6PqxxbmJSnMkcgFN0014
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the graphics clock controller of the Qualcomm Molokai (SM8845)
SoC. It is the Kaanapali one with a different PLL configuration and three
branch clocks at different offsets, so it is not compatible with it.

An LLM was used to help write this commit message.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 Documentation/devicetree/bindings/clock/qcom,sm8450-gpucc.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/clock/qcom,sm8450-gpucc.yaml b/Documentation/devicetree/bindings/clock/qcom,sm8450-gpucc.yaml
index 7eca456211e4..e62e6127b06f 100644
--- a/Documentation/devicetree/bindings/clock/qcom,sm8450-gpucc.yaml
+++ b/Documentation/devicetree/bindings/clock/qcom,sm8450-gpucc.yaml
@@ -37,6 +37,7 @@ properties:
       - qcom,glymur-gpucc
       - qcom,kaanapali-gpucc
       - qcom,milos-gpucc
+      - qcom,molokai-gpucc
       - qcom,nord-gpu2cc
       - qcom,nord-gpucc
       - qcom,sar2130p-gpucc

-- 
2.56.0

