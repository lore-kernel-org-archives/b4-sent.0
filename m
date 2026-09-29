From: Luna Hart <lhart.opensource@witekio.com>
Subject: [PATCH 0/2] hwmon: Add support for TI
 TPS389004/TPS389006/TPS389008
Date: Tue, 29 Sep 2026 16:04:03 -0700
Message-Id: <20260929-lhart-dev-tps38900x-v1-0-7045c5894152@witekio.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAONDvGoC/x3MSwqAMAwA0atI1gZi/dariIvWRg2ISitSEO9uc
 fkWMw8E9sIB+uwBz7cEOfaEIs9gWs2+MIpLBkWqIa00bqvxFzq+8TpD2WmiiLMulZ2crahuIZW
 n51nifx3G9/0AoJCU3mUAAAA=
X-Change-ID: 20260929-lhart-dev-tps38900x-f932bcdb4057
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Flaviu Nistor <flaviu.nistor@gmail.com>, 
 Luna Hart <lhart.opensource@witekio.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790723106; l=1463;
 i=lhart.opensource@witekio.com; s=20260928; h=from:subject:message-id;
 bh=UVIH989FrHhWR2tRZRtFqOaPdbLHHUMNwpfyKxWgAnc=;
 b=B1TWvhGM3hqg+fSTDhaelUjQz/pbyOtVymIs0Ud7JeR7Bq8oRy/hgK4+vl6q0hTty1lljKR3H
 FN9QA0SEVYABF0wz1AouCN6Cv1GF6LHm3KStYS/BpXJN/yL72MMkCmj
X-Developer-Key: i=lhart.opensource@witekio.com; a=ed25519;
 pk=Dm1WPzsg+HuKn11WChbCWrNOk7GD980BnpCdnUwyDuU=
X-Endpoint-Received: by B4 Relay for lhart.opensource@witekio.com/20260928 with auth_id=1079
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a binding and hwmon driver for the TI TPS38900x family
of I2C voltage supervisor/monitors. The driver implements voltage
monitoring functionality from the ADCs of the monitor chip. It supports
basic configuration of voltage channels, specifically the ability to set
the high-range (4x) voltage scale.

Tested on TI J784S4 on custom hardware with a TPS389006. Kernel 6.18 was
used with these patches during testing.

This is built atop previous unmerged work from Flaviu Nistor, but
features a large rewrite of the driver to utilize regmaps.

Signed-off-by: Luna Hart <lhart.opensource@witekio.com>
---
Luna Hart (2):
      dt-bindings: hwmon: Add TI TPS389004/TPS389006/TPS389008
      hwmon: (tps38900x) Add driver for TI TPS389004/TPS389006/TPS389008

 .../devicetree/bindings/hwmon/ti,tps38900x.yaml    | 137 ++++++++++
 Documentation/hwmon/index.rst                      |   1 +
 Documentation/hwmon/tps38900x.rst                  |  55 ++++
 MAINTAINERS                                        |   8 +
 drivers/hwmon/Kconfig                              |  11 +
 drivers/hwmon/Makefile                             |   1 +
 drivers/hwmon/tps38900x.c                          | 281 +++++++++++++++++++++
 7 files changed, 494 insertions(+)
---
base-commit: 4781ca52761e666cf18b591e6bb0478396c90320
change-id: 20260929-lhart-dev-tps38900x-f932bcdb4057

Best regards,
-- 
Luna Hart <lhart.opensource@witekio.com>

