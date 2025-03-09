From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sun, 09 Mar 2025 14:16:20 +0100
Subject: [PATCH 1/2] dt-bindings: arm: amlogic: Add Ogoos AM3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250309-ugoos-am3-v1-1-38cab5a4725b@posteo.net>
References: <20250309-ugoos-am3-v1-0-38cab5a4725b@posteo.net>
In-Reply-To: <20250309-ugoos-am3-v1-0-38cab5a4725b@posteo.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741526184; l=888;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=cqqIMQAjsp7Lgq4pj0jk6mh06cp/exYekgA28kwLzGU=;
 b=MQdcbQ2DByDgPVBjz4/nCnfDMhGmDOXtL9cjBlqd/eSMIt6t2TQd3pYRCHyLK2iNWWYrpO+kI
 EHtBqcvSJfVAnhfzDFzxTwEEF+ptaGvBd6jxsVOa1Y/4QUCAeLFM1zN
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Ugoos AM3 is a small set-top box based on the Amlogic S912 SoC.

  https://ugoos.com/ugoos-am3-16g

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 Documentation/devicetree/bindings/arm/amlogic.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/amlogic.yaml b/Documentation/devicetree/bindings/arm/amlogic.yaml
index 0647851ae1f55a27bfb148252532bcf15ca905bf..779568f158ce985e1d12fbee73418549cfc58705 100644
--- a/Documentation/devicetree/bindings/arm/amlogic.yaml
+++ b/Documentation/devicetree/bindings/arm/amlogic.yaml
@@ -127,6 +127,7 @@ properties:
               - minix,neo-u9h
               - nexbox,a1
               - tronsmart,vega-s96
+              - ugoos,am3
               - videostrong,gxm-kiii-pro
               - wetek,core2
           - const: amlogic,s912

-- 
2.48.0.rc1.219.gb6b6757d772

