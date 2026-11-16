From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/2] spi: sun6i: Add dual read support for the H616
Date: Mon, 16 Nov 2026 05:55:24 +0000
Message-Id: <20261116-spi-sun6i-h616-dual-read-v2-0-e0c66eb71e20@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NTQ6CMBBGr2Jm7RimQgFX3sOwKO0IY/hLC0RDu
 LuAF3D5kve9b4HAXjjA7bSA51mC9N0G6nwCW5uuYhS3MahIaSKKMAyCYeq0YK1Jo5tMg56Nw0S
 rLL6WVkUuhW0+eH7K+0g/ih+HqXyxHffebtQSxt5/ju+Zdu+Pm5mQMMlLNonJ8tTF96o10lxs3
 0KxrusX0+eYvNIAAAA=
X-Change-ID: 20261110-spi-sun6i-h616-dual-read-562843bc20d7
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
 bh=UssfpM7cd+H4kc8EHiRkjSsNRV0nMySWvKuNCOar8aA=;
 b=o5ph33NBY6zwlbrocmmsY0IBnv4A6gM+ObeF3Ij4Gp9qQz1zhrlub2WBcQ5PeiSs4KN1Ggjua
 2LE1xbAy6sxAR2CVDTtALy60W/bX02Uf91CMzceFv51cDSE6QG41iCR
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The H616 SPI controllers support dual and quad transfers but bind
through the H3 fallback. Patch 1 lets the binding allow those bus
widths for the H616, patch 2 enables dual reads in the driver.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed them and tested on an Orange Pi Zero2.

---
Changes in v2:
- New patch 1: the binding update Mark Brown asked for
- Patch 2: shorter commit message, no code change
- Link to v1: https://patch.msgid.link/20261110-spi-sun6i-h616-dual-read-v1-1-59bea5a897d4@gmail.com

---
Arun Iyengar (2):
      spi: dt-bindings: sun6i: Allow Dual SPI and Quad SPI for the H616
      spi: sun6i: Add dual read support for the H616

 Documentation/devicetree/bindings/spi/allwinner,sun6i-a31-spi.yaml | 1 +
 drivers/spi/spi-sun6i.c                                            | 7 +++++++
 2 files changed, 8 insertions(+)
---
base-commit: 7a043c9d31af627f0689757b29b8aad6155a9376
change-id: 20261110-spi-sun6i-h616-dual-read-562843bc20d7

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

