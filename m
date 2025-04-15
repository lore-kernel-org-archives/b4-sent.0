From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH 0/3] Generic SPMI NVMEM cell driver
Date: Tue, 15 Apr 2025 23:52:33 +0200
Message-Id: <20250415-spmi-nvmem-v1-0-22067be253cf@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACLV/mcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDE0NT3eKC3EzdvLLc1FzdVAMLM2NTY0MzQ3NTJaCGgqLUtMwKsGHRsbW
 1ABuu0b9cAAAA
X-Change-ID: 20250415-spmi-nvmem-e08635316175
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Neal Gompa <neal@gompa.dev>, 
 Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744753962; l=1432;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=jBNCv2rda4YJZMZlnqUFKXhD2YixBW/bajeGa6Tnahg=;
 b=z/bozObO8yi+GVG8sufEa3NcrtwV6CqAU6PzOgE14u6VKIBZuU8qylsUv97vpKOw9XrAYnnts
 RA/RVyk+lJwCJ3/TPasI9fumkGl32BPZfim4W4o7J+IHeyGvfsrR/2T
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This patch series adds a driver for exposing a set of SPMI registers
as NVMEM cells. This is used on Apple ARM platforms to store the RTC
offset and to communicate platform power state between the OS and
boot firmware.

The NVMEM cell consumer drivers will be sent in a further series.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
Hector Martin (2):
      nvmem: Add spmi-nvmem driver
      arm64: dts: apple: Add PMU NVMEM

Sasha Finkelstein (1):
      dt-bindings: spmi: Add generic SPMI NVMEM

 .../devicetree/bindings/nvmem/spmi-nvmem.yaml      | 44 +++++++++++++++
 MAINTAINERS                                        |  2 +
 arch/arm64/boot/dts/apple/t6001.dtsi               |  1 +
 arch/arm64/boot/dts/apple/t6002.dtsi               |  1 +
 arch/arm64/boot/dts/apple/t600x-die0.dtsi          | 50 +++++++++++++++++
 arch/arm64/boot/dts/apple/t8103.dtsi               | 50 +++++++++++++++++
 arch/arm64/boot/dts/apple/t8112.dtsi               | 50 +++++++++++++++++
 drivers/nvmem/Kconfig                              | 14 +++++
 drivers/nvmem/Makefile                             |  2 +
 drivers/nvmem/spmi-nvmem.c                         | 62 ++++++++++++++++++++++
 10 files changed, 276 insertions(+)
---
base-commit: 2e0e70c95077172b29a5b13716c4b159d578e82c
change-id: 20250415-spmi-nvmem-e08635316175

Best regards,
-- 
Sasha Finkelstein <fnkl.kernel@gmail.com>

