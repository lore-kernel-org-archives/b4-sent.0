From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Mon, 11 May 2026 18:33:53 +0700
Subject: [PATCH v2 1/3] dt-bindings: arm: qcom: document the Ayaneo Pocket
 DS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-pocketds-v2-1-299dd4247f2f@gmail.com>
References: <20260511-pocketds-v2-0-299dd4247f2f@gmail.com>
In-Reply-To: <20260511-pocketds-v2-0-299dd4247f2f@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>, 
 Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778499232; l=948;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=vJKMcLbHKxPCtNvUiI9RU+V6jt5nuzR57sFHWslUAcM=;
 b=eyabf+FqWEY4fIcbgyb81COzhMQj42tjevu021QfqqWKwMlk0M5ri9Uft7b7EFohoNUsJIQID
 UcVjWbHCzQCDmma7oi4k4bNXaBIu3e+IoLzTITb6zQoT/pFbtCiVIA0
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Teguh Sobirin <teguh@sobir.in>

Document the Qualcomm QCS8550 based Ayaneo Pocket DS gaming console.

Co-developed-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
Signed-off-by: Teguh Sobirin <teguh@sobir.in>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 2741c07e9f41..f130a6b092b9 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1107,6 +1107,12 @@ properties:
           - const: qcom,qcs8550
           - const: qcom,sm8550
 
+      - items:
+          - enum:
+              - ayaneo,pocketds
+          - const: qcom,qcs8550
+          - const: qcom,sm8550
+
       - items:
           - enum:
               - ayaneo,pocket-s2

-- 
2.54.0

