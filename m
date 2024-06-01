From: Joel Selvaraj <joelselvaraj.oss@gmail.com>
Subject: [PATCH v4 0/3] novatek-nvt-ts: add support for NT36672A
 touchscreen
Date: Sat, 01 Jun 2024 10:30:17 -0500
Message-Id: <20240601-nvt-ts-devicetree-regulator-support-v4-0-e0c0174464c4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIk+W2YC/43OQQ7CIBAF0KsY1o4BihRceQ/jAoexkmjbABKN6
 d1F40JddfknP+/PgyWKgRLbLB4sUgkpDH0NarlgeHJ9RxB8zUxyqfhaGOhLhpzA1y5SjkQQqbu
 eXR4ipOs4DjGDQ0vKHlrjhGZVGiMdw+29stvXfAqp1u/v0SJe148vxSy/COBgfKs16sZ6dNvu4
 sJ5hcOFvfwiv001z5TVPLTKqpY3BpX6N5tvU88zm2o6Z4wXHNHbnz+naXoCVIju4X4BAAA=
To: Hans de Goede <hdegoede@redhat.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 Joel Selvaraj <joelselvaraj.oss@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717255824; l=2072;
 i=joelselvaraj.oss@gmail.com; s=20240420; h=from:subject:message-id;
 bh=n8FgRSqS/0SH93OR/rSR5u3qt1CP4ZpLuUxyPWB99QQ=;
 b=3AMsyFGEo6VG5DEWahrUosuEQQpoCSe3tGbUVCSBQkn5X5r0mynSkXUb0mQ2BFYeZybdiKpAP
 W9Q34YsH6tkBQbQndqobUTg7k11XAwVb9vGKea+6UwE5iGDqvGSmrlc
X-Developer-Key: i=joelselvaraj.oss@gmail.com; a=ed25519;
 pk=qT4gsuVtlPE0Dpr+tQA/Fumm7wzVP6qfeVaY+6pX04s=
X-Endpoint-Received: by B4 Relay for joelselvaraj.oss@gmail.com/20240420 with auth_id=165
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend the novatek touchscreen driver to support NT36672A chip which
is found in phones like qcom/sdm845-xiaomi-beryllium-tianma.dts.
Added devicetree support for the driver and used i2c chip data to handle
the variation in chip id and wake type. Also added vcc and iovcc
regulators which are used to power the touchscreen hardware.

Signed-off-by: Joel Selvaraj <joelselvaraj.oss@gmail.com>
---
Changes in v4:
- Use lowercase i2c device id as suggested by Hans de Goede.
- Disable the regulators after nvt_ts_read_data during probe.
- Link to v3: https://lore.kernel.org/r/20240526-nvt-ts-devicetree-regulator-support-v3-0-aa88d10ccd9a@gmail.com

Changes in v3:
- Fix indentation in the binding as suggested by Krzysztof Kozlowski.
- Picked up Krzysztof Kozlowski's Reviewed-by tag for the binding.
- Link to v2: https://lore.kernel.org/r/20240524-nvt-ts-devicetree-regulator-support-v2-0-b74947038c44@gmail.com

Changes in v2:
- The generic i2c device id is now replaced with the correct IC variant
  provided by Hans de Goede
- Updated the bindings to reflect the latest changes and also incorporated
  the suggestions provided by Krzysztof Kozlowski
- Link to v1: https://lore.kernel.org/r/20240521-nvt-ts-devicetree-regulator-support-v1-0-8d766c639dca@gmail.com

---
Joel Selvaraj (3):
      Input: novatek-nvt-ts: replace generic i2c device id with specific IC variant
      dt-bindings: input: document Novatek NVT touchscreen controller
      Input: novatek-nvt-ts: add support for NT36672A touchscreen

 .../bindings/input/touchscreen/novatek,nvt-ts.yaml | 62 +++++++++++++++++++
 MAINTAINERS                                        |  1 +
 drivers/input/touchscreen/novatek-nvt-ts.c         | 70 ++++++++++++++++++++--
 drivers/platform/x86/x86-android-tablets/other.c   |  2 +-
 4 files changed, 128 insertions(+), 7 deletions(-)
---
base-commit: 6578aac6a270bd6deb9f9319b991dd430de263dd
change-id: 20240518-nvt-ts-devicetree-regulator-support-ac9e49b78a16

Best regards,
-- 
Joel Selvaraj <joelselvaraj.oss@gmail.com>

