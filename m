From: Aiden Isik <aidenisik@member.fsf.org>
Date: Fri, 21 Aug 2026 16:14:49 +0100
Subject: [PATCH v4 1/2] dt-bindings: watchdog: samsung-wdt: Add
 exynos5515-wdt compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-for-next-lucky7-watchdog-v4-1-d070cee5009f@member.fsf.org>
References: <20260821-for-next-lucky7-watchdog-v4-0-d070cee5009f@member.fsf.org>
In-Reply-To: <20260821-for-next-lucky7-watchdog-v4-0-d070cee5009f@member.fsf.org>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-watchdog@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2313;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=FomCRWunoZv/FcOKS7xgccqo7tYm7xEPkwn4AZZPbfA=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqiGt3Q8tb/3X2CNP+j2XwOC3vSWGkk8rvEPwIY
 vrBosRFilGJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaohrdwAKCRBJJwGyxHrX
 6xynD/95Qv0k65rFNjCS+jgOWHLGqO6p52BTj0Go3on1RpJydts29MLNi6SZ8GZlB6yoowT8iz7
 s2aEYRE7xN5fzBnZ7WasfMF020wcFisNZt07Y5pW02TdICOhv//UzfT2Lji4TDjVdhKSBHeQpd9
 2ZjlTKWevZ4RO/akI+3m+PSfek9jVdwgK91wt4jVjq0Vb/VdWqgNikhH5ZJ6OHewN0U90hg+/52
 kTvMBnqLPftY9onmQ3ufLwlUM9HuRkjDEJdpw1CBQbepUx2n24tdkhjBgwOzR1AddcHrUrejWG1
 7JNlVTi6CJLFl15SYInCVQvcypN+X0Ap1SMi9bfNAcrfNNwihrvWOQsmKEyJm9Ha+CopvzoCjzy
 X2d5Nydt2bOdtRsMPPONUy2oKX8peTSimt279ACB7+pyFjWBdqx/4mNtoZwtm5pkKMb9XK2ZTLp
 85Zy1V6/udnbo/E6aZjxHlUDd9UdIoaiONm9ihEr/YhJZDdKke5UbYPoIeHLphbgCnmd5GlZtNS
 ljwjUFyVoWmkVmyQr+rnc2q2PBJd1JA9BZALIgpUvdxexZ74G8LxCTd4HcCJKuQmNzMENKUexkQ
 e+AoVeL2Br1tAFSJjE+AHTZ+JzM8UcqORDzonNPiCbYo3ZVuGAl2w8Q21xHddjwLIUJOPoMu0Wq
 5FbcEpSuR3fr64Q==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a dt-binding compatible for the Exynos5515 watchdog timer.

This watchdog requires a syscon phandle, and the cluster index should
*not* be specified, as that does not make sense on the Exynos5515 SoC
(due to it only having a single core cluster).

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 .../devicetree/bindings/watchdog/samsung-wdt.yaml  | 23 +++++++++++++++++++++-
 1 file changed, 22 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/watchdog/samsung-wdt.yaml b/Documentation/devicetree/bindings/watchdog/samsung-wdt.yaml
index 41aee1655b0c..a32c47831577 100644
--- a/Documentation/devicetree/bindings/watchdog/samsung-wdt.yaml
+++ b/Documentation/devicetree/bindings/watchdog/samsung-wdt.yaml
@@ -22,6 +22,7 @@ properties:
           - samsung,s3c6410-wdt                   # for S3C6410, S5PV210 and Exynos4
           - samsung,exynos5250-wdt                # for Exynos5250
           - samsung,exynos5420-wdt                # for Exynos5420
+          - samsung,exynos5515-wdt
           - samsung,exynos7-wdt                   # for Exynos7
           - samsung,exynos850-wdt                 # for Exynos850
           - samsung,exynos990-wdt                 # for Exynos990
@@ -57,7 +58,7 @@ properties:
     $ref: /schemas/types.yaml#/definitions/phandle
     description:
       Phandle to the PMU system controller node (in case of Exynos5250,
-      Exynos5420, Exynos7, Exynos850, Exynos990 and gs101).
+      Exynos5420, Exynos5515, Exynos7, Exynos850, Exynos990 and gs101).
 
 required:
   - compatible
@@ -93,6 +94,26 @@ allOf:
         - samsung,cluster-index
         - samsung,syscon-phandle
 
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - samsung,exynos5515-wdt
+    then:
+      properties:
+        clocks:
+          items:
+            - description: Bus clock, used for register interface
+            - description: Source clock (driving watchdog counter)
+        clock-names:
+          items:
+            - const: watchdog
+            - const: watchdog_src
+        samsung,cluster-index: false
+      required:
+        - samsung,syscon-phandle
+
   - if:
       properties:
         compatible:

-- 
2.54.0

