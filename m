From: Antony Kurniawan Soemardi <linux@smankusors.com>
Date: Tue, 14 Apr 2026 01:55:28 +0700
Subject: [PATCH 01/10] dt-bindings: clock: qcom,rpmcc: add msm8960
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260414-msm8960-wifi-v1-1-007fda9d6134@smankusors.com>
References: <20260414-msm8960-wifi-v1-0-007fda9d6134@smankusors.com>
In-Reply-To: <20260414-msm8960-wifi-v1-0-007fda9d6134@smankusors.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Lee Jones <lee@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776106820; l=1260;
 i=linux@smankusors.com; s=20250609; h=from:subject:message-id;
 bh=1wSMQ0upQbQ8gZkIBGj7bAHKHl2mdsM0ZEnITpOYnso=;
 b=Lttd5AAQmW6e4FfATiHZkrW9wh903AbL1msUWYN3jhbdqqhuztWBQlat9hUVnErBV0vKLlp+z
 mi+xXdoESUZD+kXuOwlwNCpNNqtohCM48zRqnvhDcOn4RWtaFYn4iOS
X-Developer-Key: i=linux@smankusors.com; a=ed25519;
 pk=65wTy06fJl2/h/EJwjr704YG+yjHFhZObJBWzzK+N00=
X-Endpoint-Received: by B4 Relay for linux@smankusors.com/20250609 with auth_id=733
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the qcom,rpmcc-msm8960 compatible.

The MSM8960 platform shares the same RPM clock definitions as
APQ8064, so extend the existing conditional schema to treat
qcom,rpmcc-msm8960 the same as qcom,rpmcc-apq8064.

Signed-off-by: Antony Kurniawan Soemardi <linux@smankusors.com>
---
 Documentation/devicetree/bindings/clock/qcom,rpmcc.yaml | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/clock/qcom,rpmcc.yaml b/Documentation/devicetree/bindings/clock/qcom,rpmcc.yaml
index ab97d4b7dba8..f84d08199e47 100644
--- a/Documentation/devicetree/bindings/clock/qcom,rpmcc.yaml
+++ b/Documentation/devicetree/bindings/clock/qcom,rpmcc.yaml
@@ -36,6 +36,7 @@ properties:
           - qcom,rpmcc-msm8937
           - qcom,rpmcc-msm8940
           - qcom,rpmcc-msm8953
+          - qcom,rpmcc-msm8960
           - qcom,rpmcc-msm8974
           - qcom,rpmcc-msm8976
           - qcom,rpmcc-msm8992
@@ -90,7 +91,9 @@ allOf:
       properties:
         compatible:
           contains:
-            const: qcom,rpmcc-apq8064
+            enum:
+              - qcom,rpmcc-apq8064
+              - qcom,rpmcc-msm8960
     then:
       properties:
         clocks:

-- 
2.34.1

