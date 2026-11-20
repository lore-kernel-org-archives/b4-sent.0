From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v3 0/2] arm64: dts: allwinner: orangepi-zero2/zero3: Read
 the SPI NOR over two lines
Date: Fri, 20 Nov 2026 06:30:07 +0000
Message-Id: <20261120-zero2-spi-nor-dual-read-v3-0-1cbb0caaed91@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XPTW6DMBAF4KsgrzuVbRiws+o9qi78MwRXCSY2o
 LYRd69DssgmyyfNfG/myjKlQJkdqitLtIYc4lhC/VYxN5jxSBB8yUxy2QohEP4oRQl5CjDGBH4
 xJ0hkPLQNmtaTRFKCle0pUR9+dvnz657zYr/JzTfuMZHospTK+T7GJjO7oRQeKqmsaJDrzvNeo
 Sa0XnbWOeRSea4F9rU1jfXsRg8hzzH97j+sYpce56qX564CBFjnne07hZb4x/FswundxfNurvL
 Z0a8dCRyEQqc63iLV+tnZtu0fJM5pAmEBAAA=
X-Change-ID: 20261115-zero2-spi-nor-dual-read-645a6de25e81
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: Andre Przywara <andre.przywara@arm.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795156207; l=2063;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=TbezzXnMhGFtPtXyzkhDKAuplra+gjD4n+VzAJSqXBY=;
 b=y4xQhOYT0fd7FkbqvjjxEuvNHMYfcJJYHOVEN9DSjUQzLlKWclQbSGmDywej7kWEbWNHUuEOT
 mYejXy/io01BbI1yB/kRaFxCJt9dabk3SOd7C3Mbdh1sH6mD3imFJ7J
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Andre Przywara reviewed v1 and suggested labelling the flash node (patch
1) and setting spi-rx-bus-width in the dtsi shared with the Zero3 (patch 2).

spi-rx-bus-width = <2> needs the binding patch of [1] (acked, not applied
yet) to pass dtbs_check.
Without the driver patch of [1] the driver ignores the setting.

Tested on an Orange Pi Zero2, with [1]: 1-1-2 reads (opcode 0x3b),
two 2 MiB reads identical to an earlier dump.

[1] https://lore.kernel.org/r/20261116-spi-sun6i-h616-dual-read-v2-0-e0c66eb71e20@gmail.com

Developed with Claude (Anthropic), which wrote the patches and commit
messages. I reviewed them.

---
Changes in v3:
- Label renamed to spi_flash (Andre)
- Zero3 flash supply added (Andre): reg_dldo1, see the note in patch 1
- Zero2 &spi_flash moved after &pio (sorted)
- Dropped Suggested-by on patch 2, added Andre's tags
- Link to v2: https://patch.msgid.link/20261119-zero2-spi-nor-dual-read-v2-0-185c87065e39@gmail.com

Changes in v2:
- Label the flash node, no nested &spi0 override (Andre)
- spi-rx-bus-width moved to the shared dtsi, Zero3 included (Andre;
  he read 16 MB on a Zero3 in 1.8 s instead of 3.5 s)
- Dropped the driver dependency (Andre); the binding is still needed for dtbs_check
- Link to v1: https://patch.msgid.link/20261118-zero2-spi-nor-dual-read-v1-1-bcdcbf785be0@gmail.com

---
Arun Iyengar (2):
      arm64: dts: allwinner: orangepi-zero2/zero3: Set the SPI NOR supply by label
      arm64: dts: allwinner: orangepi-zero2/zero3: Read the SPI NOR over two lines

 arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi | 3 ++-
 arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts | 6 ++----
 arch/arm64/boot/dts/allwinner/sun50i-h618-orangepi-zero3.dts | 4 ++++
 3 files changed, 8 insertions(+), 5 deletions(-)
---
base-commit: 90e0d3fd460ec365617982b56bd7ea5179b36197
change-id: 20261115-zero2-spi-nor-dual-read-645a6de25e81
prerequisite-patch-id: 28b145097d0f859e5bd27bcc5028d0915f3ba4bd

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

