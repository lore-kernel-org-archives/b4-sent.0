From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 18 Feb 2026 12:16:18 -0600
Subject: [PATCH v2 1/3] dt-bindings: interconnect: OSM L3: Document sm8550
 OSM L3 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260218-sm8550-ddr-bw-scaling-v2-1-43a2b6d47e70@gmail.com>
References: <20260218-sm8550-ddr-bw-scaling-v2-0-43a2b6d47e70@gmail.com>
In-Reply-To: <20260218-sm8550-ddr-bw-scaling-v2-0-43a2b6d47e70@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Georgi Djakov <djakov@kernel.org>, 
 Sibi Sankar <sibi.sankar@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771438580; l=897;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=QL4QtlV1mkUECwvUyM6TwRVGqKLGQYeQGpH9Y7qGjM4=;
 b=MPZfDr/vlSXG8c8OTZEeBIXBCkRI2FikGcYjpKZttCkgoRZKuTJvHcMR3TxO6VYE541zP1+Sf
 1WvZfT1x9X8BYvMHwqTXPxTKA87bD1fieyQE4o0JFog/aEpNqvd2kPK
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the OSM L3 found in the Qualcomm SM8550 platform.

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

