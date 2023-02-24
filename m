From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH RFC 0/4] Driver for Apple Z2 touchscreens.
Date: Fri, 24 Feb 2023 11:20:05 +0100
Message-Id: <20230223-z2-for-ml-v1-0-028f2b85dc15@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFWP+GMC/x2NQQqDQAxFryJZN6DRFum20AO4LS5mbKYG6iiJF
 FG8u2OXj/8+bwNjFTa4Zxso/8RkjAmKSwZd7+KHUd6JgXIqc6ISV8IwKg5fLOrgr1TdQuVrSL5
 3xujVxa4/H4OzmfUcJuUgyz/ygub5gHbfD/nmbFF5AAAA
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 - <asahi@lists.linux.dev>, Henrik Rydberg <rydberg@bitmath.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-input@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677234010; l=1467;
 i=fnkl.kernel@gmail.com; s=20230213; h=from:subject:message-id;
 bh=iO9PN0y1qjt6XxSGQL41NucjZnvl8Vrb0aCV9l4Baxw=;
 b=dImDJPnm2PjAzixKlaYbuO+xXG0Y6YZ4B4bWEsmaK9XI/9tzCa8+2bLT0yto9OtWiqh83pRqY
 qM6HrTIDAOcArxJFYMyemiDG6YVmwXVJgxx8kVAqt5UfoTFGbwNqHHn
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=7LFSAJtxIWAs9LzCIyX0sSvCZy2wQTyEIu1zch6o804=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20230213 with auth_id=28
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This series adds support for Apple touchscreens using the Z2 protocol.
Those are used as the primary touchscreen on mobile Apple devices, and for the
touchbar on laptops using the M-series chips. (T1/T2 laptops have a coprocessor
in charge of speaking Z2 to the touchbar).

Sending this as a RFC for now, since this series requires the SPI controller
support which is not upstream yet:
https://lore.kernel.org/all/20211212034726.26306-1-marcan@marcan.st/

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
Sasha Finkelstein (4):
      dt-bindings: input: touchscreen: Add Z2 controller bindings.
      input: apple_z2: Add a driver for Apple Z2 touchscreens
      arm64: dts: apple: t8103: Add touchbar bindings
      MAINTAINERS: Add entries for Apple Z2 touchscreen driver

 .../input/touchscreen/apple,z2-touchscreen.yaml    |  81 ++++
 MAINTAINERS                                        |   2 +
 arch/arm64/boot/dts/apple/t8103-j293.dts           |  20 +
 arch/arm64/boot/dts/apple/t8103.dtsi               |  12 +
 drivers/input/touchscreen/Kconfig                  |  13 +
 drivers/input/touchscreen/Makefile                 |   1 +
 drivers/input/touchscreen/apple_z2.c               | 465 +++++++++++++++++++++
 7 files changed, 594 insertions(+)
---
base-commit: c9c3395d5e3dcc6daee66c6908354d47bf98cb0c
change-id: 20230223-z2-for-ml-18fb5246f4b8

Best regards,
-- 
Sasha Finkelstein <fnkl.kernel@gmail.com>

