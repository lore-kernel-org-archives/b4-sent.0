From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Date: Tue, 03 Nov 2026 18:37:06 +0800
Subject: [PATCH v3 1/6] dt-bindings: arm: rockchip: Add FriendlyElec NanoPi
 R28S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-nanopi-r28s-v3-1-ae8664fd168f@proton.me>
References: <20261103-nanopi-r28s-v3-0-ae8664fd168f@proton.me>
In-Reply-To: <20261103-nanopi-r28s-v3-0-ae8664fd168f@proton.me>
To: u-boot@lists.u-boot-project.org
Cc: Kever Yang <kever.yang@rock-chips.com>, 
 Quentin Schulz <u-boot@0leil.net>, Jonas Karlman <jonas@kwiboo.se>, 
 Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>, 
 Heiko Stuebner <heiko@sntech.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1833;
 i=HystericalDragons@proton.me; s=20261103; h=from:subject:message-id;
 bh=L+1Fp55shYkTyH7p3MowRNm8t4fglhebV98qUkz2YWU=;
 b=owGbwMvMwCU8Ldb53x4TtgLG02pJDFkvdwbPydqizc/7tIrlxbZYLrvM94mL3j9TTbo86evB/
 Z/vBZd/79jBwiDMxSArpsjSKf154pfHF6Z/vTkpC2YOKxPIEAYuTgGYSHUYE5uRDEdiSeNdjhye
 nWrbvcviapae1WNVSNHVnvWO+TCPFXtXY/uPLzJbNf4ytP24spTJMnetmqlT8pI3PeyPzxvGvVZ
 czMTJaM8lfGRNuJhEp8EB9q7Q163LRR1P1TNqFB06UaPttiz4u2sS0+mpjOUTw536S45s6tOV31
 /3Wm1Rp+2yE4f1TrVMz08CAA==
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=5A3AC293DCEEAA41A8A3266A910205A0AEB09D84
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/20261103 with auth_id=1393
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The NanoPi R28S is a dual gigabit Ethernet router board based on the
Rockchip RK3528 SoC. It shares its base devicetree with the NanoPi
Zero2, so fold both boards into a single RK3528 series entry, which
further RK3528 based NanoPi boards can join without renaming it.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: 安容 <HystericalDragons@proton.me>
Link: https://patch.msgid.link/20260919-r28s-upstream-v7-1-e80a6f8ef521@proton.me
Signed-off-by: Heiko Stuebner <heiko@sntech.de>

[ upstream commit: bdcf29a379afecc02c3e99c0d1745363ad7a7407 ]

(cherry picked from commit e9eafc0ca521c8d12e1a65b43f899e336ef28eba)
---
 dts/upstream/Bindings/arm/rockchip.yaml | 12 +++++++-----
 1 file changed, 7 insertions(+), 5 deletions(-)

diff --git a/dts/upstream/Bindings/arm/rockchip.yaml b/dts/upstream/Bindings/arm/rockchip.yaml
index a799bb843f7..a1f000b1bee 100644
--- a/dts/upstream/Bindings/arm/rockchip.yaml
+++ b/dts/upstream/Bindings/arm/rockchip.yaml
@@ -340,6 +340,13 @@ properties:
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
@@ -381,11 +388,6 @@ properties:
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
2.56.0

