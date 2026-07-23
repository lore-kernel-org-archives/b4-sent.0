From: Vincent Jardin <vjardin@free.fr>
Subject: [PATCH 0/2] dpll: zl3073x: add Microchip ZL30643 support
Date: Fri, 24 Jul 2026 01:09:11 +0200
Message-Id: <20260724-for-upstream-zl30643-v1-0-ea93ba4d85c8@free.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABefYmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcyMT3bT8It3SguKSotTEXN2qHGMDMxNjXYskI2MjM/MkS3OTNCWg1oK
 i1LTMCrCx0bG1tQAMf9AAZgAAAA==
To: Ivan Vecera <ivecera@redhat.com>, 
 Prathosh Satish <Prathosh.Satish@microchip.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Vadim Fedorenko <vadim.fedorenko@linux.dev>, 
 Arkadiusz Kubalewski <arkadiusz.kubalewski@intel.com>, 
 Jiri Pirko <jiri@resnulli.us>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784848154; l=1025;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=p1gRB2PzlwcRqzmDrRYk7SlcM/ROTsU5ElkcPRvh02Q=;
 b=z5cIm8kz02Naw4qoK+Ply0iQLput0QY6Q7kNGR9pPAe7gSj9tcAuVItTh/KYOiH7Vqehfb804
 uUVJC+KzSr0BSZCQE7e5ch65EuhKH7E9wFxuMMyhtvZYlBB5u5vPUby
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Microchip ZL30643 (chip ID 0x0E3B) is a 3 DPLL channel member
of the ZL3073x family.

Patch 1 adds the binding.
Patch 2 registers the chip in the driver: the chip-info table and the
I2C, SPI and OF device-ID match tables.

It was tested on an LX2160A board with a ZL30733 and a ZL30643, both
are probed and they expose their DPLL channels.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Vincent Jardin (2):
      dt-bindings: dpll: zl3073x: add ZL30643 compatible
      dpll: zl3073x: add ZL30643 chip support

 Documentation/devicetree/bindings/dpll/microchip,zl30731.yaml | 1 +
 drivers/dpll/zl3073x/core.c                                   | 1 +
 drivers/dpll/zl3073x/i2c.c                                    | 2 ++
 drivers/dpll/zl3073x/spi.c                                    | 2 ++
 4 files changed, 6 insertions(+)
---
base-commit: 248951ddc14de84de3910f9b13f51491a8cd91df
change-id: 20260724-for-upstream-zl30643-8b23267b974f

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

