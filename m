From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Mon, 17 Jun 2024 12:37:00 +0300
Subject: [PATCH v10 26/38] ASoC: dt-bindings: ep93xx: Document DMA support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240617-ep93xx-v10-26-662e640ed811@maquefel.me>
References: <20240617-ep93xx-v10-0-662e640ed811@maquefel.me>
In-Reply-To: <20240617-ep93xx-v10-0-662e640ed811@maquefel.me>
To: Hartley Sweeten <hsweeten@visionengravers.com>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-sound@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718617100; l=1224;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=IYgRqPiUpJda2whx2paj9O35GPXheF0lc1rCPFeTg9o=;
 b=9q0iZ5LJ0KG4HhEwTMjG/Rcm8wW9MV4d51edKmjpR8IUp9ISWH4xa5lyQeLBmmPjhp3wzo6KAQ+A
 oWYiUfBJClv9rzk1yQ3D8z8i8gYOK+f14SSRBs2glXhLkoiqSeiJ
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document DMA support in binding document.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Reviewed-by: Mark Brown <broonie@kernel.org>
---
 .../devicetree/bindings/sound/cirrus,ep9301-i2s.yaml         | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/cirrus,ep9301-i2s.yaml b/Documentation/devicetree/bindings/sound/cirrus,ep9301-i2s.yaml
index 453d493c941f..36a320ddf534 100644
--- a/Documentation/devicetree/bindings/sound/cirrus,ep9301-i2s.yaml
+++ b/Documentation/devicetree/bindings/sound/cirrus,ep9301-i2s.yaml
@@ -40,6 +40,16 @@ properties:
       - const: sclk
       - const: lrclk
 
+  dmas:
+    items:
+      - description: out DMA channel
+      - description: in DMA channel
+
+  dma-names:
+    items:
+      - const: tx
+      - const: rx
+
 required:
   - compatible
   - '#sound-dai-cells'
@@ -61,6 +71,8 @@ examples:
                  <&syscon 30>,
                  <&syscon 31>;
         clock-names = "mclk", "sclk", "lrclk";
+        dmas = <&dma0 0 1>, <&dma0 0 2>;
+        dma-names = "tx", "rx";
     };
 
 ...

-- 
2.43.2

