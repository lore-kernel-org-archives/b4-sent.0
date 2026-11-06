From: Ben Grisdale <bengris32@protonmail.ch>
Date: Fri, 06 Nov 2026 15:13:05 +0000
Subject: [PATCH 1/2] regulator: dt-bindings: fan53555: Add Silergy SYM827
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-fan53555-silergy-sym827-support-v1-1-4e871c7f475c@protonmail.ch>
References: <20261106-fan53555-silergy-sym827-support-v1-0-4e871c7f475c@protonmail.ch>
In-Reply-To: <20261106-fan53555-silergy-sym827-support-v1-0-4e871c7f475c@protonmail.ch>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793978058; l=868;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=qUex7JnM/vla7BxxPF0GGdCxKqcEzvskd/p297Vrwo4=;
 b=0bxKsdnzMxuOfoRMy652LToiG7q3uCysciWTlaQDwUWX5I8tHYJVD1Fz/0ayXA06oqU+TaP/P
 /pu/7Y3XkQgC/LBP7iQ386jHrB1qAGp2Rl5JIcgSruXvO53r/sbGnRo
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for the Silergy SYM827, a 6A synchronous
step-down converter with a similar I2C register map to the FAN53555.

Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 Documentation/devicetree/bindings/regulator/fcs,fan53555.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/regulator/fcs,fan53555.yaml b/Documentation/devicetree/bindings/regulator/fcs,fan53555.yaml
index b35b8f365b0f..1bc22eb43dd9 100644
--- a/Documentation/devicetree/bindings/regulator/fcs,fan53555.yaml
+++ b/Documentation/devicetree/bindings/regulator/fcs,fan53555.yaml
@@ -20,6 +20,7 @@ properties:
           - fcs,fan53526
           - rockchip,rk8600
           - rockchip,rk8602
+          - silergy,sym827
           - silergy,syr827
           - silergy,syr828
           - tcs,tcs4525

-- 
2.56.0

