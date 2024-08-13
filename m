From: Utsav Agarwal <utsav.agarwal@analog.com>
Subject: [PATCH v10 0/3] adp5588-keys: Support for dedicated gpio operation
Date: Tue, 13 Aug 2024 10:51:30 +0100
Message-Id: <20240813-adp5588_gpio_support-v10-0-aab3c52cc8bf@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKIsu2YC/43Q3UrEMBAF4FdZcm0lSWfy45XvIbIkmbQb0Kaka
 1GWvrvp3rhSi3t5Dsx3YC5siiXFiT0dLqzEOU0pDzUI/nBg4eSGPjaJasEkl8A1F42jEdGYYz+
 mfJw+xjGXc6OQvPQkhbMdq6djiV36vLovrzWf0nTO5es6M8Pa/gPO0PAGwHvHATBa/uwG95b7x
 5Df2SrOeKu0Owquiu1CdMSp/UNRtwrsKKoqwStEAaQF+I2i71F0VWIL0evoHbqtYu5RTFUkN6F
 DgiBJbRT7oxiudhS7/oWUEMYrUtj+UpZl+QYz3/k+GAIAAA==
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
 Oliver Gaskell <oliver.gaskell@analog.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723542691; l=4164;
 i=utsav.agarwal@analog.com; s=20240701; h=from:subject:message-id;
 bh=r3ixwT4ejaY1WXYoTRnXA9O5iIKHCzNV0dZx1F6sTuk=;
 b=IQz9G0SArziByu8tFlo26DBKrKLiIn7itrN727zn/+SoM6P7dQbnddP7DvhqsSzTFWNM8tkNa
 dnopI+gT0pTDAd0c+5NpMZIAXOrO2Bme0Ds/Fu2Ou8/j1DdqQWBBOC/
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

Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
---
Changelog
==========

Changes in v10:
	- Corrected changelog ordering
	- Changed dtbinding commit to clarify all changes are made in
	  software. The commit message now also expands on what
	  the desired pure gpio mode is
	- Added acquired tags to commits
	- dt-binding:
		Removed multiple blank lines before the dependecies block
	  	Removed excess headers included in dtbinding example
	  	Removed constraint being repeated in free form text
	  	Merged outlying dependency into a single block
- Link to v9: https://lore.kernel.org/r/20240806-adp5588_gpio_support-v9-0-4d6118b6d653@analog.com

Changes in v9:
	- Added dt-binding dependency for interrupt-controller. Now if
	  interrupt-controller is specified, interrupts must be
	  provided.
- Link to v8: https://lore.kernel.org/r/20240704-adp5588_gpio_support-v8-0-208cf5d4c2d6@analog.com

Changes in v8:
	- Fixed indentation in document example (removed extra spaces)
- Link to v7: https://lore.kernel.org/r/20240704-adp5588_gpio_support-v7-0-e34eb7eba5ab@analog.com

Changes in v7:
	- Fixed commit subject for transported patch 
	- Driver now does not setup gpio_irq_chip if 
	  interrupt has not been provided
	- Fixed indentation for dtbinding example
- Link to v6: https://lore.kernel.org/r/20240704-adp5588_gpio_support-v6-0-cb65514d714b@analog.com

Changes in v6:
	- Restored functionality to register interrupts in GPIO
	  mode(i.e, these are optional but not exclusive to keypad mode
	  since even in pure gpio mode, they can be used as inputs via 
	  gpio-keys)
	- Updated dt-bindings such that each keypad property depends on
	  the others. Interrupts, although optional are now required by 
	  keypad mode but are not limited to it.
- Link to v5: https://lore.kernel.org/r/20240703-adp5588_gpio_support-v5-0-49fcead0d390@analog.com

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

V4:
	- Added dt-bindings patch

V3:
	-  Moved device_property_present() for reading "gpio-only" into 
	adp558_fw_parse()
	-  Added print statements in case of error

V2: 
	-  Changed gpio_only from a local variable to a member of struct
	adp5588_kpad
	-  Removed condition from adp5588_probe() to skip adp5588_fw_parse() if 
	gpio-only specified. adp558_fw_parse() now handles and returns
	0 if gpio-only has been specified.
	-  Added a check in adp5588_fw_parse() to make sure keypad 
	properties(keypad,num-columns and keypad,num-rows) were not defined when 
	gpio-only specified

---

---
Dmitry Torokhov (1):
      Input: adp5588-keys - use guard notation when acquiring mutexes

Utsav Agarwal (2):
      Input: adp5588-keys - add support for pure gpio
      dt-bindings: input: pure gpio support for adp5588

 .../devicetree/bindings/input/adi,adp5588.yaml     | 40 ++++++++--
 drivers/input/keyboard/adp5588-keys.c              | 86 +++++++++++++---------
 2 files changed, 84 insertions(+), 42 deletions(-)
---
base-commit: 1c52cf5e79d30ac996f34b64284f2c317004d641
change-id: 20240701-adp5588_gpio_support-65db2bd21a9f

Best regards,
-- 
Utsav Agarwal <utsav.agarwal@analog.com>

