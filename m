From: Richard Leitner <richard.leitner@linux.dev>
Date: Thu, 26 Oct 2023 09:08:50 +0200
Subject: [PATCH v2 2/2] dt-bindings: hwmon: ti,ina2xx: add ti,ina237
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231026-ina237-v2-2-dec44811a3c9@linux.dev>
References: <20231026-ina237-v2-0-dec44811a3c9@linux.dev>
In-Reply-To: <20231026-ina237-v2-0-dec44811a3c9@linux.dev>
To: Guenter Roeck <linux@roeck-us.net>, Jean Delvare <jdelvare@suse.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1698304135; l=711;
 i=richard.leitner@linux.dev; s=20231025; h=from:subject:message-id;
 bh=hz+nOTC5E+8gnzYA2BexlgejiqntKVvvG4MRarols1w=;
 b=52V4KetWDgyIjvgRhZArF8xqDkr7222pycFNSta1cRJ7abK31jjnVIwHzCJpR5h76SRAt7q+Ok0L
 93Y4ZIZ7Awa8ZBIkJkNAvTda5MMabZh/+JOVsOR2Eu4XWKtS6POu
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=ZYa5+0m9RFYtnNU6DLet7sHyPehnVHa0ucJlYiAu2NU=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20231025 with auth_id=90
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ti,ina237 binding to ti,ina2xx as they are very similar and may
share the same properties.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 Documentation/devicetree/bindings/hwmon/ti,ina2xx.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/hwmon/ti,ina2xx.yaml b/Documentation/devicetree/bindings/hwmon/ti,ina2xx.yaml
index 8648877d2d01..378d1f6aeeb3 100644
--- a/Documentation/devicetree/bindings/hwmon/ti,ina2xx.yaml
+++ b/Documentation/devicetree/bindings/hwmon/ti,ina2xx.yaml
@@ -26,6 +26,7 @@ properties:
       - ti,ina226
       - ti,ina230
       - ti,ina231
+      - ti,ina237
       - ti,ina238
 
   reg:

-- 
2.40.1

