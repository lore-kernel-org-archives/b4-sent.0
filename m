From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sun, 23 Mar 2025 13:37:50 +0100
Subject: [PATCH 1/3] dt-bindings: vendor-prefixes: Add TC
 Unterhaltungselektronik AG
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250323-fernsehfee-v1-1-2621341cd37a@posteo.net>
References: <20250323-fernsehfee-v1-0-2621341cd37a@posteo.net>
In-Reply-To: <20250323-fernsehfee-v1-0-2621341cd37a@posteo.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742733500; l=959;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=uaz9m8VjNE4NEygLbUtmBG2+WbjOgy1rPMuQ4WTpnro=;
 b=XWEvZjys42PmDLa1n4FLTA9f2MmzxWu8uLr8Mzx4Mal4ZylyaFFdxjPKN+Az3yww8cB+aEWHj
 WpA+cD9U14/B0t2ta3oMhRBIPPX4SlIOX4/8AZbHcQA/4q2fxIr/B45
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

TC Unterhaltungselektronik is the company behind Fernsehfee branded
set-top boxes.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 5079ca6ce1d1e9e2b52312439e4b1d48b262200c..0019f6131bbfc11ba55f5a15a238825abf665aaf 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -1484,6 +1484,8 @@ patternProperties:
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

