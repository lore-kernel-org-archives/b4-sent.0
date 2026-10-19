From: Junyi Zhao <junyi.zhao@amlogic.com>
Subject: [PATCH 0/3] Add vendor glue layer support and Amlogic A9
 implementation
Date: Mon, 19 Oct 2026 13:34:25 +0800
Message-Id: <20261019-a9_i3c-v1-0-329d819d621f@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOGr1WoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0MD3UTL+EzjZF3LFFMjE9MUA0uTZAsloOKCotS0zAqwQdGxEH5xaVJ
 WanIJSLdSbS0AmYvdyWoAAAA=
X-Change-ID: 20261010-a9_i3c-9d5245d094c8
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Frank Li <Frank.Li@nxp.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-i3c@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, imx@lists.linux.dev, 
 linux-hardening@vger.kernel.org, xianwei.zhao@amlogic.com, 
 Kelvin.Zhang@amlogic.com, Junyi Zhao <junyi.zhao@amlogic.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792388075; l=1948;
 i=junyi.zhao@amlogic.com; s=20260924; h=from:subject:message-id;
 bh=pgIkA9EQP4kVbdf5QtIU9MRFvhNyPH6tw4oAfuEjiik=;
 b=QIGcl9ephVHWpuLWE8j6m/z4Ati/770ms7/xAPm1vRqUYUPZMK1LXMa/5Whq8a8K6loC9Gw5I
 KWH3cPY2l1xAuI3YvuF4GsbgSjndplpbnU+NZEYeW3luoxe1XAHVz36
X-Developer-Key: i=junyi.zhao@amlogic.com; a=ed25519;
 pk=hiL5PjGIksGFiWvEx9J3MhQqU/ro6vNbj72NIw4bbvA=
X-Endpoint-Received: by B4 Relay for junyi.zhao@amlogic.com/20260924 with auth_id=1054
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SVC I3C controller IP is used by multiple vendors, which may
require platform-specific handling for controller resources and
integration details.

Rework the SVC I3C driver to introduce a vendor glue layer that
separates common controller logic from vendor-specific extensions.
This allows different implementations to reuse the shared SVC I3C
framework while providing their own platform-dependent operations.

On top of the glue layer framework, add support for the Amlogic A9
implementation of the SVC I3C controller, including Device Tree
bindings and the A9-specific glue layer driver.

This series consists of:

  - Rework the SVC I3C driver to support vendor glue layers.
  - Add Device Tree bindings for the Amlogic A9 I3C controller.
  - Add the Amlogic A9 SVC I3C glue layer driver.

Signed-off-by: Junyi Zhao <junyi.zhao@amlogic.com>
---
Junyi Zhao (3):
      i3c: master: Rework SVC I3C to support vendor glue layers
      dt-bindings: i3c: Add Amlogic A9 I3C controller
      i3c: master: svc: Add Amlogic A9 glue layer

 .../devicetree/bindings/i3c/amlogic,i3c-a9.yaml    | 102 +++++
 MAINTAINERS                                        |  12 +-
 drivers/i3c/master/Kconfig                         |   9 +-
 drivers/i3c/master/Makefile                        |   2 +-
 drivers/i3c/master/svc/Kconfig                     |  28 ++
 drivers/i3c/master/svc/Makefile                    |   6 +
 drivers/i3c/master/svc/i3c-amlogic.c               | 250 +++++++++++
 .../master/{svc-i3c-master.c => svc/i3c-main.c}    | 467 ++-------------------
 drivers/i3c/master/svc/i3c-main.h                  | 297 +++++++++++++
 drivers/i3c/master/svc/i3c-silvaco.c               | 173 ++++++++
 10 files changed, 909 insertions(+), 437 deletions(-)
---
base-commit: aac26bee2287c88af5be5a5ff96d783b19a28790
change-id: 20261010-a9_i3c-9d5245d094c8

Best regards,
--  
Junyi Zhao <junyi.zhao@amlogic.com>

