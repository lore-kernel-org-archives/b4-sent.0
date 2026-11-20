From: Rajan Yadav <rajanyadav0307@gmail.com>
Date: Fri, 20 Nov 2026 01:22:13 -0600
Subject: [PATCH 1/4] dt-bindings: vendor-prefixes: Add Shenzhen Kickpi
 Digital Technology
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-k5c-dt-v1-v1-1-d9681df67bc0@gmail.com>
References: <20261120-k5c-dt-v1-v1-0-d9681df67bc0@gmail.com>
In-Reply-To: <20261120-k5c-dt-v1-v1-0-d9681df67bc0@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 Andre Przywara <andre.przywara@arm.com>, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Rajan Yadav <rajanyadav0307@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795159332; l=1286;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=gFo6j59NzHKrlOvLgDxrGptA4LIjDH4Hdw5hr398y8U=;
 b=fFpAMIAg/lv2xBPfX2kce0TU5AiNuFAAajV4OUITbIHuTYyxTXr5MeOoYbe4kC1sej5l5Qq7W
 6WdSvsIj/s1Acp0v5kKMtccaa7nlP+78pRUp8XmFIMVrfZTnqcAY8Qf
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Shenzhen Kickpi Digital Technology Co., Ltd. makes single board
computers under the KickPi name, such as the KickPi K5C with an
Allwinner A133 SoC. Add a vendor prefix for them.

The company name is the one KickPi uses on its documentation site
(doc.kickpi.com) and as the registered owner of the KICKPI trademark
(US registration 7747802); their e-mail and web domain is kickpi.com.

Claude Code (Anthropic) drafted this change and its message; I
reviewed it and checked it with dt_binding_check.

Link: https://www.kickpi.com/
Signed-off-by: Rajan Yadav <rajanyadav0307@gmail.com>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 5471a06f93f..a67f9c1c896 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -919,6 +919,8 @@ patternProperties:
     description: Keymile GmbH
   "^khadas,.*":
     description: Khadas
+  "^kickpi,.*":
+    description: Shenzhen Kickpi Digital Technology Co., Ltd.
   "^kiebackpeter,.*":
     description: Kieback & Peter GmbH
   "^kinetic,.*":

-- 
2.34.1

