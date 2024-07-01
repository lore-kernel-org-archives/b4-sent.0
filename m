From: Utsav Agarwal <utsav.agarwal@analog.com>
Subject: [PATCH v4 0/2] adp5588-keys: Support for dedicated gpio operation
Date: Mon, 01 Jul 2024 16:04:49 +0100
Message-Id: <20240701-adp5588_gpio_support-v4-0-44bba0445e90@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJHFgmYC/x3MTQqAIBBA4avErBNMsr+rRITmWLPJQSuC6O5Jy
 2/x3gMJI2GCoXgg4kWJwp5RlwUsm9lXFOSyQUlVy1ZWwjjWuuvmlSnM6WQO8RCNdlZZpyrTe8g
 pR/R0/9txet8Pb4Bme2YAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719846302; l=1741;
 i=utsav.agarwal@analog.com; s=20240701; h=from:subject:message-id;
 bh=looVJtFQZcec+jXHJMoRnWIFRehDK3wbXLGpJmuScKU=;
 b=cWNWYh5i4IA/s9OTtCFegD8Y7IPG9TExKPDAInMmjMa8tAX0BzwvV3Ls8eq3o6mp2vn8kRDOd
 LooKZhMUTajDt2kVEMp/BIaHeUqq+t00LcsvjeFOBG+LUyOB0NOO/lP
X-Developer-Key: i=utsav.agarwal@analog.com; a=ed25519;
 pk=mIG5Dmd3TO5rcICwTsixl2MoUcf/i2u+jYqifd7+fmI=
X-Endpoint-Received: by B4 Relay for utsav.agarwal@analog.com/20240701 with auth_id=178
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Current state of the driver for the ADP5588/87 only allows partial
I/O to be used as GPIO. This support was previously present as a
separate gpio driver, which was dropped with the commit
5ddc896088b0 ("gpio: gpio-adp5588: drop the driver") since the
functionality was deemed to have been merged with adp5588-keys.

This series of patches re-enables this support by introducing a new
property names "gpio-only", which allows the driver to relax the
requirement for registering a keymap and enable pure GPIO operation. 

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
Utsav Agarwal (2):
      Input: adp5588-keys - add support for pure gpio
      dt-bindings: input: Update dtbinding for adp5588

 .../devicetree/bindings/input/adi,adp5588.yaml     | 28 ++++++++++++++++---
 drivers/input/keyboard/adp5588-keys.c              | 32 ++++++++++++++++++++++
 2 files changed, 56 insertions(+), 4 deletions(-)
---
base-commit: 1c52cf5e79d30ac996f34b64284f2c317004d641
change-id: 20240701-adp5588_gpio_support-65db2bd21a9f

Best regards,
-- 
Utsav Agarwal <utsav.agarwal@analog.com>

