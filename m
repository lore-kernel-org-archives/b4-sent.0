From: Ricardo Pardini <ricardo@pardini.net>
Date: Fri, 20 Nov 2026 01:39:28 +0100
Subject: [PATCH 2/3] dt-bindings: arm: rockchip: Add Mekotronics R58X-Pro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-rk3588-mekotronics-r58x-pro-v1-2-4e70c077c7b4@pardini.net>
References: <20261120-rk3588-mekotronics-r58x-pro-v1-0-4e70c077c7b4@pardini.net>
In-Reply-To: <20261120-rk3588-mekotronics-r58x-pro-v1-0-4e70c077c7b4@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=907; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=2G78J0UgfXoTrXCAbZ5jv/J7JIo2b+DqfUU1E8WzZBA=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq/5bAQTWLRYGYREzXDvbPG8mt9JJ3ioqRNk0VE
 Fipxd+VixaJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCav+WwAAKCRA7Xj/jnsft
 6ZJKB/9njf+S8P+q2eGygIUa18wgD85SjCrCbvr1wsJiwBNdxtRLlRVd0ndrpH3qLha3/8YXSoJ
 7fHN4FmrrBwBQr9u4rYQHMzfwGIf2XSNuLLV4fEQ78Z1KChohTvOLjlWpYiZtM5iLeJN1cc9ziF
 dM/XY3i9/xxdumSuKinm0qH2nesOET8QnDrT8SHmkRZ2sTLH7NUWJN0+Cv+U+Dw4+TVwAuedagq
 FW7il78IV8/LvkWn/mPv9+S2vx1NekP/8SRlrvCuvhvo1GiHIf0BDlAQO2kbDj4M4jOPdfaNFrB
 X4O29dFdsjn1me1sx1pYoj+VzxZMwWV3nTzZJ5Y2NW7+BOe7
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
index a24949b163cf..e8817cebdba9 100644
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

