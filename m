From: Ricardo Pardini <ricardo@pardini.net>
Date: Mon, 23 Nov 2026 16:07:26 +0100
Subject: [PATCH v2 1/3] dt-bindings: vendor-prefixes: Add Mekotronics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-rk3588-mekotronics-r58x-pro-v2-1-2a3430cf5f88@pardini.net>
References: <20261123-rk3588-mekotronics-r58x-pro-v2-0-2a3430cf5f88@pardini.net>
In-Reply-To: <20261123-rk3588-mekotronics-r58x-pro-v2-0-2a3430cf5f88@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=895; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=rwVu4BEUHXmVQV5ANdnCfqg9lM0S+d24Qc9S/0M6UCA=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBrBFa3XDcIt+WFnK50QuZukoPzIntotu1ZUjx2v
 yLPh3oaeASJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCawRWtwAKCRA7Xj/jnsft
 6TgrCAChyeJsZMoPikMtXVSXeLalam5+o87nQLM6WlkednG5DyKmDPVwymGVm9E/BuNnrH+IvsT
 NgcycoMjIUTSp73GnCuL7atyz8Fu+m/DUQTnGmb6timH6CAISmEQlyqz/1lbCelLKYx32FEy+zb
 rP3ffrybSksv8xA/fLxoApZvuE5gVBEdJppQecFg8zmg6y2Jd72xJg3M/9y0JMVS8knpIH+pAmY
 XjuRC2xn578EZw4ZttfgeJgSSeV2Lh/yQ5cUYSgV3dgTePJH9M0GztmMtqP7SVvoJhgKsB9z7zC
 nHpSjtNCnzgJeeAd5p8PthqoLnXf+jI+eJNGwSyuBNVNKHAF
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Mekotronics is a Chinese manufacturer of industrial mini PCs and
single board computers based on Rockchip SoCs.

Link: https://www.mekotronics.com
Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 5471a06f93f10..ddf06858856d4 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -1067,6 +1067,8 @@ patternProperties:
     description: Medion AG
   "^megachips,.*":
     description: MegaChips
+  "^mekotronics,.*":
+    description: Mekotronics Co., Ltd.
   "^mele,.*":
     description: Shenzhen MeLE Digital Technology Ltd.
   "^melexis,.*":

-- 
2.47.3

