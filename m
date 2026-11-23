From: Ricardo Pardini <ricardo@pardini.net>
Date: Mon, 23 Nov 2026 16:07:27 +0100
Subject: [PATCH v2 2/3] dt-bindings: arm: rockchip: Add Mekotronics
 R58X-Pro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-rk3588-mekotronics-r58x-pro-v2-2-2a3430cf5f88@pardini.net>
References: <20261123-rk3588-mekotronics-r58x-pro-v2-0-2a3430cf5f88@pardini.net>
In-Reply-To: <20261123-rk3588-mekotronics-r58x-pro-v2-0-2a3430cf5f88@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=909; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=5tvM2v/b/zAV6i3N+Q541Ucn1iSwSgwcNGoUzeuHrDY=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBrBFa4T7h3xDYAGt7U028mkQDIYNCB6XGbMwBqY
 OOVPpqmQFmJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCawRWuAAKCRA7Xj/jnsft
 6ZJDB/47TCHhmYrhrRHjpapvAGNrJ6mfW83UpP5N+ScNANgPQkOz5pGDsFLxFSgUeeUS471ODaH
 6/MLTG8Os2ucJXb7tcS1wBzSOdUJgXZs2vEcizGqHaKMQZiBOJuFoaBbC50qJBnKjrAhtdYB9zG
 SovI0aWvZnyyJvoS81ER3wcUul/W+dJDlfkEvum98GwIIIBrzD+dpqMwKalCw1sY3lgkp9kf4Ln
 6nuJJGiZyNTADJc9HQGtg9bizAMqVEZx6AZq4X1OqMCeULfVhB8bj7WDAxBLKrkYI34ItMZ05SH
 uoG4yPS1si5lJxII80hnj1TY1YA5Nx8Q2BenbQvvdeQTFS3x
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the compatible for the Mekotronics R58X-Pro, an industrial mini PC
based on the Rockchip RK3588 SoC.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 Documentation/devicetree/bindings/arm/rockchip.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/rockchip.yaml b/Documentation/devicetree/bindings/arm/rockchip.yaml
index a24949b163cff..e8817cebdba9c 100644
--- a/Documentation/devicetree/bindings/arm/rockchip.yaml
+++ b/Documentation/devicetree/bindings/arm/rockchip.yaml
@@ -864,6 +864,11 @@ properties:
           - const: widora,mangopi-m28k
           - const: rockchip,rk3528
 
+      - description: Mekotronics R58X-Pro
+        items:
+          - const: mekotronics,r58x-pro
+          - const: rockchip,rk3588
+
       - description: mqmaker MiQi
         items:
           - const: mqmaker,miqi

-- 
2.47.3

