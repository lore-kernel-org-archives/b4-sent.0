From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Date: Sat, 19 Sep 2026 18:28:17 +0800
Subject: [PATCH v7 1/3] dt-bindings: arm: rockchip: Add FriendlyElec NanoPi
 R28S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260919-r28s-upstream-v7-1-e80a6f8ef521@proton.me>
References: <20260919-r28s-upstream-v7-0-e80a6f8ef521@proton.me>
In-Reply-To: <20260919-r28s-upstream-v7-0-e80a6f8ef521@proton.me>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chukun Pan <amadeus@jmu.edu.cn>, Jonas Karlman <jonas@kwiboo.se>, 
 jensen <jensenhuang@friendlyarm.com>, 
 Andrey Korshunov <razor1702@gmail.com>, 
 Diederik de Haas <diederik@cknow-tech.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1622;
 i=HystericalDragons@proton.me; h=from:subject:message-id;
 bh=GjgiG/CwrGYA6nG9hPXid2MYCUCClI7qpstAQn8fUNs=;
 b=owGbwMvMwCUmepz3XUtTHjvjabUkhqx1ycdlp/poMgdu33paPfj0iRvdTS61+64sX2JaLHfRf
 7qgVW9rRykLgxgXg6yYIovspupIoVXRM4tYpI7DzGFlAhnCwMUpABM5Uc/wT/lQ1nMphfCFHz/z
 G5yNNl24NULE+t3uKE+JlFqpjthpfxgZfl6zswvNaqm3W872/J/n4y2q7z8Kb4l453N7C6fu/+Y
 adgA=
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=1DB27B5912AA5B9972041AC715C70DEE84826E07
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/default with auth_id=1004
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The NanoPi R28S is a dual gigabit Ethernet router board based on the
Rockchip RK3528 SoC. It shares its base devicetree with the NanoPi
Zero2, so fold both boards into a single RK3528 series entry, which
further RK3528 based NanoPi boards can join without renaming it.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: 安容 <HystericalDragons@proton.me>
---
 Documentation/devicetree/bindings/arm/rockchip.yaml | 12 +++++++-----
 1 file changed, 7 insertions(+), 5 deletions(-)

diff --git a/Documentation/devicetree/bindings/arm/rockchip.yaml b/Documentation/devicetree/bindings/arm/rockchip.yaml
index 81744fbee9..dc69999862 100644
--- a/Documentation/devicetree/bindings/arm/rockchip.yaml
+++ b/Documentation/devicetree/bindings/arm/rockchip.yaml
@@ -347,6 +347,13 @@ properties:
               - friendlyarm,nanopi-r2s-plus
           - const: rockchip,rk3328
 
+      - description: FriendlyElec NanoPi RK3528 series boards
+        items:
+          - enum:
+              - friendlyarm,nanopi-r28s
+              - friendlyarm,nanopi-zero2
+          - const: rockchip,rk3528
+
       - description: FriendlyElec NanoPi R3S
         items:
           - const: friendlyarm,nanopi-r3s
@@ -388,11 +395,6 @@ properties:
           - const: friendlyarm,nanopi-r76s
           - const: rockchip,rk3576
 
-      - description: FriendlyElec NanoPi Zero2
-        items:
-          - const: friendlyarm,nanopi-zero2
-          - const: rockchip,rk3528
-
       - description: FriendlyElec NanoPC T6 series boards
         items:
           - enum:

-- 
2.55.0

