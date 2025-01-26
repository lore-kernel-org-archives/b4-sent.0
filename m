From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/9] YAML conversion of several Freescale/PowerPC DT
 bindings
Date: Sun, 26 Jan 2025 19:58:55 +0100
Message-Id: <20250126-ppcyaml-v1-0-50649f51c3dd@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAO+FlmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDQyMz3YKC5MrE3BxdMwuD5OQUiyTjtGQjJaDqgqLUtMwKsEnRsbW1AIw
 prb9ZAAAA
X-Change-ID: 20250126-ppcyaml-680ccd8b3fc2
To: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org
Cc: Scott Wood <oss@buserror.net>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Damien Le Moal <dlemoal@kernel.org>, 
 Niklas Cassel <cassel@kernel.org>, Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Lee Jones <lee@kernel.org>, 
 Vinod Koul <vkoul@kernel.org>, Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.neuschaefer@gmx.net>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Mark Brown <broonie@kernel.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 linux-kernel@vger.kernel.org, linux-ide@vger.kernel.org, 
 linux-crypto@vger.kernel.org, dmaengine@vger.kernel.org, 
 linux-pci@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 linux-spi@vger.kernel.org, linux-mtd@lists.infradead.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737917943; l=2648;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=t7MiR81B+Iee46VXjw3fUJ5IYqT5cIbBOLroU8KM1fQ=;
 b=rX4cEDadyqjKuA8yYkLZevdyfcRaUdz4BHeJl10YNn4xTsKCjeCD6OKBl3O1tpdL5puknSF0r
 w3DGg25+T63CHz+RBokGYXZ8fMyOUHiLEo+aY9gwD/QBhE8TjlNwX8S
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a spin-off of the series titled
"powerpc: MPC83xx cleanup and LANCOM NWAPP2 board".

During the development of that series, it became clear that many
devicetree bindings for Freescale MPC8xxx platforms are still in the old
plain-text format, or don't exist at all, and in any case don't mention
all valid compatible strings.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (9):
      dt-bindings: powerpc: Add binding for Freescale/NXP MPC83xx SoCs
      dt-bindings: ata: Convert fsl,pq-sata binding to YAML
      dt-bindings: crypto: Convert fsl,sec-2.0 binding to YAML
      dt-bindings: mfd: Convert fsl,mcu-mpc8349emitx binding to YAML
      dt-bindings: dma: Convert fsl,elo*-dma bindings to YAML
      dt-bindings: pci: Add fsl,mpc83xx-pcie bindings
      dt-bindings: watchdog: Convert mpc8xxx-wdt binding to YAML
      dt-bindings: spi: Convert Freescale SPI bindings to YAML
      [RFC] dt-bindings: nand: Convert fsl,elbc bindings to YAML

 .../devicetree/bindings/ata/fsl,pq-sata.yaml       |  59 ++++++
 Documentation/devicetree/bindings/ata/fsl-sata.txt |  28 ---
 .../devicetree/bindings/crypto/fsl,sec2.0.yaml     | 139 ++++++++++++++
 .../devicetree/bindings/crypto/fsl-sec2.txt        |  65 -------
 .../devicetree/bindings/dma/fsl,elo-dma.yaml       | 129 +++++++++++++
 .../devicetree/bindings/dma/fsl,elo3-dma.yaml      | 105 +++++++++++
 .../devicetree/bindings/dma/fsl,eloplus-dma.yaml   | 120 ++++++++++++
 .../bindings/mfd/fsl,mcu-mpc8349emitx.yaml         |  53 ++++++
 .../devicetree/bindings/mtd/fsl,elbc-fcm-nand.yaml |  61 ++++++
 .../devicetree/bindings/pci/fsl,mpc8xxx-pci.yaml   |  83 +++++++++
 .../devicetree/bindings/powerpc/fsl/dma.txt        | 204 ---------------------
 .../bindings/powerpc/fsl/fsl,elbc-gpcm-uio.yaml    |  55 ++++++
 .../devicetree/bindings/powerpc/fsl/fsl,elbc.yaml  | 150 +++++++++++++++
 .../bindings/powerpc/fsl/fsl,mpc83xx.yaml          |  67 +++++++
 .../devicetree/bindings/powerpc/fsl/lbc.txt        |  43 -----
 .../bindings/powerpc/fsl/mcu-mpc8349emitx.txt      |  17 --
 .../devicetree/bindings/spi/fsl,espi.yaml          |  56 ++++++
 Documentation/devicetree/bindings/spi/fsl,spi.yaml |  71 +++++++
 Documentation/devicetree/bindings/spi/fsl-spi.txt  |  62 -------
 .../devicetree/bindings/watchdog/mpc8xxx-wdt.txt   |  25 ---
 .../devicetree/bindings/watchdog/mpc8xxx-wdt.yaml  |  64 +++++++
 21 files changed, 1212 insertions(+), 444 deletions(-)
---
base-commit: ffd294d346d185b70e28b1a28abe367bbfe53c04
change-id: 20250126-ppcyaml-680ccd8b3fc2

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

