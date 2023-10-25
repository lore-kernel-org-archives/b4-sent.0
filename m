From: Richard Leitner <richard.leitner@linux.dev>
Date: Wed, 25 Oct 2023 10:34:14 +0000
Subject: [PATCH 4/4] dt-bindings: hwmon: ti,ina238: add ti,ina237
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231025-ina237-v1-4-a0196119720c@linux.dev>
References: <20231025-ina237-v1-0-a0196119720c@linux.dev>
In-Reply-To: <20231025-ina237-v1-0-a0196119720c@linux.dev>
To: Guenter Roeck <linux@roeck-us.net>, Jean Delvare <jdelvare@suse.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1698230088; l=666;
 i=richard.leitner@linux.dev; s=20231025; h=from:subject:message-id;
 bh=2UlV2SAeLThisZx2CDUzVQIsXFCsdphm0WX5MqF/paA=;
 b=qVMEmSxVR/Bxf6+PrpumfMpyFJL40+yFqvVmuDr8yuDujWEFxZ2CGxoNMGcrHJR8tHp9Rf4n02pU
 YDhZzYxyBzu4oeagPUqVG4mczsszD7wqGMgouzCpDI++hLYnLHSe
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=ZYa5+0m9RFYtnNU6DLet7sHyPehnVHa0ucJlYiAu2NU=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20231025 with auth_id=90
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ti,ina237 binding to ti,ina238 as they share the same driver.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 Documentation/devicetree/bindings/hwmon/ti,ina238.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/hwmon/ti,ina238.yaml b/Documentation/devicetree/bindings/hwmon/ti,ina238.yaml
index aba89e5f34b3..17408076696c 100644
--- a/Documentation/devicetree/bindings/hwmon/ti,ina238.yaml
+++ b/Documentation/devicetree/bindings/hwmon/ti,ina238.yaml
@@ -22,6 +22,7 @@ description: |
 properties:
   compatible:
     enum:
+      - ti,ina237
       - ti,ina238
 
   reg:

-- 
2.40.1

