From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 19 Feb 2026 22:07:39 -0600
Subject: [PATCH v3 1/2] dt-bindings: interconnect: OSM L3: Document sm8550
 OSM L3 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260219-sm8550-ddr-bw-scaling-v3-1-75c19152e921@gmail.com>
References: <20260219-sm8550-ddr-bw-scaling-v3-0-75c19152e921@gmail.com>
In-Reply-To: <20260219-sm8550-ddr-bw-scaling-v3-0-75c19152e921@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Georgi Djakov <djakov@kernel.org>, 
 Sibi Sankar <sibi.sankar@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771560469; l=967;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=mS8M/OvCSyCfH2FPOESQBHGwPnDgZXk2BMAopHCtTqQ=;
 b=RhWnrH18WLVa+J8yF9CdvqHnkwgxX4ZUsl8GrEPH5ECxH908m89IrCg+QGufUTt/UyK7BWVOf
 gEhMmRW8XdSACIp3jeAnszkaEjQBHpqpJdYDscokC0e84Byj2Amyir2
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the OSM L3 found in the Qualcomm SM8550 platform.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/interconnect/qcom,osm-l3.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/interconnect/qcom,osm-l3.yaml b/Documentation/devicetree/bindings/interconnect/qcom,osm-l3.yaml
index 4b9b98fbe8f22258c209e8337bb4517e5f5888e8..3cbe2c3701f77d5d70082092043f2b2ccbd64905 100644
--- a/Documentation/devicetree/bindings/interconnect/qcom,osm-l3.yaml
+++ b/Documentation/devicetree/bindings/interconnect/qcom,osm-l3.yaml
@@ -34,6 +34,7 @@ properties:
               - qcom,sm6375-cpucp-l3
               - qcom,sm8250-epss-l3
               - qcom,sm8350-epss-l3
+              - qcom,sm8550-epss-l3
               - qcom,sm8650-epss-l3
           - const: qcom,epss-l3
       - items:

-- 
2.52.0

