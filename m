From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Wed, 04 Nov 2026 21:59:21 +0100
Subject: [PATCH v2 1/3] dt-bindings: arm: rockchip: add FriendlyElec NanoPi
 M6V2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-nanopi-m6v2-v2-1-dfcd8714f48a@gmail.com>
References: <20261104-nanopi-m6v2-v2-0-dfcd8714f48a@gmail.com>
In-Reply-To: <20261104-nanopi-m6v2-v2-0-dfcd8714f48a@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Shawn Lin <Shawn.lin@rock-chips.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793825992; l=1010;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=kMzMgde44rYz24ZMLHKoVZSaRZSmvu1GOyj3r3/eQTI=;
 b=F61jD7PkYeloWQ2Ucc5RhDzJjMpJAizwJBCvxrPVZlPen0NNLQEVy9sm5+85FT7QuNWDQO3W5
 g/DuJyGZNa6CPe9K7GHhAQCaGB0PsnFd2/9UWqwBejigJ7wo1bnzkTv
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree binding documentation for FriendlyElec NanoPi M6V2,
a single-board computer based on the Rockchip RK3588S SoC. This board
is an updated version of the original M6 board with a few changes.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 Documentation/devicetree/bindings/arm/rockchip.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/rockchip.yaml b/Documentation/devicetree/bindings/arm/rockchip.yaml
index 456ad1c58e7f5..01a13aaf3e8fb 100644
--- a/Documentation/devicetree/bindings/arm/rockchip.yaml
+++ b/Documentation/devicetree/bindings/arm/rockchip.yaml
@@ -398,6 +398,7 @@ properties:
         items:
           - enum:
               - friendlyarm,nanopi-m6
+              - friendlyarm,nanopi-m6v2
               - friendlyarm,nanopi-r6c
               - friendlyarm,nanopi-r6s
           - const: rockchip,rk3588s

-- 
2.56.0

