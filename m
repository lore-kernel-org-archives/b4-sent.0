From: Sven Peter <sven@kernel.org>
Subject: [PATCH 0/3] Apple SoC CIO (USB4/Thunderbolt) reset controller
Date: Sun, 09 Aug 2026 14:16:01 +0200
Message-Id: <20260809-b4-cio-reset-v1-0-4f33777d9b4b@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw5EQBBG4VeRWk8l7RLBq0xm0d1+lAXShUjEu
 2tj+S3OOUkRBEpNclLALirzFJF+EvKDnXqwtNGUmaw0lanZFexl5gDFytbmnTOFs20NiskS0Mn
 x331/r3VzI/z6POi6bpQn5XNwAAAA
X-Change-ID: 20260809-b4-cio-reset-aa3fb04bad9e
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1677; i=sven@kernel.org;
 h=from:subject:message-id; bh=DsfiHmyqE8aSbXZkKzysnOzPgwXdCEsx/VkGP4SjgGY=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1ZFfnNE7VrLuzN3HSpcd7HbKeSfunzERAHGT7IqlUftb
 k2q2X+yo5SFQYyLQVZMkWX7fnvTJw/fCC7ddOk9zBxWJpAhDFycAjCR2bMZ/inFntr83liqw2Vz
 lcvuzVtPyOsfF9WeGTK/gs3hbJj060aGf3aC/m2r9k7aHmm35T5XvO4t0/VbyrKuCh17qXYgL8H
 pCQsA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

The CIO blocks used for USB4/Thunderbolt on Apple Silicon SoCs have a
reset inside the power manager that has to be deasserted before their
co-processor can be booted. On t8103 and t8112 each port comes with a
dedicated register page while t600x and t602x use a single register
with one request bit per port shared by all ports of a die in the
middle of the PMGR MMIO region.

The first patch adds the dt-binding, the second one the driver and the
last one the device tree nodes for all SoCs. This will be used by the
upcoming USB4/Thunderbolt series to start the host routers before
booting their co-processors.

Best,

Sven

---
Sven Peter (3):
      dt-bindings: reset: Add Apple SoC CIO reset
      reset: Add Apple SoC CIO reset driver
      arm64: dts: apple: Add CIO reset controllers

 .../devicetree/bindings/arm/apple/apple,pmgr.yaml  |   6 +
 .../bindings/reset/apple,t8103-cio-reset.yaml      |  74 +++++++++
 MAINTAINERS                                        |   2 +
 arch/arm64/boot/dts/apple/t600x-dieX.dtsi          |   8 +-
 arch/arm64/boot/dts/apple/t602x-dieX.dtsi          |   8 +-
 arch/arm64/boot/dts/apple/t8103.dtsi               |   6 +
 arch/arm64/boot/dts/apple/t8112.dtsi               |   6 +
 drivers/reset/Kconfig                              |  10 ++
 drivers/reset/Makefile                             |   1 +
 drivers/reset/reset-apple-cio.c                    | 182 +++++++++++++++++++++
 10 files changed, 301 insertions(+), 2 deletions(-)
---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260809-b4-cio-reset-aa3fb04bad9e

Best regards,
--  
Sven Peter <sven@kernel.org>

