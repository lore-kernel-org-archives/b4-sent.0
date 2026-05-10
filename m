From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Subject: [PATCH 0/2] iio: light: Add ROHM BH1730FVC ambient light sensor
 driver
Date: Mon, 11 May 2026 01:09:48 +0700
Message-Id: <20260511-bh1730-v1-0-e0df1f499135@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDU0ND3aQMQ3NjA13DVGMDo8TklESTNAsloOKCotS0zAqwQdGxEH5xaVJ
 WanIJSLdSbS0ATs9lY2oAAAA=
X-Change-ID: 20260511-bh1730-1e302acda4f8
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, CTCaer <ctcaer@gmail.com>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778436589; l=893;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=sO5H5/4GTewuYdeypxz3gvRPdcqIT9yN7wjzCLN20jw=;
 b=BJWxJxe+zIelIrHIX4g6mTxIbq/y8NB14mgZF1iBJYaXrIEgMBrZbKHS78BePuOsfVB3D/zEa
 IY6p1kT98CTAGHMoY313GgHlh1PP3gpkjCsUvWrqq6IyeVB5NacNdYm
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a driver and devicetree binding for the ROHM BH1730FVC ambient
light sensor. This sensor is found on the Nintendo Switch console,
where it is used by the system for automatic display brightness
adjustment.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
CTCaer (2):
      dt-bindings: iio: light: Add ROHM BH1730FVC binding
      iio: light: bh1730: Add bh1730 light sensor driver

 .../bindings/iio/light/rohm,bh1730fvc.yaml         |  95 +++
 drivers/iio/light/Kconfig                          |   9 +
 drivers/iio/light/Makefile                         |   1 +
 drivers/iio/light/bh1730.c                         | 686 +++++++++++++++++++++
 4 files changed, 791 insertions(+)
---
base-commit: e98d21c170b01ddef366f023bbfcf6b31509fa83
change-id: 20260511-bh1730-1e302acda4f8

Best regards,
--  
Alexandre Hamamdjian <azkali.limited@gmail.com>

