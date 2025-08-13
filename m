From: Janne Grunau <j@jannau.net>
Subject: [PATCH 0/5] Apple device tree sync from downstream kernel
Date: Wed, 13 Aug 2025 11:53:32 +0200
Message-Id: <20250813-apple-dt-sync-6-17-v1-0-209f15d10aa0@jannau.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJxgnGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDC0Nj3cSCgpxU3ZQS3eLKvGRdM11Dc90Uw7Rkw2QLyzTz5EQloMaCotS
 0zAqwodGxtbUAsOexiGQAAAA=
X-Change-ID: 20250813-apple-dt-sync-6-17-d1fc1c89f7ca
To: Sven Peter <sven@kernel.org>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mark Kettenis <kettenis@openbsd.org>, 
 Hector Martin <marcan@marcan.st>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2447; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=eiXrLuhR4xCamhoxoYxrnKpTHf3dzkLdi7yUfznol88=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhow5CWsePjDbkaGoumtOfrJAVFj2+dDzsUq7k1yFmWomB
 rzTN23sKGVhEONikBVTZEnSftnBsLpGMab2QRjMHFYmkCEMXJwCMJGtlgz/M1h7Y6/v4L+x4oP/
 RI4ntz55uvg3i6pPmO72bOd1h52eTgz/VJgv6D9JzLx50DnkkeJZ9vf8Vu/jO3dbafPaf9vWvuE
 GLwA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series pulls changes from the downstream device trees which are
supported in upstream kernel.
Most importantly it fixes the PCIe description for a specific iMac model
(iMac M1, 2 USB-C ports, 2021). This is worked around in the downstream
kernel by not disabling the port. In preparation for submitting M2
Pro/Max/Ultra devices trees I investigated the issue on the similarly
affected M2 Pro Mac mini and fixed it this way.
It completes the Wlan/BT device nodes for t600x based devices and adds
the missing 15-inch Macbook Air (M2, 2023).

Checkpatch emits following warnings:

WARNING: DT compatible string vendor "pci14e4" appears un-documented --
check ./Documentation/devicetree/bindings/vendor-prefixes.yaml

Which I chose to ignore. `vendor-prefixes.yaml` prefixes contains no
other mapping for PCI vendor code and the list of ignored prefixes
forbids extending it. Both options feel wrong though. "pci${vendor}" is
clearly a vendor prefix but duplicating the PCI vendor data base feels
wrong. `vendor-prefixes.yaml` currently does not contain and PCI vendor
aliases.

Signed-off-by: Janne Grunau <j@jannau.net>
---
Hector Martin (2):
      arm64: dts: apple: t600x: Comple WiFi properties
      arm64: dts: apple: t600x: Add bluetooth device nodes

Janne Grunau (3):
      arm64: dts: apple: t8103-j457: Fix PCIe ethernet iommu-map
      dt-bindings: arm: apple: Add t8112 j415 compatible
      arm64: dts: apple: Add devicetreee for t8112-j415

 Documentation/devicetree/bindings/arm/apple.yaml |  2 +
 arch/arm64/boot/dts/apple/Makefile               |  1 +
 arch/arm64/boot/dts/apple/t6000-j314s.dts        |  8 +++
 arch/arm64/boot/dts/apple/t6000-j316s.dts        |  8 +++
 arch/arm64/boot/dts/apple/t6001-j314c.dts        |  8 +++
 arch/arm64/boot/dts/apple/t6001-j316c.dts        |  8 +++
 arch/arm64/boot/dts/apple/t6001-j375c.dts        |  8 +++
 arch/arm64/boot/dts/apple/t6002-j375d.dts        |  8 +++
 arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi   | 10 +++
 arch/arm64/boot/dts/apple/t600x-j375.dtsi        | 10 +++
 arch/arm64/boot/dts/apple/t8103-j457.dts         | 12 +++-
 arch/arm64/boot/dts/apple/t8112-j415.dts         | 80 ++++++++++++++++++++++++
 12 files changed, 161 insertions(+), 2 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250813-apple-dt-sync-6-17-d1fc1c89f7ca

Best regards,
-- 
Janne Grunau <j@jannau.net>

