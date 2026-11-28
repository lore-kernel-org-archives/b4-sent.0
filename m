From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 19:00:43 +0000
Subject: [PATCH net-next] dt-bindings: net: sun8i-emac: Require the
 mdio-mux node on H3 and V3s
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-sun8i-emac-mux-required-v1-1-187490b1aa45@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM2wrCMBAFf6XsswsmQlv8FfEhl1NdoVFzKYHSf
 ze2j8Mws1JCFCS6ditFLJLkHRqoU0fuacIDLL4x6bPuldIjpxJGYczG8VwqR3yLRHi22g3mMvl
 e24Fa/YmYpO7nGwVkDqiZ7odJxb7g8n9M2/YD/vOTQYUAAAA=
X-Change-ID: 20261128-sun8i-emac-mux-required-b2c7a3fd62b7
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795892442; l=1385;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=9uE/k+HI8ZaqDnoeVabbl4K8WHCPMxQEnlQ4YkoyXj8=;
 b=mXnMXngTFwXiwUUyox16paN3Z0wX47wsfhaLelZoR282raRhyipPe4LSU1AmEn+lJQdd6Uk78
 EKzD4qrSZjEAqxEZolecOTPlV2eyoz/lqpQtIzT1/TJ9lxQTrmEMbl0
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 0569929d9799 ("dt-bindings: net: sun8i-emac: Convert the binding
to a schemas") dropped the mdio-mux requirement for H3 and V3s, but the
driver fails the probe without the node. Restore it.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Found by Sashiko [1]. dt_binding_check is clean, dtbs_check of the in-tree
H3/H5/V3/V3s/S3 DTBs is unchanged, and an orangepi-pc DTB without the
node now fails. Developed with Claude (Anthropic); I reviewed it.

[1] https://lore.kernel.org/r/179551897695.3135.144965187993855310@kernel.org
---
 Documentation/devicetree/bindings/net/allwinner,sun8i-a83t-emac.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/allwinner,sun8i-a83t-emac.yaml b/Documentation/devicetree/bindings/net/allwinner,sun8i-a83t-emac.yaml
index 2cae0133b3cd..661bb5a16013 100644
--- a/Documentation/devicetree/bindings/net/allwinner,sun8i-a83t-emac.yaml
+++ b/Documentation/devicetree/bindings/net/allwinner,sun8i-a83t-emac.yaml
@@ -228,6 +228,9 @@ allOf:
             - mdio-parent-bus
             - mdio@1
 
+      required:
+        - mdio-mux
+
   - if:
       properties:
         compatible:

---
base-commit: f89726ffabef1b08c52e6163b7ab94b0d5f15503
change-id: 20261128-sun8i-emac-mux-required-b2c7a3fd62b7

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

