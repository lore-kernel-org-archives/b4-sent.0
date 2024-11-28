From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH v2 0/4] Driver for Apple Z2 touchscreens.
Date: Thu, 28 Nov 2024 23:29:15 +0100
Message-Id: <20241128-z2-v2-0-76cc59bbf117@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALvuSGcC/zWMQQrCMBBFr1JmbWQyxiKuvId0ESdjO2BbSSSoJ
 Xc3Lbh8n//eAkmiSoJzs0CUrEnnqQLtGuDBT70YDZWBkJy15MyXDKOl25FO4jFAPT6j3PW9Ra5
 d5UHTa46frZntuv71dtWzNWjYHdgxt4QYLv3o9bHneYSulPIDnpMJipQAAAA=
X-Change-ID: 20241124-z2-c012b528ea0d
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732832961; l=1917;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=oe01/Ykp7CrABnRRYCE+rh9+IS7KDiWdmcELIniUmsg=;
 b=QWGUNje+O0YI4L6uacMv3gCdhycX36kw+7OQPwVuFaDv7ROAUD8JL4y3TN+sqO/WSelEPv/HJ
 QF3jDo6TppbDr01ZAUfKJynJi79vHIby22PKFeS+8EQSFGwkYBUuwaU
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This series adds support for Apple touchscreens using the Z2 protocol.
Those are used as the primary touchscreen on mobile Apple devices, and for the
touchbar on laptops using the M-series chips. (T1/T2 laptops have a coprocessor
in charge of speaking Z2 to the touchbar).

Originally sent as a RFC at https://lore.kernel.org/all/20230223-z2-for-ml-v1-0-028f2b85dc15@gmail.com/
The changes since then mostly address the review feedback, but also
add another machine that has this specific controller.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
Changes in v2:
- In a separate patch, fixed an issue that prevented the SPI controller
  from using GPIO CS, and as such, moved the hardware quirk to there
- Went back to uploading the firmware in probe() instad of open()
- Other changes addressing the review feedback
- Link to v1: https://lore.kernel.org/r/20241126-z2-v1-0-c43c4cc6200d@gmail.com

---
Sasha Finkelstein (4):
      dt-bindings: input: touchscreen: Add Z2 controller
      input: apple_z2: Add a driver for Apple Z2 touchscreens
      arm64: dts: apple: Add touchbar digitizer nodes
      MAINTAINERS: Add entries for Apple Z2 touchscreen driver

 .../input/touchscreen/apple,z2-multitouch.yaml     |  69 ++++
 MAINTAINERS                                        |   2 +
 arch/arm64/boot/dts/apple/t8103-j293.dts           |  26 ++
 arch/arm64/boot/dts/apple/t8103.dtsi               |  20 +
 arch/arm64/boot/dts/apple/t8112-j493.dts           |  24 ++
 arch/arm64/boot/dts/apple/t8112.dtsi               |  14 +
 drivers/input/touchscreen/Kconfig                  |  13 +
 drivers/input/touchscreen/Makefile                 |   1 +
 drivers/input/touchscreen/apple_z2.c               | 458 +++++++++++++++++++++
 9 files changed, 627 insertions(+)
---
base-commit: 9f16d5e6f220661f73b36a4be1b21575651d8833
change-id: 20241124-z2-c012b528ea0d

