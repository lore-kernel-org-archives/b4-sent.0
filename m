From: Pieterjan Camerlynck <pieterjanca@gmail.com>
Date: Wed, 10 Jul 2024 16:32:41 +0200
Subject: [PATCH v2 1/2] dt-bindings: leds: pca995x: Add new nxp,pca9956b
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240710-pca995x-v2-1-8fafb6e4b7d5@gmail.com>
References: <20240710-pca995x-v2-0-8fafb6e4b7d5@gmail.com>
In-Reply-To: <20240710-pca995x-v2-0-8fafb6e4b7d5@gmail.com>
To: Pavel Machek <pavel@ucw.cz>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Isai Gaspar <isaiezequiel.gaspar@nxp.com>, Marek Vasut <marex@denx.de>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Pieterjan Camerlynck <pieterjanca@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720622068; l=1529;
 i=pieterjanca@gmail.com; s=20240709; h=from:subject:message-id;
 bh=6vO+6FBkF83NNJD/iYLLMy7G/J0jk6c6K0j7e/z+Ghg=;
 b=BXYTI3rjON12iAtJ3DR9Cmlx4DClvKRBpE4dlu/HzFT8/Uk2JPEU2xTMTzqDtKhMnYsSkJw7O
 LLmF0ib3fQEBdYpJsO0tOAQHd0McOH0EET2jPlb41jHJQIKmhfN2jxJ
X-Developer-Key: i=pieterjanca@gmail.com; a=ed25519;
 pk=gSAHfvqQjVhNa1MhUClqbt7d3S+fviKz6FdQVaWFRyM=
X-Endpoint-Received: by B4 Relay for pieterjanca@gmail.com/20240709 with auth_id=182
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add nxp,pca9956b compatible, which has 24 instead of 16 outputs. Adjust
the documentation for the difference.

Reviewed-by: Marek Vasut <marex@denx.de>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Pieterjan Camerlynck <pieterjanca@gmail.com>
---
 Documentation/devicetree/bindings/leds/nxp,pca995x.yaml | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/leds/nxp,pca995x.yaml b/Documentation/devicetree/bindings/leds/nxp,pca995x.yaml
index 654915c1f687..ab8c90cbadb5 100644
--- a/Documentation/devicetree/bindings/leds/nxp,pca995x.yaml
+++ b/Documentation/devicetree/bindings/leds/nxp,pca995x.yaml
@@ -11,19 +11,21 @@ maintainers:
   - Marek Vasut <marex@denx.de>
 
 description:
-  The NXP PCA9952/PCA9955B are programmable LED controllers connected via I2C
-  that can drive 16 separate lines. Each of them can be individually switched
+  The NXP PCA995x family are programmable LED controllers connected via I2C
+  that can drive separate lines. Each of them can be individually switched
   on and off, and brightness can be controlled via individual PWM.
 
   Datasheets are available at
   https://www.nxp.com/docs/en/data-sheet/PCA9952_PCA9955.pdf
   https://www.nxp.com/docs/en/data-sheet/PCA9955B.pdf
+  https://www.nxp.com/docs/en/data-sheet/PCA9956B.pdf
 
 properties:
   compatible:
     enum:
       - nxp,pca9952
       - nxp,pca9955b
+      - nxp,pca9956b
 
   reg:
     maxItems: 1

-- 
2.45.2

