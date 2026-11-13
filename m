From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 16:38:48 +0000
Subject: [PATCH 2/9] dt-bindings: ata: rockchip,dwc-ahci: Allow iommus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-mmu600-php-v1-2-231196049a3b@gmail.com>
References: <20261113-mmu600-php-v1-0-231196049a3b@gmail.com>
In-Reply-To: <20261113-mmu600-php-v1-0-231196049a3b@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 David Wu <david.wu@rock-chips.com>, Damien Le Moal <dlemoal@kernel.org>, 
 Niklas Cassel <cassel@kernel.org>, Serge Semin <fancer.lancer@gmail.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-ide@vger.kernel.org, 
 Pranjal Shrivastava <praan@google.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, iommu@lists.linux.dev, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794587927; l=768;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=isSOzqim4au9wHe7ayRhl/SLN2i9x9Bd32HMuVeTIQM=;
 b=f6Y3AcMeSBLf/zykfhiJs5LybaevPurozLoFXlFNqhejoU33A3G1MjYQNWi1Mb5O1U8Ymvg19
 B/YuuGiVKViCq0yib6lm2auaQC3rhJ4p7/Hv04UMNTk54hvSQsIEhip
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3588 SATA controllers are behind the PHP SMMU. Allow iommus, as
snps,dwc-ahci does.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 Documentation/devicetree/bindings/ata/rockchip,dwc-ahci.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/ata/rockchip,dwc-ahci.yaml b/Documentation/devicetree/bindings/ata/rockchip,dwc-ahci.yaml
index b5ecaabfe2e2..e33e8b5591ee 100644
--- a/Documentation/devicetree/bindings/ata/rockchip,dwc-ahci.yaml
+++ b/Documentation/devicetree/bindings/ata/rockchip,dwc-ahci.yaml
@@ -34,6 +34,9 @@ properties:
           - rockchip,rk3588-dwc-ahci
       - const: snps,dwc-ahci
 
+  iommus:
+    maxItems: 1
+
   ports-implemented:
     const: 1
 

-- 
2.55.0

