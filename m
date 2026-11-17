From: Luna Hart <lhart.opensource@witekio.com>
Subject: [PATCH v2 0/2] hwmon: Add support for TI TPS389006/TPS389008
Date: Tue, 17 Nov 2026 15:45:34 -0800
Message-Id: <20261117-lhart-dev-tps38900x-v2-0-e5730523d3ee@witekio.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAB7n/GoC/32NQQ6CMBBFr0Jm7ZihUKGsvIdhAaXIRKWkbSqGc
 HcrB3D5XvLf38Abx8ZDk23gTGTPdk4gThnoqZvvBnlIDILEhZRQ+Jw6F3AwEcPii1oRrTiqQvR
 66EuSFaTl4szI61G9tYkn9sG6z3ES85/934s5ElZUSi1rVeZSXN8czIPtWdsXtPu+fwGJt0Nku
 AAAAA==
X-Change-ID: 20260929-lhart-dev-tps38900x-f932bcdb4057
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Flaviu Nistor <flaviu.nistor@gmail.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 Luna Hart <lhart.opensource@witekio.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794959140; l=3091;
 i=lhart.opensource@witekio.com; s=20260928; h=from:subject:message-id;
 bh=ub3rQB1hEVUcxmYwPcTpjMDC14MRxWhQm8aPzhcMGKQ=;
 b=B0wPX6eZkboYZTGtpv+4lOEOawfyeSbhO4MbEAGM3CqhIBb+avKeyH6bwIXUqCPUnBS0R1V9Z
 PtP4Lt5wV9UBUZvlkYElifUv54I9yTF6YGCJivvZaJssmHRyhfJ/068
X-Developer-Key: i=lhart.opensource@witekio.com; a=ed25519;
 pk=Dm1WPzsg+HuKn11WChbCWrNOk7GD980BnpCdnUwyDuU=
X-Endpoint-Received: by B4 Relay for lhart.opensource@witekio.com/20260928 with auth_id=1079
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a devicetree binding and a hwmon driver for the TI
TPS389006 and TPS389008 I2C voltage supervisors and monitors, with 6 and
8 channels.

The driver reports the voltage measured by the ADC of each channel, and
can enable or disable the monitoring of a channel. The devicetree can
select the voltage range (1x or 4x) of each channel. Otherwise, the
power on state for the scale is used (likely OTP values).

This v2 patch set addresses v1 review comments, and handles parts with
an OTP configuration. There is no single register to indicate if a
channel or chip uses custom OTP values. Thus we assume any OTP
programmable register to have a deliberately set value. We have taken
care to preserve the init state of channels based on the value of
their monitor enable register. Triggering a fault by modifying channel
settings with monitoring enabled may have additional consequences
depending on the hardware layout.

Tested on a TI J784S4 based board with a TPS389006, on a 7.3 based
kernel.

Signed-off-by: Luna Hart <lhart.opensource@witekio.com>
---
Changes in v2:
- Drop the TPS389004, no datasheet or part listing could be found for it
- dt-bindings: rename the file to ti,tps389006.yaml and vmon@N to channel@N
- dt-bindings: child nodes no longer select the channels, unconnected
  inputs are marked with status = "disabled"
- dt-bindings: replace ti,4x-scaling with ti,vrange-multiplier = <1|4>,
  absent keeps the range programmed in the chip
- dt-bindings: document NIRQ and the MON1-MON8 numbering, drop redundant
  descriptions
- dt-bindings: no fallback compatible, the parts differ in channel count
- hwmon: fix the VRANGE_MULT address, it is in bank 1 (0x11f)
- hwmon: never change the range of a channel that is monitoring at probe,
  and respect the configuration write protection
- hwmon: return -ENODATA while the ACT pin is low
- hwmon: fail probe when no match data is found (GENMASK(-1, 0))
- hwmon: cleanups: use the regmap cache instead of a local copy, drop
  <linux/mod_devicetable.h>, "{ }" terminators, /* */ comments,
  devm_kzalloc_obj(), channel counts in Kconfig, sorted Kconfig/Makefile
- Link to v1: https://lore.kernel.org/r/20260929-lhart-dev-tps38900x-v1-0-7045c5894152@witekio.com

---
Luna Hart (2):
      dt-bindings: hwmon: Add TI TPS389006/TPS389008
      hwmon: (tps38900x) Add driver for TI TPS389006/TPS389008

 .../devicetree/bindings/hwmon/ti,tps389006.yaml    | 114 +++++++
 Documentation/hwmon/index.rst                      |   1 +
 Documentation/hwmon/tps38900x.rst                  |  80 +++++
 MAINTAINERS                                        |   8 +
 drivers/hwmon/Kconfig                              |  12 +
 drivers/hwmon/Makefile                             |   1 +
 drivers/hwmon/tps38900x.c                          | 361 +++++++++++++++++++++
 7 files changed, 577 insertions(+)
---
base-commit: 28c252b708a9d223192cbf848d320cf6d0f7ed3a
change-id: 20260929-lhart-dev-tps38900x-f932bcdb4057

Best regards,
-- 
Luna Hart <lhart.opensource@witekio.com>

