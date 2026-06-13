From: Enzo Adriano <enzo.adriano.code@gmail.com>
Date: Sat, 13 Jun 2026 05:42:14 -0400
Subject: [PATCH 2/4] dt-bindings: mmc: add Allwinner A733 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260613-a733-dts-v1-public-ready-v1-2-7787c94681db@gmail.com>
References: <20260613-a733-dts-v1-public-ready-v1-0-7787c94681db@gmail.com>
In-Reply-To: <20260613-a733-dts-v1-public-ready-v1-0-7787c94681db@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>, 
 Ulf Hansson <ulfh@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-mmc@vger.kernel.org, Enzo Adriano <enzo.adriano.code@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781343732; l=895;
 i=enzo.adriano.code@gmail.com; s=a733-cubie-a7s; h=from:subject:message-id;
 bh=zVJKVu7EGuw8s8oGE8yMBHZdc3RPxLxGeUk2Y5HLBc4=;
 b=OwgC+JN5AxLkp2caqoaunDY4+/Rg7UispYVAhVzR01NX/xGu8rU+mT5ag15avNFEpQPgGL2xd
 w/SSVPmL2kfCkdwUaZJS/7zONdzg2abvndKPVpuP38+mOo01+0S893R
X-Developer-Key: i=enzo.adriano.code@gmail.com; a=ed25519;
 pk=5S3Wmdqa4XfCdeZF/HfeYqnQF8GN9JGt3SE1cxqSX8E=
X-Endpoint-Received: by B4 Relay for enzo.adriano.code@gmail.com/a733-cubie-a7s with auth_id=820
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the A733 MMC controller compatible with the existing D1-style
fallback.

Signed-off-by: Enzo Adriano <enzo.adriano.code@gmail.com>
---
 Documentation/devicetree/bindings/mmc/allwinner,sun4i-a10-mmc.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/mmc/allwinner,sun4i-a10-mmc.yaml b/Documentation/devicetree/bindings/mmc/allwinner,sun4i-a10-mmc.yaml
index 9f3b1edacaa0..9e9590521210 100644
--- a/Documentation/devicetree/bindings/mmc/allwinner,sun4i-a10-mmc.yaml
+++ b/Documentation/devicetree/bindings/mmc/allwinner,sun4i-a10-mmc.yaml
@@ -58,6 +58,9 @@ properties:
       - items:
           - const: allwinner,sun55i-a523-mmc
           - const: allwinner,sun20i-d1-mmc
+      - items:
+          - const: allwinner,sun60i-a733-mmc
+          - const: allwinner,sun20i-d1-mmc
 
   reg:
     maxItems: 1

-- 
2.53.0

