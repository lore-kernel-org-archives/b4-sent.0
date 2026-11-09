From: Umer Uddin <umer.uddin@mentallysanemainliners.org>
Date: Mon, 09 Nov 2026 21:02:02 +0000
Subject: [PATCH v2 1/2] dt-bindings: arm: samsung: samsung-boards: Add
 bindings for SM-T515 board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-gta3xllte-support-v2-1-85c31b6efebd@mentallysanemainliners.org>
References: <20261109-gta3xllte-support-v2-0-85c31b6efebd@mentallysanemainliners.org>
In-Reply-To: <20261109-gta3xllte-support-v2-0-85c31b6efebd@mentallysanemainliners.org>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Umer Uddin <umer.uddin@mentallysanemainliners.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794258123; l=932;
 i=umer.uddin@mentallysanemainliners.org; s=20261109;
 h=from:subject:message-id; bh=rPHV+1f50EZ85D3csJMso8rMA1UhcD9FsDkCoV1Wx3o=;
 b=zUnWIrqvadiWfBOS7sVKmVI09UnbwQgEzT1TCWU/YJA2x+FMIDqrTIJwAk0MNH0+YVgWpLN9l
 xhuGqB0AkYwDYLxonFJPW+ZK1pX9fkNKksjEeJaueAvFfRf/pf93k2I
X-Developer-Key: i=umer.uddin@mentallysanemainliners.org; a=ed25519;
 pk=Hsgrt4A72CFTe27AI1AAWlnLsiQrlb4+T+cbrfWDhUA=
X-Endpoint-Received: by B4 Relay for umer.uddin@mentallysanemainliners.org/20261109 with auth_id=1466
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree bindings for Samsung Galaxy Tab A 10.1 (2019, 4G) board.

Signed-off-by: Umer Uddin <umer.uddin@mentallysanemainliners.org>
---
 Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml b/Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml
index db19a686f490..6ac7f895351e 100644
--- a/Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml
+++ b/Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml
@@ -226,6 +226,7 @@ properties:
       - description: Exynos7885 based boards
         items:
           - enum:
+              - samsung,gta3xllte               # Samsung Galaxy Tab A 10.1 (2019, 4G)
               - samsung,jackpotlte              # Samsung Galaxy A8 (2018)
           - const: samsung,exynos7885
 

-- 
2.56.0

