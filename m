From: Ricardo Pardini <ricardo@pardini.net>
Date: Fri, 20 Nov 2026 01:39:27 +0100
Subject: [PATCH 1/3] dt-bindings: vendor-prefixes: Add Mekotronics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-rk3588-mekotronics-r58x-pro-v1-1-4e70c077c7b4@pardini.net>
References: <20261120-rk3588-mekotronics-r58x-pro-v1-0-4e70c077c7b4@pardini.net>
In-Reply-To: <20261120-rk3588-mekotronics-r58x-pro-v1-0-4e70c077c7b4@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=893; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=tdZ5Gv+020lndTtofgOunypBXIjX4W1b3fbo3BuNVP4=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq/5a/6HsaT8egAyGahPN23aDtgjy29G7m4FCJi
 D26go1E+zyJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCav+WvwAKCRA7Xj/jnsft
 6RTaB/9Ktg5sIirrYbaHMSc+4QalJhLY8T+kttDKUDHfs7gWd0EQnQfA7UztvJfKc2Vowyp7QBM
 lUo0PlYXWmeeZaEFq7OY97tNU3x7dpqduzPHBHkicF9LlVzNauQehS7sQwUp0jnyjmMzETMBmKA
 JWArEIJPhJ2DbLWiTsPoN5Ksbzb/s01BzwhdNl/AkxPdtA2sH5jag1KKiYl0W1LMFjkNoeMUVgk
 OuxNPHKlmSUllj/xyB9fotXoEFofChuMvSGSEqPjqacpXjaq3Bl02Ka9J+CcDU4h0mT62ig4/nM
 JD+3ILiScXYq0K7WGpIbOOODXoVaJTDPCi6M7ZYPxSXGhk6S
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
index 5471a06f93f1..ddf06858856d 100644
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

