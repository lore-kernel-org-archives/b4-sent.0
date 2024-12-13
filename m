From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 13 Dec 2024 18:32:47 +0100
Subject: [PATCH 1/4] dt-bindings: gpio: fairchild,74hc595: Add On Semi
 MC74HC595A compat
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241213-gpio74-v1-1-fa2c089caf41@posteo.net>
References: <20241213-gpio74-v1-0-fa2c089caf41@posteo.net>
In-Reply-To: <20241213-gpio74-v1-0-fa2c089caf41@posteo.net>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Maxime Ripard <mripard@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734111175; l=839;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=qxi7ezuDAqwzYk6ajkrcBy3FpR6YWEwtHIQ7XHElelQ=;
 b=hW6LL0mzoKrCGQcv9Jg8Mict776E/boeDHjzroqPMbulfsQw2jXCecr2t8NRT280JUHEpG0b0
 SLdwnLo7s+RDxoBgnPCHNnV/mgqWp5WsnDVSYzqB0u9zWmRjBJx1Mjp
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The On Semi MC74HC595A/MC74HCT595A is another part that is compatible with
the Fairchild MM74HC595. This patch adds it to the DT binding.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 Documentation/devicetree/bindings/gpio/fairchild,74hc595.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/gpio/fairchild,74hc595.yaml b/Documentation/devicetree/bindings/gpio/fairchild,74hc595.yaml
index e8bc9f018edb1253d700945f006e19598efb299a..629cf9b2ab8e4a63fbe17f56792a46d2066d40c3 100644
--- a/Documentation/devicetree/bindings/gpio/fairchild,74hc595.yaml
+++ b/Documentation/devicetree/bindings/gpio/fairchild,74hc595.yaml
@@ -14,6 +14,7 @@ properties:
     enum:
       - fairchild,74hc595
       - nxp,74lvc594
+      - onnn,74hc595a
 
   reg:
     maxItems: 1

-- 
2.45.2

