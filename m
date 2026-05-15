From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 15 May 2026 15:35:28 -0500
Subject: [PATCH 2/3] spi: dt-bindings: tegra: Support dma-coherent property
 for QSPI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-tegra194-qspi-iommu-v1-2-57dfb63cd3d6@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778877338; l=743;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=m/PPegEGAyaU6wZWkIdDWHDa9uH5hiVYhCovCoKJA0Y=;
 b=/RnOs3EhWYLrIOMwj4LQr3tSmjiZ8qHJBwbDhpw4ZOm+ZZBuMm7/JVKaQ5NNnJ1gAnf7JJwEC
 5FVOPNVa/pzDEF726SKKer/rlKGsQDi3FM1+AtVICt8VxycNlLYfNYx
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DMA coherency is supported by at least the Tegra194 and Tegra234
controllers.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/spi/nvidia,tegra210-quad.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/spi/nvidia,tegra210-quad.yaml b/Documentation/devicetree/bindings/spi/nvidia,tegra210-quad.yaml
index 62233eb3101aeb..433bca02f86b13 100644
--- a/Documentation/devicetree/bindings/spi/nvidia,tegra210-quad.yaml
+++ b/Documentation/devicetree/bindings/spi/nvidia,tegra210-quad.yaml
@@ -47,6 +47,8 @@ properties:
   iommus:
     maxItems: 1
 
+  dma-coherent: true
+
 patternProperties:
   "@[0-9a-f]+$":
     type: object

-- 
2.53.0

