From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH 0/2] Bindings and DTS for Apple SoC GPUs
Date: Wed, 11 Jun 2025 19:32:15 +0200
Message-Id: <20250611-sgx-dt-v1-0-7a11f3885c60@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJ+9SWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDU2ND3eL0Ct2UEl2TRMMkIDJOMjJIUwIqLihKTcusABsUHVtbCwAIRPi
 FWAAAAA==
X-Change-ID: 20250531-sgx-dt-4a1ba1b3b20f
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Neal Gompa <neal@gompa.dev>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749663157; l=1440;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=I4HXo0ATSJ/hdYPbDOMk7Ra3is0bb13Y9rAP/aptRgY=;
 b=a/YPKcThE02rkRwTyp+2PWA/Znv8r+ZwFTmoNq9NkcjUgxXGHJoltLqMOGX5qRLEf4jZ6KO9L
 a7wGQotkZnHAE5MWdWThd6RMmfvdh3TUiWPOhTM2vktnPdo+qNV5750
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This patch series adds the DT bindings and tree entries for the GPU
present in Apple M-series SoCs. The driver itself is in Rust and
upstream is currently missing several prerequisite bindings, so will
be sent later.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
Sasha Finkelstein (2):
      dt-bindings: Add Apple SoC GPU
      arm64: dts: Add Apple SoC GPU

 Documentation/devicetree/bindings/gpu/apple,agx.yaml | 95 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 MAINTAINERS                                          |  1 +
 arch/arm64/boot/dts/apple/t6000.dtsi                 |  4 ++++
 arch/arm64/boot/dts/apple/t6001.dtsi                 |  4 ++++
 arch/arm64/boot/dts/apple/t6002.dtsi                 |  4 ++++
 arch/arm64/boot/dts/apple/t600x-common.dtsi          | 34 ++++++++++++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t600x-die0.dtsi            | 28 ++++++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8103.dtsi                 | 62 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8112.dtsi                 | 62 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 9 files changed, 294 insertions(+)
---
base-commit: aef17cb3d3c43854002956f24c24ec8e1a0e3546
change-id: 20250531-sgx-dt-4a1ba1b3b20f

Best regards,
-- 
Sasha Finkelstein <fnkl.kernel@gmail.com>

