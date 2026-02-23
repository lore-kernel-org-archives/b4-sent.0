From: Marc Paolo Sosa <marcpaolo.sosa@analog.com>
Subject: [PATCH 0/2] add driver for max16150
Date: Mon, 23 Feb 2026 19:03:38 +0800
Message-Id: <20260223-max16150-v1-0-38e2a4f0d0f1@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAo0nGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDIyNj3dzECkMzQ1MDXYvUNEuTVDMT4+QUAyWg8oKi1LTMCrBR0bG1tQD
 RFD5dWgAAAA==
X-Change-ID: 20260223-max16150-8ef94e643cd0
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Marc Paolo Sosa <marcpaolo.sosa@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771844627; l=1100;
 i=marcpaolo.sosa@analog.com; s=20260223; h=from:subject:message-id;
 bh=/Lwi2SQOmjSZoQ2lD1J/F6NVtGfgvtYG1FZkkyq+TAA=;
 b=o3wekkboUVy8NBZSvp/U6yVbN8moHRJrRb8NnTDV8XQ0Oywr77RoE5H4oqQLufr06GLhqpII+
 98yT4xjK/R2DpYIvYGCXGHtLcQRiOzRawl2DaXhmEH7x6l320NiIwzY
X-Developer-Key: i=marcpaolo.sosa@analog.com; a=ed25519;
 pk=RR72PZYRimO/84huVqlVyHN3IM3AL984DRKCEXnOJuE=
X-Endpoint-Received: by B4 Relay for marcpaolo.sosa@analog.com/20260223 with auth_id=646
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce pushbutton control and debouncing support for the
MAX16150/MAX16169. The component is a low‑power on/off controller
featuring an integrated switch debouncer and internal latch, designed
to accept a noisy mechanical pushbutton input while providing a clean,
stable latched output. It also includes a one‑shot interrupt output for
event signaling, enabling reliable switch interfacing in low‑power embedded
systems.

Signed-off-by: Marc Paolo Sosa <marcpaolo.sosa@analog.com>
---
Marc Paolo Sosa (2):
      dt-bindings: input: add adi,max16150.yaml
      input: misc: add driver for max16150

 .../devicetree/bindings/input/adi,max16150.yaml    |  57 ++++++++
 drivers/input/misc/Kconfig                         |   9 ++
 drivers/input/misc/Makefile                        |   1 +
 drivers/input/misc/max16150.c                      | 161 +++++++++++++++++++++
 4 files changed, 228 insertions(+)
---
base-commit: e7b53288d9ea899abc6d47a7f20065ab511a810c
change-id: 20260223-max16150-8ef94e643cd0

Best regards,
-- 
Marc Paolo Sosa <marcpaolo.sosa@analog.com>

