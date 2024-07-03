From: Utsav Agarwal <utsav.agarwal@analog.com>
Subject: [PATCH v5 0/3] adp5588-keys: Support for dedicated gpio operation
Date: Wed, 03 Jul 2024 11:58:13 +0100
Message-Id: <20240703-adp5588_gpio_support-v5-0-49fcead0d390@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMUuhWYC/4WNQQ6DIBBFr2JmXRokQ6tdeY/GGBDUSVogYEkb4
 91LvUCX7yX//Q2SjWQT3KoNos2UyLsC8lTBuCg3W0amMAgukF95zZQJUjbNMAfyQ3qF4OPKLtJ
 ooY2oVTtBmYZoJ3of2XtfeKG0+vg5XjL+7J9gRsYZotaKI0rb8k459fDzefRP6Pd9/wJQTla4u
 QAAAA==
To: Utsav Agarwal <utsav.agarwal@analog.com>, 
 Michael Hennerich <michael.hennerich@analog.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Arturs Artamonovs <arturs.artamonovs@analog.com>, 
 Vasileios Bimpikas <vasileios.bimpikas@analog.com>, 
 Oliver Gaskell <oliver.gaskell@analog.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720004298; l=2339;
 i=utsav.agarwal@analog.com; s=20240701; h=from:subject:message-id;
 bh=ZKBZXqTb3GYcej9sBFGWNtjDUyV0Rn3CMeoWjdQoMDA=;
 b=F5tQpXuKWFwC+womE91xcSEaMlAf2+LITtvgdoV2FfCwSH+UNmP1DrAbVZZpGx9lHkr8+ioKN
 HZ+kRE5RfHnAIUoFTjct16dDojVUrrAb5whPZduEy9pRdP1N7DJe+M2
X-Developer-Key: i=utsav.agarwal@analog.com; a=ed25519;
 pk=mIG5Dmd3TO5rcICwTsixl2MoUcf/i2u+jYqifd7+fmI=
X-Endpoint-Received: by B4 Relay for utsav.agarwal@analog.com/20240701 with auth_id=178
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Current state of the driver for the ADP5588/87 only allows partial
I/O to be used as GPIO. This support was previously present as a
separate gpio driver, which was dropped with the commit
5ddc896088b0 ("gpio: gpio-adp5588: drop the driver") since the
functionality was deemed to have been merged with adp5588-keys.

This series of patches re-enables this support by allowing the driver to 
relax the requirement for registering a keymap and enable pure GPIO 
operation. 

Changelog
==========

V2: 
	-  Changed gpio_only from a local variable to a member of struct
	adp5588_kpad
	-  Removed condition from adp5588_probe() to skip adp5588_fw_parse() if 
	gpio-only specified. adp558_fw_parse() now handles and returns
	0 if gpio-only has been specified.
	-  Added a check in adp5588_fw_parse() to make sure keypad 
	properties(keypad,num-columns and keypad,num-rows) were not defined when 
	gpio-only specified

V3:
	-  Moved device_property_present() for reading "gpio-only" into 
	adp558_fw_parse()
	-  Added print statements in case of error

V4:
	- Added dt-bindings patch

Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
---
V5:
	- Removed extra property "gpio-only", now pure gpio mode is
	  detected via the adbsence of keypad specific properties.
	- Added dependencies for keypad properties to preserve
	  the original requirements in case a pure gpio mode is not
	  being used.
	- Added additional description for why the "interrupts" property
	  was made optional
	- Rebased current work based on https://lore.kernel.org/linux-input/ZoLt_qBCQS-tG8Ar@google.com/
- Link to v4: https://lore.kernel.org/r/20240701-adp5588_gpio_support-v4-0-44bba0445e90@analog.com

---
Dmitry Torokhov (1):
      iInput: adp5588-keys - use guard notation when acquiring mutexes

Utsav Agarwal (2):
      Input: adp5588-keys - add support for pure gpio
      dt-bindings: input: Update dtbinding for adp5588

 .../devicetree/bindings/input/adi,adp5588.yaml     | 33 ++++++++--
 drivers/input/keyboard/adp5588-keys.c              | 70 ++++++++++++----------
 2 files changed, 66 insertions(+), 37 deletions(-)
---
base-commit: 1c52cf5e79d30ac996f34b64284f2c317004d641
change-id: 20240701-adp5588_gpio_support-65db2bd21a9f

Best regards,
-- 
Utsav Agarwal <utsav.agarwal@analog.com>

