From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Mon, 16 Nov 2026 05:55:25 +0000
Subject: [PATCH v2 1/2] spi: dt-bindings: sun6i: Allow Dual SPI and Quad
 SPI for the H616
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-spi-sun6i-h616-dual-read-v2-1-e0c66eb71e20@gmail.com>
References: <20261116-spi-sun6i-h616-dual-read-v2-0-e0c66eb71e20@gmail.com>
In-Reply-To: <20261116-spi-sun6i-h616-dual-read-v2-0-e0c66eb71e20@gmail.com>
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794808525; l=1092;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=J5fWkwwhvbIRdi/tKkf4w+0nyQr1DVDQbXeDAzQuqPQ=;
 b=svyeGoIzmzcktMV1ZQt0EBtPZ6VDtsuLr/LDWTdESX9RzfCqsv0ugB5a52NxpTCv0RN59pdrH
 kdVg5xaYFd5DVGcPPYnBEvgqoHqeay4U895LmnUpQLlsnD5UdBf0pjG
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The H616 SPI controllers support dual and quad transfers (H616 user
manual, SPI_BCC DRM and Quad_EN bits; only SPI0 has the WP/HOLD pins
for quad). Allow them, as commit 743956bb9990 ("spi: dt-bindings:
sun6i: Allow Dual SPI and Quad SPI for newer SoCs") did for the R329
and A523. The H616 keeps the H3 fallback.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 Documentation/devicetree/bindings/spi/allwinner,sun6i-a31-spi.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/spi/allwinner,sun6i-a31-spi.yaml b/Documentation/devicetree/bindings/spi/allwinner,sun6i-a31-spi.yaml
index 14c2f318dd04..116c5868415a 100644
--- a/Documentation/devicetree/bindings/spi/allwinner,sun6i-a31-spi.yaml
+++ b/Documentation/devicetree/bindings/spi/allwinner,sun6i-a31-spi.yaml
@@ -106,6 +106,7 @@ allOf:
           compatible:
             contains:
               enum:
+                - allwinner,sun50i-h616-spi
                 - allwinner,sun50i-r329-spi
                 - allwinner,sun55i-a523-spi
     then:

-- 
2.55.0

