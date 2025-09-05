From: Woodrow Douglass <wdouglass@carnegierobotics.com>
Subject: [PATCH v7 0/2] regulator: pf530x: NXP PF530x regulator driver
Date: Fri, 05 Sep 2025 08:39:41 -0400
Message-Id: <20250902-pf530x-v7-0-10eb2542f944@carnegierobotics.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA3aumgC/33QwW7DIAwG4FepOM8VMTiEnvoe0w5ATIO2JhWJo
 k5V332Q07S1PVr4/2x8EzPnxLM47G4i85rmNI2lMG87EQY3nhhSX2qBEklaiXCJpOQV2t4bb7F
 pUAZRmr2bGXx2Yxhq+9nNC+f6cMkc03Wb8P5R6pinMyxDZre55K2hQgORjqBNR2A7JIhsVaO66
 HrVHD85j/y1n/KpikOalyl/byuvWF3hCA1LRDDketAWGZxiBWRscKE3vUL9W6mLrGqL/v3YiiA
 hNpLYS6OCb47BldwpcZ78tKQw78N0rnv8S6qS1KiRTdsZ0z5JbrP149m6CgZNLHctEr8Q6LFAR
 WipC1oqbstZXgjtY6EtgmPiyA4b2/VPhPv9/gOMj28WPQIAAA==
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Woodrow Douglass <wdouglass@carnegierobotics.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2451;
 i=wdouglass@carnegierobotics.com; h=from:subject:message-id;
 bh=tuNjf+8cgNDQrXfELfd8MfwKaydQiJBd15X3JTiaVHs=;
 b=owEBbQGS/pANAwAKAewLuLlPNh4UAcsmYgBoutohDHhJ5uUpBNqYocZVZoMS8Xc2VjO5yhkD2
 eKNYeo4szCJATMEAAEKAB0WIQSIUqjrbDLQw0mgxHLsC7i5TzYeFAUCaLraIQAKCRDsC7i5TzYe
 FGk8B/9ZBU4eLtPe/tBr10uO4xRYoPCCt+c/ptYIyUsqqaJmKdsJMPnZStKFfqSsoKp+pW5Xq6j
 +tjojpaMK1HNmQwztwpr02u+21CTFXiD2ZoUTGo07qVBrpjgA8JCeRf2YxxFM/mcphkRhS8KAzn
 KlQX0Z2kA2Qp/vDMSRIIwjxkBbwF7bKX4P5TA+iFP9Qjj2YoRbaE97nneJPncPdGbnOA+u7Q6p4
 W9Bounm/XiaX0ZUQpay+a9Y1e976vA4UgQ3nclh+xB1lf8JBfI5e2dyYVZH03n3HwJQmwO5Xkex
 sr9+0fmH/chPBluCPwTG1/LIXXvb3pJ0m0e3TQLLDey0si5z
X-Developer-Key: i=wdouglass@carnegierobotics.com; a=openpgp;
 fpr=8852A8EB6C32D0C349A0C472EC0BB8B94F361E14
X-Endpoint-Received: by B4 Relay for wdouglass@carnegierobotics.com/default with auth_id=514
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I wrote this driver to read settings and state from the nxp pf530x
regulator. Please consider it for inclusion, any criticism is welcome.

Thanks,
Woodrow Douglass

--
2.39.5

---
Changes in v7:.
- make vrange and pf530x_range_desc const, removed unused driver_data pointer
- Drop "nxp,pf5301" and "nxp,pf5302" from of_device_id list, allow fallback
- Add Reviewed-by to the dt-binding from Krzysztof Kozlowski (Thanks!)
- Link to v6: https://lore.kernel.org/r/20250902-pf530x-v6-0-ae5efea2198d@carnegierobotics.com

Changes in v6:
- Make sure that the device tree binding properly references regulator.yaml
- Link to v5: https://lore.kernel.org/r/20250902-pf530x-v5-0-658c403e6a52@carnegierobotics.com

Changes in v5:
- Fixed compatibility match to properly fall back to pf5300
- Reordered patches so that devicetree schema comes before the driver itself
- Modified nxp,pf5300 schema to pass `make dt_binding_check`
- Link to v4: https://lore.kernel.org/r/20250902-pf530x-v4-0-4727f112424e@carnegierobotics.com

Changes in v4:
- Added REGULATOR_ERROR_OVER_TEMP_WARN to pf530x_get_error_flags
- Added EMREV to the info print
- Link to v3: https://lore.kernel.org/r/20250902-pf530x-v3-0-4242e7687761@carnegierobotics.com

Changes in v3:
- Replaced REGCACHE_RBTREE with REGCACHE_MAPLE
- Replaced pf530x_is_enabled function with regulator_is_enabled_regmap
- Added status bits from INT_SENSE1 to pf530x_get_status function
- Added extra context to info print upon chip identification
- Reworked devtree to not require nested "regulators" subnode
- Some minor reformatting of comment style and long lines
- Link to v2: https://lore.kernel.org/r/20250902-pf530x-v2-0-f105eb073cb1@carnegierobotics.com

---
Woodrow Douglass (2):
      regulator: dt-bindings: nxp,pf530x: Add NXP PF5300/PF5301/PF5302 PMICs
      regulator: pf530x: Add a driver for the NXP PF5300 Regulator

 .../devicetree/bindings/regulator/nxp,pf5300.yaml  |  54 +++
 MAINTAINERS                                        |   6 +
 drivers/regulator/Kconfig                          |  12 +
 drivers/regulator/Makefile                         |   1 +
 drivers/regulator/pf530x-regulator.c               | 375 +++++++++++++++++++++
 5 files changed, 448 insertions(+)
---
base-commit: b320789d6883cc00ac78ce83bccbfe7ed58afcf0
change-id: 20250902-pf530x-6db7b921120c

Best regards,
-- 
Woodrow Douglass <wdouglass@carnegierobotics.com>

