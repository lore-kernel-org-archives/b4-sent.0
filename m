From: George Moussalem <george.moussalem@outlook.com>
Date: Thu, 01 May 2025 13:20:51 +0400
Subject: [PATCH 1/2] dt-bindings: spi: spi-qpic-snand: Add IPQ5018
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250501-ipq5018-spi-qpic-snand-v1-1-31e01fbb606f@outlook.com>
References: <20250501-ipq5018-spi-qpic-snand-v1-0-31e01fbb606f@outlook.com>
In-Reply-To: <20250501-ipq5018-spi-qpic-snand-v1-0-31e01fbb606f@outlook.com>
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, sadre Alam <quic_mdalam@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746091263; l=1065;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=Vn57KyOsNu/ySFd+C3/QjJQvANGt6ZH80rH1wCZ1tT8=;
 b=3RrQmearoVavPvbKtCI1KwwwSX1OTyhq6rOVklLPGZFGFKhyVqAfnJoUZCOids4dHNnILQ1AZ
 2W6MX43xx7PAi+38BpFmh99VvSWL/OLtdiAl9MDE8yRrH95LgCMBm/q
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IPQ5018 contains the QPIC-SPI-NAND flash controller which is the same as
the one found in IPQ9574. So let's document the IPQ5018 compatible and
use IPQ9574 as the fallback.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 Documentation/devicetree/bindings/spi/qcom,spi-qpic-snand.yaml | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/spi/qcom,spi-qpic-snand.yaml b/Documentation/devicetree/bindings/spi/qcom,spi-qpic-snand.yaml
index aa3f933192034fe6d54d6149373d50c31ec4aa96..cb1f15224b45574a3c3d603566c859a9bec41937 100644
--- a/Documentation/devicetree/bindings/spi/qcom,spi-qpic-snand.yaml
+++ b/Documentation/devicetree/bindings/spi/qcom,spi-qpic-snand.yaml
@@ -21,8 +21,12 @@ allOf:
 
 properties:
   compatible:
-    enum:
-      - qcom,ipq9574-snand
+    oneOf:
+      - items:
+          - enum:
+              - qcom,ipq5018-snand
+          - const: qcom,ipq9574-snand
+      - const: qcom,ipq9574-snand
 
   reg:
     maxItems: 1

-- 
2.49.0

