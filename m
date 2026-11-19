From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/2] arm64: dts: allwinner: orangepi-zero2/zero3: Read
 the SPI NOR over two lines
Date: Thu, 19 Nov 2026 05:29:33 +0000
Message-Id: <20261119-zero2-spi-nor-dual-read-v2-0-185c87065e39@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WPQW7CMBBFr4JmzVS2GycOK+5RsbA9E2IEcbCTq
 C3K3WsC2y6f9Of9Pw/InAJnOOwekHgJOcShgNrvwPd2ODMGKgxKqFpKqfGXU1SYx4BDTEizvWJ
 iS1hX2tbESrORUK7HxF343sxfpxfn2V3YT0/dO5H4PpfK6RWD0U6+L4Wl3zhZadE2JDqjW9aOV
 OO810IZEq3U3aezlSN4qvuQp5h+th8WuZnec82/cxeJEp0n77rGaMfieL7ZcP3w8QandV3/AFC
 vskkZAQAA
X-Change-ID: 20261115-zero2-spi-nor-dual-read-645a6de25e81
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: Andre Przywara <andre.przywara@arm.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795066173; l=1665;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=dSUlrtuj/XZo8LVxmrqcGVmatGiczTvRbXzsTOXBhPM=;
 b=p6DGgixcbBrVaXI7ubEA+MhLxvzD4Dcd9aRiJTYGBG7qLklgmmtb9PJolIxZuNYvkR4bst+X4
 fdvV+6DSPb4DvykJXBJKX7CCREZBaoG/ELg1mT5uhdZUjIAe9pTTaem
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Andre Przywara reviewed v1 and suggested labelling the flash node (patch
1) and setting spi-rx-bus-width in the dtsi shared with the Zero3 (patch 2).

spi-rx-bus-width = <2> needs the binding patch of [1] (acked, not applied
yet) to pass dtbs_check.
Without the driver patch of [1] the driver ignores the setting.

Tested on an Orange Pi Zero2 only, with [1]: 1-1-2 reads (opcode 0x3b),
two 2 MiB reads identical to an earlier dump.

[1] https://lore.kernel.org/r/20261116-spi-sun6i-h616-dual-read-v2-0-e0c66eb71e20@gmail.com

Developed with Claude (Anthropic), which wrote the patches and commit
messages. I reviewed them.

---
Changes in v2:
- Label the flash node, no nested &spi0 override (Andre)
- spi-rx-bus-width moved to the shared dtsi, Zero3 included (Andre;
  he read 16 MB on a Zero3 in 1.8 s instead of 3.5 s)
- Dropped the driver dependency (Andre); the binding is still needed for dtbs_check
- Link to v1: https://patch.msgid.link/20261118-zero2-spi-nor-dual-read-v1-1-bcdcbf785be0@gmail.com

---
Arun Iyengar (2):
      arm64: dts: allwinner: orangepi-zero2: Reference the SPI NOR by label
      arm64: dts: allwinner: orangepi-zero2/zero3: Read the SPI NOR over two lines

 arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero.dtsi |  3 ++-
 arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts | 10 ++++------
 2 files changed, 6 insertions(+), 7 deletions(-)
---
base-commit: 90e0d3fd460ec365617982b56bd7ea5179b36197
change-id: 20261115-zero2-spi-nor-dual-read-645a6de25e81
prerequisite-patch-id: 28b145097d0f859e5bd27bcc5028d0915f3ba4bd

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

