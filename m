From: Daniel Drake <dan@reactivated.net>
Date: Sun, 27 Sep 2026 14:09:02 +0100
Subject: [PATCH v7 3/6] dt-bindings: display: brcm,bcm2835-hvs: Document
 iommus property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260927-bcm2712-iommu-submit-v7-3-dfa2b975cbc9@reactivated.net>
References: <20260927-bcm2712-iommu-submit-v7-0-dfa2b975cbc9@reactivated.net>
In-Reply-To: <20260927-bcm2712-iommu-submit-v7-0-dfa2b975cbc9@reactivated.net>
To: "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>, 
 Daniel Drake <dan@reactivated.net>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-rpi-kernel@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, nick.hollinghurst@raspberrypi.com, 
 james.quinlan@broadcom.com, Jason Gunthorpe <jgg@ziepe.ca>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=914; i=dan@reactivated.net;
 h=from:subject:message-id; bh=jvJtzPewMxeDZpE90O4lOLjfTo2HtXAHbTAGkD5tWH0=;
 b=owEBbQKS/ZANAwAKAcPmj7FTFEe7AcsmYgBquRWEkcJdsNIqcX6vaW1rQNFgVdhf6QsR8c3Sj
 KJCQ6/02dyJAjMEAAEKAB0WIQQ6Rf0sUP1iEhXfVfjD5o+xUxRHuwUCarkVhAAKCRDD5o+xUxRH
 u1/zD/9yzR0tMdVnQFUov9zJvP4J1F0UT7anXVClYkLytUL1oL/htyvpcPApxhQQ/Ai0sN51GQI
 JRpfyCItHz1PypKQGNfrvKWVg39fGGMMJpaYIfiERtaXHYD/rp2XiPPpjfp5N+QDS66UN16TjfL
 9kzNW5Ap51sD3ysqJvYmf/z/1LfLgv2H7z39x5sZy25+l5MPWaGiJjUFEajiovxFQRqeAZZ5UIx
 SSu955o1VwTjbzYgU4oAD5NdvQ9UiyhLIBV8lRSzuezVznLtKhRYO7bQiUVr1oAjf9mfPcWE3t+
 rW8xXN0wrh3PyKG8WFvuO+x7Yg2eYOpr+4pQU+aBD+Q1Vc0wxVS2bOdPg6jEWCdxvYlbWsPQmgL
 3JPjun3puwVAu5ytD/yF1uLgenJswWymM5q7ZjtievXk+W27ETu1AdZ1ZZt96apfuXy4V1juX38
 TN6oddMc28hBa1uw3IoYGqG4F4WaGAwLI23jWDsY8i2BFyjfSlpkB7GW7pVBznq/UP2rCKddAWG
 S3CfOUoIDIXRMBoHq+mVES/JqGC828Z74vsMvU8K+L5eRgQ2wp7XCpsKbxPPYtRak6ju70twY1u
 YENtf0k0qB/D4wt8C15XybD3Ocl0nZ+Tj4f5JEwnBde2CZ2nlZsu3bjwikcUtY+QX4rqinGKb7B
 qZE7pYYsvrVnKvA==
X-Developer-Key: i=dan@reactivated.net; a=openpgp;
 fpr=3A45FD2C50FD621215DF55F8C3E68FB1531447BB
X-Endpoint-Received: by B4 Relay for dan@reactivated.net/default with auth_id=1070
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On BCM2712, the Hardware Video Scaler (HVS) is connected behind an IOMMU.
Add the optional iommus property to allow describing this connection.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Reviewed-by: Florian Fainelli <florian.fainelli@broadcom.com>
Signed-off-by: Daniel Drake <dan@reactivated.net>
---
 Documentation/devicetree/bindings/display/brcm,bcm2835-hvs.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/brcm,bcm2835-hvs.yaml b/Documentation/devicetree/bindings/display/brcm,bcm2835-hvs.yaml
index 9aca38a58a16..8f8aae9f3788 100644
--- a/Documentation/devicetree/bindings/display/brcm,bcm2835-hvs.yaml
+++ b/Documentation/devicetree/bindings/display/brcm,bcm2835-hvs.yaml
@@ -35,6 +35,9 @@ properties:
     minItems: 1
     maxItems: 2
 
+  iommus:
+    maxItems: 1
+
 required:
   - compatible
   - reg

-- 
2.55.0

