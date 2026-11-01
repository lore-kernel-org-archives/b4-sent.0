From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Sun, 01 Nov 2026 23:00:52 +0100
Subject: [PATCH 1/3] dt-bindings: arm: rockchip: add FriendlyElec NanoPi
 M6V2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-nanopi-m6v2-v1-1-e401ea64b394@gmail.com>
References: <20261101-nanopi-m6v2-v1-0-e401ea64b394@gmail.com>
In-Reply-To: <20261101-nanopi-m6v2-v1-0-e401ea64b394@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Shawn Lin <Shawn.lin@rock-chips.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793570476; l=940;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=xVk4B1jOv3LSCGkGw0hfHKz0UpvYSO+VAerlPGw1LtQ=;
 b=1mnT3U+SfryHw8PD6flAr0YpAYDOqd7y4ItNbI9+cvvhiUyPQZK96kHFiqFMeoXVdQK9JEEpV
 O6aDLzIO3pJAyoBzN5N41PkbDHBONZZomYLUf1G1aZVzNLZtb3pDxWJ
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree binding documentation for FriendlyElec NanoPi M6V2,
a single-board computer based on the Rockchip RK3588S SoC. This board
is an updated version of the original M6 board with a few changes.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 Documentation/devicetree/bindings/arm/rockchip.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/rockchip.yaml b/Documentation/devicetree/bindings/arm/rockchip.yaml
index a24949b163cff..70d78f7f8c559 100644
--- a/Documentation/devicetree/bindings/arm/rockchip.yaml
+++ b/Documentation/devicetree/bindings/arm/rockchip.yaml
@@ -392,6 +392,7 @@ properties:
         items:
           - enum:
               - friendlyarm,nanopi-m6
+              - friendlyarm,nanopi-m6v2
               - friendlyarm,nanopi-r6c
               - friendlyarm,nanopi-r6s
           - const: rockchip,rk3588s

-- 
2.56.0

