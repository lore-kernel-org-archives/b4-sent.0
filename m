From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 07 Sep 2026 19:13:39 +0200
Subject: [PATCH v2 1/3] dt-bindings: vendor-prefixes: add Free Mobile
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260907-for-upstream-nbxv3-dts-v2-1-6b4afd36180b@free.fr>
References: <20260907-for-upstream-nbxv3-dts-v2-0-6b4afd36180b@free.fr>
In-Reply-To: <20260907-for-upstream-nbxv3-dts-v2-0-6b4afd36180b@free.fr>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788801225; l=855;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=GS6HXtqxwlBUlcOkCxh64ErhDBGMmoQtgCG1FanLSW4=;
 b=pZTrPdNKSAjqy369GEIvgRGDHKgqpAo5QEJdf9oK7rxagmgL1vFoiLjoIAGLGbVLJ7qjnLIY1
 WWbzt14169QDNjfuiqgA0rx+QuTx4SouVvlwVwoaw1acfVo+wH8hKZk
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Free Mobile is a French mobile network operator. Add its vendor
prefix, used by the Nodebox v3 CPU Module (freemobile,nbxv3).

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index ba20029693734..e467da45cd7ac 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -626,6 +626,8 @@ patternProperties:
     description: Freebox SAS
   "^freecom,.*":
     description: Freecom Gmbh
+  "^freemobile,.*":
+    description: Free Mobile
   "^frida,.*":
     description: Shenzhen Frida LCD Co., Ltd.
   "^friendlyarm,.*":

-- 
2.43.0

