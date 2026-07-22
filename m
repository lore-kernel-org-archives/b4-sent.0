From: Richard Leitner <richard.leitner@linux.dev>
Subject: [PATCH RFC 0/2] regmap: support firmware-described non-sequential
 register reads
Date: Wed, 22 Jul 2026 10:42:45 +0200
Message-Id: <20260722-regmap-single-read-v1-0-aaaf31591669@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIWCYGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcyMj3aLU9NzEAt3izLz0nFQgLzFFN9Eo1dLUwNwgOcXMTAmosaAoNS2
 zAmxotFKAY4izB0g0yM1ZKRYiW1yalJWaXAIyV6m2FgB4lBpjhAAAAA==
X-Change-ID: 20260722-regmap-single-read-a2e95070cd66
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>
Cc: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Alexander Stein <alexander.stein@ew.tq-group.com>, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 driver-core@lists.linux.dev, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784709824; l=2228;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=DA2LsH4Jd5MF1qG95I2J6cn2R2yPkQGy8WeIdsJjhic=;
 b=guJ+3eWoZ5JTS58AI7qGHphtRB9TwV90ZwgNwiEqKHH38a9Zaa7cQElFmFMbYS8H8fAu0E76l
 qXUs+brb7M9AGdsYKcvFsnZAVyTNYwTO9Va5+RXQoFcT0VUBMmVPMpQ
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

this series adds support for firmware/device-tree described constraints
on sequential register reads.

The motivating use case are camera modules from Vision Components.
These modules may integrate image sensors that normally support
incrementing multi-register reads, while the MCU (which sits basically
"between" the I2C host and the camera sensors) breaks them. In such
cases, single-register reads work, but sequential/bulk register reads do
not.

This limitation is therefore not a property of the sensor silicon
itself, but of the hardware module/integration in which the device is
used. As a result, it cannot be identified from the deivce driver and
handling it in each affected device driver does not scale well.

To address this, the series introduces a common firmware property
(no-sequential-read) describing hardware integrations where reading
multiple consecutive registers in a single operation is not reliable.
regmap then consumes that property and maps it to its existing
use_single_read configuration. This keeps the hardware constraint
described in firmware/device-tree while applying it in the layer that
already owns the register read transfer policy.

The initial discussion that motivated this approach can be found here:
https://lore.kernel.org/lkml/20260721151614.GN50424@killaraus.ideasonboard.com/

Feedback is especially welcome on the property naming, the placement of
the common binding schema, and if regmap is the best place to implment this.

Thanks,
Richard

Link: https://lore.kernel.org/lkml/20260721151614.GN50424@killaraus.ideasonboard.com/
Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
Richard Leitner (2):
      dt-bindings: regmap: add common schema for no-sequential-read
      regmap: implement no-sequential-read firmware property

 .../devicetree/bindings/regmap/common.yaml         | 26 ++++++++++++++++++++++
 drivers/base/regmap/regmap.c                       | 14 +++++++++++-
 2 files changed, 39 insertions(+), 1 deletion(-)
---
base-commit: 248951ddc14de84de3910f9b13f51491a8cd91df
change-id: 20260722-regmap-single-read-a2e95070cd66

Best regards,
--  
Richard Leitner <richard.leitner@linux.dev>

