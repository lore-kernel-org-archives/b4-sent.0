From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Wed, 22 Nov 2023 12:00:06 +0300
Subject: [PATCH v5 28/39] ASoC: dt-bindings: ep93xx: Document Audio Port
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231122-ep93xx-v5-28-d59a76d5df29@maquefel.me>
References: <20231122-ep93xx-v5-0-d59a76d5df29@maquefel.me>
In-Reply-To: <20231122-ep93xx-v5-0-d59a76d5df29@maquefel.me>
To: Hartley Sweeten <hsweeten@visionengravers.com>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-sound@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700643671; l=781;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=fQkTeXGg7TcwMQIX97nCBe2cVG8/7E1wIWiv9MYol48=;
 b=rOtEsf68m2PM3FoJfLj4Nz3g7e0qBm867FCxZytcFiu2AQlnbYAU03C+R9Md3rRnAkbxgUhUhX3R
 NACvJQAFAFJQqVqEOpZoCZDJuBogcODAtEBWfGAYwnZrwWXvyDy8
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document Audio Graph Port support in binding document.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 Documentation/devicetree/bindings/sound/cirrus,ep9301-i2s.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/cirrus,ep9301-i2s.yaml b/Documentation/devicetree/bindings/sound/cirrus,ep9301-i2s.yaml
index 36a320ddf534..4693e85aed37 100644
--- a/Documentation/devicetree/bindings/sound/cirrus,ep9301-i2s.yaml
+++ b/Documentation/devicetree/bindings/sound/cirrus,ep9301-i2s.yaml
@@ -50,6 +50,10 @@ properties:
       - const: tx
       - const: rx
 
+  port:
+    $ref: audio-graph-port.yaml#
+    unevaluatedProperties: false
+
 required:
   - compatible
   - '#sound-dai-cells'

-- 
2.41.0

