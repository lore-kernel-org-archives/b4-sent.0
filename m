From: Samuel Kayode <samuel.kayode@savoirfairelinux.com>
Subject: [PATCH v3 0/6] add support for pf1550 PMIC MFD-based drivers
Date: Tue, 27 May 2025 18:25:32 -0400
Message-Id: <20250527-pf1550-v3-0-45f69453cd51@savoirfairelinux.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANw7NmgC/yXMywqDMBCF4VcJs27KJHZq8VUkCzWTdhZemqgI4
 rsbdPkdDv8OiaNwgkrtEHmVJOOQUTwUdL9m+LIWnw0WLSHZUk/BEKH2LzQBPZbtByGfp8hBtit
 Uu9uR/0vuzfcIbZNYd2Pfy1yp9f00BO44Tjto7KWBAAAA
X-Change-ID: 20250527-pf1550-d401f0d07b80
To: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Sebastian Reichel <sre@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-input@vger.kernel.org, linux-pm@vger.kernel.org, 
 Samuel Kayode <samuel.kayode@savoirfairelinux.com>, eballetbo@gmail.com, 
 abelvesa@linux.com, b38343@freescale.com, yibin.gong@nxp.com, 
 Abel Vesa <abelvesa@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748384783; l=3259;
 i=samuel.kayode@savoirfairelinux.com; s=20250527; h=from:subject:message-id;
 bh=URe9IVrGZGJyILeVZBhhwONAzc69qPxN2OjxE6CJZ4E=;
 b=UJ4AcJwLfK4DFqRBhE//y7QyL/NeE6MGisDxCq6MHlHpahCh8CYZPc0hk8Qp9pNPhav7nSXPv
 w1jN1WnfbY6ARElc+dw0DpA8Pp7zaBt/T5Xn4VERhp5hVe3NC4klhf2
X-Developer-Key: i=samuel.kayode@savoirfairelinux.com; a=ed25519;
 pk=TPSQGQ5kywnnPyGs0EQqLajLFbdDu17ahXz8/gxMfio=
X-Endpoint-Received: by B4 Relay for samuel.kayode@savoirfairelinux.com/20250527 with auth_id=412
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for pf1550 PMIC. It provides the core mfd driver and a
set of three sub-drivers for the regulator, power supply and input subsystems.

Patch 1 adds the DT binding document for the PMIC. Patches 2-5 adds the
pertinent drivers. Last patch adds a MAINTAINERS entry for the drivers.

Changes since v1:
   - DT bindings for all devices included
   - Add onkey driver
   - Add driver for the regulators
   - Ensure charger is activated as some variants have it off by default
   - Update mfd and charger driver per feedback from eballetbo@gmail.com
   - Add myself as maintainer for these drivers
   - Link to v1: https://lore.kernel.org/1523974819-8711-1-git-send-email-abel.vesa@nxp.com/

Changes since v2:
   - Rebase on recent mainline kernel v6.15
   - Single yaml file containing dt bindings for all pf1550 devices
   - irq mapping done in MFD driver as suggested by Dmitry Torokhov
   - Drop unnecessary includes in drivers
   - Replace dev_err with dev_err_probe in probe method of drivers
   - Drop compatible string from drivers of the sub-devices
   - Remove dependency on OF from drivers of the sub-devices
   - onkey: move driver from input/keyboard into input/misc
   - onkey: remove dependency on OF
   - onkey: use onkey virqs instead of central irq
   - onkey: fix integer overflow for regmap_write when unmasking
     interrupts during pf1550_onkey_resume
   - charger: add support for monitored-battery which is used in setting
     a constant voltage for the charger.
   - Address other feedback from Dmitry Torokhov and Krzysztof Kozlowski
   - Link to v2: https://lore.kernel.org/cover.1747409892.git.samuel.kayode@savoirfairelinux.com/

Signed-off-by: Samuel Kayode <samuel.kayode@savoirfairelinux.com>
---
Samuel Kayode (6):
      dt-bindings: mfd: add pf1550
      mfd: pf1550: add core mfd driver
      regulator: pf1550: add support for regulator
      input: pf1550: add onkey support
      power: supply: pf1550: add battery charger support
      MAINTAINERS: add an entry for pf1550 mfd driver

 Documentation/devicetree/bindings/mfd/pf1550.yaml | 139 +++++
 MAINTAINERS                                       |  10 +
 drivers/input/misc/Kconfig                        |  11 +
 drivers/input/misc/Makefile                       |   1 +
 drivers/input/misc/pf1550-onkey.c                 | 202 +++++++
 drivers/mfd/Kconfig                               |  14 +
 drivers/mfd/Makefile                              |   2 +
 drivers/mfd/pf1550.c                              | 277 ++++++++++
 drivers/power/supply/Kconfig                      |  11 +
 drivers/power/supply/Makefile                     |   1 +
 drivers/power/supply/pf1550-charger.c             | 639 ++++++++++++++++++++++
 drivers/regulator/Kconfig                         |   9 +
 drivers/regulator/Makefile                        |   1 +
 drivers/regulator/pf1550-regulator.c              | 353 ++++++++++++
 include/linux/mfd/pf1550.h                        | 241 ++++++++
 15 files changed, 1911 insertions(+)
---
base-commit: 0a4b866d08c6adaea2f4592d31edac6deeb4dcbd
change-id: 20250527-pf1550-d401f0d07b80

Best regards,
-- 
Samuel Kayode <samuel.kayode@savoirfairelinux.com>

