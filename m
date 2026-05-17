From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Sun, 17 May 2026 20:14:20 +0700
Subject: [PATCH v3 1/4] dt-bindings: arm: qcom: document the Ayaneo Pocket
 DS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260517-pocketds-v3-1-d5910c801756@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779023659; l=835;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=NYdtjmtd1UJX19KWh8T30Z3zmyp1DHDS/k4hVHOJ4EM=;
 b=HVWy1Z93IjkHW0ng0OVfPSA+tvmakwuLPZzEwYM9olKU/Q2c2Dld8t+j5acpltu8BEmQGESiR
 HVVP02gcfNcCBQxJPD7NPqfPCQyRXrP0vvlMQP69UEWcf9tqCYo0VyA
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Qualcomm QCS8550 based Ayaneo Pocket DS gaming console.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
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

