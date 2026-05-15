From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 15 May 2026 15:35:27 -0500
Subject: [PATCH 1/3] spi: dt-bindings: tegra: Support IOMMU property for
 Tegra194 QSPI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-tegra194-qspi-iommu-v1-1-57dfb63cd3d6@gmail.com>
References: <20260515-tegra194-qspi-iommu-v1-0-57dfb63cd3d6@gmail.com>
In-Reply-To: <20260515-tegra194-qspi-iommu-v1-0-57dfb63cd3d6@gmail.com>
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Thierry Reding <thierry.reding@gmail.com>, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778877338; l=874;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=Ctj0vZsUccyi2YsBh7ZigPaDzSk51BPiMWEp4e5pg7E=;
 b=ETf8WHKvOVF54Tby8QTiO3pg3xFXtE0sSvz3/FUu76xcn4Z8AsBBghTdraxufAwXpLT7mPe5+
 wbsgXEVb4pRBNfEbhq7ojKO8P1H0my5U+5/vLXBp/EMMdSJ/SZjma+P
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is supported via an external dma controller

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/spi/nvidia,tegra210-quad.yaml | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/spi/nvidia,tegra210-quad.yaml b/Documentation/devicetree/bindings/spi/nvidia,tegra210-quad.yaml
index 909c204b8adf81..62233eb3101aeb 100644
--- a/Documentation/devicetree/bindings/spi/nvidia,tegra210-quad.yaml
+++ b/Documentation/devicetree/bindings/spi/nvidia,tegra210-quad.yaml
@@ -78,7 +78,9 @@ allOf:
         compatible:
           not:
             contains:
-              const: nvidia,tegra234-qspi
+              enum:
+                - nvidia,tegra194-qspi
+                - nvidia,tegra234-qspi
     then:
       properties:
         iommus: false

-- 
2.53.0

