From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Mon, 28 Apr 2025 12:44:28 +0200
Subject: [PATCH v2 1/4] dt-bindings: vendor-prefixes: Add TC
 Unterhaltungselektronik AG
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250428-fernsehfee-v2-1-293b98a43a91@posteo.net>
References: <20250428-fernsehfee-v2-0-293b98a43a91@posteo.net>
In-Reply-To: <20250428-fernsehfee-v2-0-293b98a43a91@posteo.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745837069; l=1023;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=lhW1S1FqMGlohP33kbMw1Pv6brNFdpf4vK4RYn9L2Ow=;
 b=FTY9CmJ9n2ohyDbO/qJZqosFFn7U14VWhCnco0IzGh6Gm4JAfeBCIiuq5vK/IPab3X0l9f6Sa
 Ihm0gJtX4+jAcTLq+jgTYmqgc0uFaRXuQcRIgnZuzJPM326GFPDN3k9
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

TC Unterhaltungselektronik is the company behind Fernsehfee branded
set-top boxes.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 86f6a19b28ae217643bf7a63a471f74819d18238..c61c5e11ff5472acb8a6ebdd6d1a66cfa07ae7af 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -1494,6 +1494,8 @@ patternProperties:
     description: Toby Churchill Ltd.
   "^tcs,.*":
     description: Shenzhen City Tang Cheng Technology Co., Ltd.
+  "^tcu,.*":
+    description: TC Unterhaltungselektronik AG
   "^tdo,.*":
     description: Shangai Top Display Optoelectronics Co., Ltd
   "^team-source-display,.*":

-- 
2.48.0.rc1.219.gb6b6757d772

