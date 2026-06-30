From: Michael Reeves <michael.reeves077@gmail.com>
Date: Tue, 30 Jun 2026 22:54:31 +1000
Subject: [PATCH 03/10] dt-bindings: iommu: apple,dart: Add t8122 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260630-apple-mtp-keyboard-final-v1-3-506d936a1707@gmail.com>
References: <20260630-apple-mtp-keyboard-final-v1-0-506d936a1707@gmail.com>
In-Reply-To: <20260630-apple-mtp-keyboard-final-v1-0-506d936a1707@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Jassi Brar <jassisinghbrar@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hector Martin <marcan@marcan.st>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 iommu@lists.linux.dev, linux-input@vger.kernel.org, 
 Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782824083; l=963;
 i=michael.reeves077@gmail.com; s=20260105; h=from:subject:message-id;
 bh=y5JWfMxBJX2xwts+wGq01XJ6a6fA14G/VbJw916yMm0=;
 b=5iqh2NsfbrvbnnFMBUjNQ9JMWqmwkDS68TKoS3s6ZKyEuN8ohJJ4u5+rkTGBiNHhfR+95Ekiq
 ojKHCJikfWADnyTu62aZ30rMoFM5bYbdIPtKbGM4A7trN7HTSRd2pBQ
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=QIrgWBGCm3LG0YYc6MLCDkwuVXLTGGooVBdWX/KhSiU=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20260105 with auth_id=591
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MTP block on t8122 has its own DART instance for coprocessor DMA.

Document the t8122 compatible with the existing t8110 fallback because
the programming model is shared.

Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 Documentation/devicetree/bindings/iommu/apple,dart.yaml | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/iommu/apple,dart.yaml b/Documentation/devicetree/bindings/iommu/apple,dart.yaml
index 47ec7fa52c3a..e179199dbd3b 100644
--- a/Documentation/devicetree/bindings/iommu/apple,dart.yaml
+++ b/Documentation/devicetree/bindings/iommu/apple,dart.yaml
@@ -29,7 +29,9 @@ properties:
           - apple,t8110-dart
           - apple,t6000-dart
       - items:
-          - const: apple,t6020-dart
+          - enum:
+              - apple,t6020-dart
+              - apple,t8122-dart
           - const: apple,t8110-dart
 
   reg:

-- 
2.51.2

