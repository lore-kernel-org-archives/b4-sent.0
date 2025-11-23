From: Amit Sunil Dhamne <amitsd@google.com>
Subject: [PATCH 0/6] Introduce MAX77759 charger driver
Date: Sun, 23 Nov 2025 08:35:47 +0000
Message-Id: <20251123-max77759-charger-v1-0-6b2e4b8f7f54@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGPHImkC/x2MQQqAIBAAvyJ7TlBBrb4SHaw220MWK4QQ/j3pO
 AwzL2RkwgyjeIHxoUxXaqA7AesRUkRJW2MwylitlZVnKN57O8imOSLL3prFGbc5pwO07Gbcqfz
 Laa71A6K3ftdiAAAA
X-Change-ID: 20251105-max77759-charger-852b626d661a
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Lee Jones <lee@kernel.org>, Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 RD Babiera <rdbabiera@google.com>, Kyle Tso <kyletso@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763886983; l=1935;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=BpGpxP773zsyhDqiIdTbkt1LHwhw61h1r+wf9K8eXBA=;
 b=BWVPQuQsjLSNkUQqrd15xu/QTq3ozxwwQ2vwMMcB/GYDKnpH5yHZo2OYSKPSBUfx/euLcrJbV
 nJPACkoU7CFCwihqtmUdLp8NRbWZ13t2vr/ibMQv0GZBPk8vharpQqE
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MAX77759 PMIC is used in Pixel 6 and 6 Pro (Oriole/Raven) boards.
One of the functions of the MAX77759 PMIC is a battery charger. This
patchset introduces a driver for this function. One of the unique
features of this charger driver is that it works with a USB input where
the Type-C controller is TCPCI based.

Changes to the board files will follow soon once this patchset is reviewed.

For reference to the MAX77759 MFD based patchset (present in upstream):
https://lore.kernel.org/all/20250509-max77759-mfd-v10-0-962ac15ee3ef@linaro.org/

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
Amit Sunil Dhamne (6):
      dt-bindings: power: supply: Add Maxim MAX77759 charger
      dt-bindings: mfd: maxim,max77759: add charger child node
      dt-bindings: usb: maxim,max33359: Add supply property for VBUS in OTG mode
      mfd: max77759: modify irq configs
      power: supply: max77759: add charger driver
      usb: typec: tcpm/tcpci_maxim: deprecate WAR for setting charger mode

 .../devicetree/bindings/mfd/maxim,max77759.yaml    |  12 +
 .../power/supply/maxim,max77759-charger.yaml       |  36 +
 .../devicetree/bindings/usb/maxim,max33359.yaml    |   4 +
 MAINTAINERS                                        |   7 +
 drivers/mfd/max77759.c                             |  27 +-
 drivers/power/supply/Kconfig                       |  11 +
 drivers/power/supply/Makefile                      |   1 +
 drivers/power/supply/max77759_charger.c            | 866 +++++++++++++++++++++
 drivers/usb/typec/tcpm/tcpci_maxim.h               |   1 +
 drivers/usb/typec/tcpm/tcpci_maxim_core.c          |  48 +-
 include/linux/mfd/max77759.h                       |   9 +
 11 files changed, 999 insertions(+), 23 deletions(-)
---
base-commit: 39f90c1967215375f7d87b81d14b0f3ed6b40c29
change-id: 20251105-max77759-charger-852b626d661a

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

