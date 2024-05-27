From: Joel Selvaraj <joelselvaraj.oss@gmail.com>
Subject: [PATCH v3 0/3] novatek-nvt-ts: add support for NT36672A
 touchscreen
Date: Sun, 26 May 2024 22:26:23 -0500
Message-Id: <20240526-nvt-ts-devicetree-regulator-support-v3-0-aa88d10ccd9a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAF/9U2YC/43NQQ6DIBQE0KsY1v2NIEXtqvdoukD4VRIVA0jaG
 O9eNF24dDmTyZuFeHQGPblnC3EYjTd2TKG4ZER1cmwRjE6ZsJzx/EYrGGOA4EGnrcLgEMFhO/c
 yWAd+nibrAkhVI6+bspJUkCRNDt/ms788Xyl3xqf5dz+NdGv/PqOn/Eghh0qXQihR1FrJRztI0
 1+VHcjmR3Y0+TmTJbMpec3LvKgU50dzXdcfnJBIUSoBAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716780394; l=1813;
 i=joelselvaraj.oss@gmail.com; s=20240420; h=from:subject:message-id;
 bh=prpzGhuCLwgnWK4gbCVzha4BTqIB+FEnrv/OgDMS0Wo=;
 b=/fj7cXabk4wL0lsditJEpA4IcJz+MDBlkYvmeKV7ZakhUe2pAOaYB5BunAAFWZyMK1asPVk6U
 0mMUttIFJD+DIWAlBX0us4ScW6BOZJhEl19LrrsJtvDud2tEBRvI9NG
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

 .../bindings/input/touchscreen/novatek,nvt-ts.yaml | 62 +++++++++++++++++
 MAINTAINERS                                        |  1 +
 drivers/input/touchscreen/novatek-nvt-ts.c         | 78 ++++++++++++++++++++--
 drivers/platform/x86/x86-android-tablets/other.c   |  2 +-
 4 files changed, 136 insertions(+), 7 deletions(-)
---
base-commit: 6578aac6a270bd6deb9f9319b991dd430de263dd
change-id: 20240518-nvt-ts-devicetree-regulator-support-ac9e49b78a16

Best regards,
-- 
Joel Selvaraj <joelselvaraj.oss@gmail.com>

