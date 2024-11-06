From: Janne Grunau <j@jannau.net>
Subject: [PATCH v5 0/3] Apple SPI controller driver
Date: Wed, 06 Nov 2024 08:53:59 +0100
Message-Id: <20241106-asahi-spi-v5-0-e81a4f3a8e19@jannau.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJcgK2cC/3XMTQ7CIBCG4as0rMXwK+DKexgX0wIWF7SBSjRN7
 y7tqsa4/CbzvDPKLgWX0bmZUXIl5DDEOuShQV0P8e5wsHUjRpggmlIMGfqA8xiw10qQFpRRVqH
 6Pybnw2trXW919yFPQ3pv6cLW61ahlOwrhWGC1YmDBi2s5uLygBjheYxuQmum8L+UV8rbeu6kb
 7WTP1TsqdxTUak1igtPtPGd+aLLsnwAY7dM+hkBAAA=
X-Change-ID: 20240811-asahi-spi-f8740ba797d7
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Janne Grunau <j@jannau.net>, 
 Nick Chan <towinchenmi@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3507; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=eMru1U320VfLOEr90ChBn78/932lYaJiS4lfyxZ+a6E=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhnRthfVb+H/8fi5RsvCV/NTtJStm/uJeLea+SVGV/XrSt
 hsTzCfN6ChlYRDjYpAVU2RJ0n7ZwbC6RjGm9kEYzBxWJpAhDFycAjCRe2EMv1l25t6db/GY/aOn
 gVm/QavywfUlex72HuddsULbsrWKM4fhr7Sz7YPsQ+s+bMhadjzsapdv1InuFaLGajy8hX1Mhht
 /8wEA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

This updated series address the review comments from the original
submission in 2021 [1]. It adds a new SPI controller driver for Apple
SoCs and is based on spi-sifive. It has been tested with the generic
jedec,spi-nor support and with a downstream driver for an Apple specific
HID over SPI transport.

As usual, I'm splitting off the MAINTAINERS and DT binding changes.
We would rather merge the MAINTAINERS change through the Asahi-SoC
tree to avoid merge conflicts as things trickle upstream, since
we have other submissions touching that section of the file.

The DT binding change can go via the SPI tree or via ours, but it's
easier if we merge it, as then we can make the DT changes to
instantiate it without worrying about DT validation failures depending
on merge order.

This is mostly Hector's work with a few minor changes to address review
comments from me.

[1] https://lore.kernel.org/linux-spi/20211212034726.26306-1-marcan@marcan.st/

v2:
- removed '#address-cells' and '#size-cells' from the bindings and added
  Rob's Rb:
- fixed (new) checkpatch warnings
- added t8112 (M2) SoC
- shorted long and complex source code lines
- switch to devm_clk_prepare_enable() and devm_pm_runtime_enable()
- switch to dev_err_probe() in probe function
- removed "pdev->dev.dma_mask = NULL;"
- got rid of apple_spi_remove()

Signed-off-by: Janne Grunau <j@jannau.net>
---
Changes in v5:
- use devm_spi_alloc_host()
- switch bindings commit msg prefix to "spi: dt-bindings:"
- Link to v4: https://lore.kernel.org/r/20241105-asahi-spi-v4-0-d9734f089fc9@jannau.net

Changes in v4:
- removed the label from example in the bindings
- really added Rob's Rb: for the bindings added Reviewed/Acked-by: for v3
- alphabetically sorted #includes
- removed leftover platform_set_drvdata
- Link to v3: https://lore.kernel.org/r/20241101-asahi-spi-v3-0-3b411c5fb8e5@jannau.net

Changes in v3:
- fixed bindings_check warning
- converted top file comment to C++ style comments
- dropped verbose dev_err_probe after failed devm_* function
- stopped setting field in zero initialized struct to 0
- added error handling for devm_pm_runtime_enable()
- Link to v2: https://lore.kernel.org/r/20241101-asahi-spi-v2-0-763a8a84d834@jannau.net

Changes in v2:
- removed '#address-cells' and '#size-cells' from the bindings and added
  Rob's Rb:
- fixed (new) checkpatch warnings
- added t8112 (M2) SoC
- shorted long and complex source code lines
- switch to devm_clk_prepare_enable() and devm_pm_runtime_enable()
- switch to dev_err_probe() in probe function
- removed "pdev->dev.dma_mask = NULL;"
- got rid of apple_spi_remove()
- Link to v1: https://lore.kernel.org/linux-spi/20211212034726.26306-1-marcan@marcan.st/

---
Hector Martin (3):
      spi: dt-bindings: apple,spi: Add binding for Apple SPI controllers
      spi: apple: Add driver for Apple SPI controller
      MAINTAINERS: Add apple-spi driver & binding files

 .../devicetree/bindings/spi/apple,spi.yaml         |  62 +++
 MAINTAINERS                                        |   2 +
 drivers/spi/Kconfig                                |  11 +
 drivers/spi/Makefile                               |   1 +
 drivers/spi/spi-apple.c                            | 530 +++++++++++++++++++++
 5 files changed, 606 insertions(+)
---
base-commit: 98f7e32f20d28ec452afb208f9cffc08448a2652
change-id: 20240811-asahi-spi-f8740ba797d7

Best regards,
-- 
Janne Grunau <j@jannau.net>

