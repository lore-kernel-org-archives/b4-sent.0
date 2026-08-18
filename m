From: Aiden Isik <aidenisik@member.fsf.org>
Date: Tue, 18 Aug 2026 19:03:17 +0100
Subject: [PATCH v3 1/2] dt-bindings: watchdog: samsung-wdt: Add
 exynos5515-wdt compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260818-for-next-lucky7-watchdog-v3-1-2912bd122c57@member.fsf.org>
References: <20260818-for-next-lucky7-watchdog-v3-0-2912bd122c57@member.fsf.org>
In-Reply-To: <20260818-for-next-lucky7-watchdog-v3-0-2912bd122c57@member.fsf.org>
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
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqhJ5q6l1KKMnV2P6Cn1UsoP5ufTSgNjAGWZlvj
 kdMw6exdGqJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoSeagAKCRBJJwGyxHrX
 6z0vD/4siUbFB5yUoK3t5gXuJmAWUELGYDCgBLixa04YZ3IswaQCav8Q+HRyPs+OZgKo0jDWkhn
 cv2lz1y4w0m5sPwMHoAYEINCli+6HtswcLh0+BrYG313/EiVEG1p0bgxoyAjr8a38/rjqwxoxBn
 p1zZtKVJdmo65fcyKiNP+Dx3cAccWVAnrGC+dosL+J44yZbCeH4HJEZ/i9jEnHz2Pq6eayKrYcj
 HShAsP9V5Fscoszpq4UmH4MncD7o08zQzWdVjPHqZYkEPGtDiL7xlJWBDVbST13cyNZIld1JF2i
 tBviRwVewVTmCV0fXTlxAn2lxqqSCXqHRrP5emJExFgfZzYOWTNPTA2+AMEp40wOZsPQlZH2zqj
 TcJ1NWL6jLsczyorAA093zt4iNVvo1u6idPASS/9fDXnKbypp+gNlqm35SnebCr8Q35rNWBn/uX
 48g6kIT9y5bIvLWKZofF/ClgtITvpLFSTgAwvmTebmGXDRkjG5P/3F/xAXNa2tthr+QIwCFGi7W
 b3E1RCD/wONwoQG+oe66tDtGfqt1hLRqMOLGwquUldPR54B3P1GrO9YqNJy+gwGFJuzDSR8t1sx
 obx7dI11j+uuHYk6PXq+gz4TNpp+5DNEGyaLvRA5jELVymtFStiJUNinOtoUjWi4bJS94JM0MiY
 Evvy7h8v1B46gKA==
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

