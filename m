From: Aiden Isik <aidenisik@member.fsf.org>
Date: Mon, 17 Aug 2026 11:22:52 +0100
Subject: [PATCH 1/2] dt-bindings: watchdog: samsung-wdt: Add exynos5515-wdt
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260817-for-next-lucky7-watchdog-v1-1-a14370e20b92@member.fsf.org>
References: <20260817-for-next-lucky7-watchdog-v1-0-a14370e20b92@member.fsf.org>
In-Reply-To: <20260817-for-next-lucky7-watchdog-v1-0-a14370e20b92@member.fsf.org>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-watchdog@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 Aiden Isik <aidenisik+git@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2310;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=qmqcVgcTJyX2r6r452NiYreHT9JlZHTUJh1Zj91t7tY=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqguEVSqyad5mbh50KvxR6h8JL+fob6cbZzG81r
 m3KGiLBUjmJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoLhFQAKCRBJJwGyxHrX
 6yeID/9+fPUN80oI5yjbiuhjOdxKIKr4czeAw0blx24qTHegF/0nCcc5T4C12+GI6/S0WjoFqV2
 eU7LOT0M1b0b/zvgI5D0juUW0VQMjVHY5UKB+mP+pdsoAZhmzVYyF+UcwMZ5k8Ji3MoXH1W/iru
 cJYyzK3GnZJYtmJ12NweWOB44jEDagQzD/eRXJGO4wB08hQ8eZfeJyzQIS1Tj46S0HHyY/PGglJ
 jM35iy+sXfzj++Vzcg0alfj9zHhGe2gK3TkJhEjvFFZgTfishoanivImmJlbW67q+18pSHlcly2
 MxcW9gFSkpyKCOjW2WDr/qUyaoAT6j5Mrupe04JGxzDVT6jUow0iTnE0Vwz5L6p4Vc91ctJrJUI
 s16RB55tXadgxpguAjvlF8uXHaOJGlnp/XcgAdygrNuLZpWoy8Rf1YRqETJzluqsQuLTB6GmRwm
 GxEtIASUoj8BBG0/Zb0z3uMlgxeXC6wkRzQiC1zJwwuXoLU4SLCvG1Tlt2LpZ0NBXRiCZhPS+1h
 eioSVKwekmk3OzcqPFVT+FN+5LfQwBBKFQ0Z54Sx7T8cneR0bjPjRrKgHzz+uB+t5yjOlIG5P4m
 47GeA+u1rFWaK3CTLIWvZha5cFq2X57OT4BFc69PX+Ym1jdmH1W+Xt9sLjjJ07n5qsFBUAI7/m+
 05qAwcAZ1wr00Bg==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a dt-binding compatible for the Exynos5515 watchdog timer.

This watchdog requires a syscon phandle, and the cluster index should
*not* be specified, as that does not make sense on the Exynos5515 SoC
(due to it only having a single core cluster).

Signed-off-by: Aiden Isik <aidenisik+git@member.fsf.org>
---
 .../devicetree/bindings/watchdog/samsung-wdt.yaml  | 22 +++++++++++++++++++++-
 1 file changed, 21 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/watchdog/samsung-wdt.yaml b/Documentation/devicetree/bindings/watchdog/samsung-wdt.yaml
index 41aee1655b0c..9e754404848b 100644
--- a/Documentation/devicetree/bindings/watchdog/samsung-wdt.yaml
+++ b/Documentation/devicetree/bindings/watchdog/samsung-wdt.yaml
@@ -22,6 +22,7 @@ properties:
           - samsung,s3c6410-wdt                   # for S3C6410, S5PV210 and Exynos4
           - samsung,exynos5250-wdt                # for Exynos5250
           - samsung,exynos5420-wdt                # for Exynos5420
+          - samsung,exynos5515-wdt                # for Exynos5515
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
@@ -93,6 +94,25 @@ allOf:
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
+      required:
+        - samsung,syscon-phandle
+
   - if:
       properties:
         compatible:

-- 
2.54.0

