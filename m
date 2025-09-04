From: Woodrow Douglass <wdouglass@carnegierobotics.com>
Subject: [PATCH v6 0/2] regulator: pf530x: NXP PF530x regulator driver
Date: Thu, 04 Sep 2025 16:44:34 -0400
Message-Id: <20250902-pf530x-v6-0-ae5efea2198d@carnegierobotics.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADL6uWgC/32QwW7DIBBEfyXi3I3wwhq7p/xH1QPgJUZtTASWl
 Sryvxf7VLVJj6PdeTO7d1E4Ry7i9XAXmZdYYpqqaF8Owo92OjPEoWqBEkn2EuEaSMkbtIMzrse
 mQelFXXa2MLhsJz9u6xdbZs7b4Jo5xNue8PZedcjpAvOY2e5ccr2higYiHUCbjqDvkCBwrxrVB
 Tuo5vTBeeLPY8rnjTjGMqf8tVdecOMKS2hYIoIhO4DukcEqVkCm99YPZlCof1K2Iovarb8PWxA
 khEYSO2mUd83J2+o7R87JpTn6cvTpsvX441TVqVEjm7Yzpn3i3LP142y9EQyaUP9aSfwPgR4Tq
 BJa6ryWitv6lieEdV2/AQ6a1Kv7AQAA
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Woodrow Douglass <wdouglass@carnegierobotics.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2194;
 i=wdouglass@carnegierobotics.com; h=from:subject:message-id;
 bh=Dsw9PRMirZoaLF17M2hBwYns127wF4Tr8AJAlcOjpz0=;
 b=owEBbQGS/pANAwAKAewLuLlPNh4UAcsmYgBoufo4eWMArFN4MqhM2GX2eWEiAKrsbl5Mzystj
 NDq3Un6lIOJATMEAAEKAB0WIQSIUqjrbDLQw0mgxHLsC7i5TzYeFAUCaLn6OAAKCRDsC7i5TzYe
 FAm2CACPxjHcf2RqLaEYzr8FjjWvTcCwTTlak4kVaAXhERlo6zC7nMi7KxzyIa+QSe9jsPdSKyf
 o/k8cMjRACbUdOBbuF5cJKkqaQjRlWWcvT8nPT4eCtxZhqrk/1czceZ2NOz+EsFG59Wyk/rT2zl
 5DJ5qjPtG9Q+Otg5pS3Uw+e5yC8eVv+zsv2Kch4yVTs82Nkq0GW3d9xI5jkQTjRW5t1lifjrtfr
 Lj2cIEk41PfgJt6x0n4xIsgEsyMko0whEGQ9o+ntjMkyn0TZqLNRJwA/5ypSaBwFVHN3Uef22w1
 z4+fDm/jspl5K1Vy/VAHsOk/5Py0cxjNtj3o/32TcXaeMwzp
X-Developer-Key: i=wdouglass@carnegierobotics.com; a=openpgp;
 fpr=8852A8EB6C32D0C349A0C472EC0BB8B94F361E14
X-Endpoint-Received: by B4 Relay for wdouglass@carnegierobotics.com/default with auth_id=514
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I wrote this driver to read settings and state from the nxp pf530x
regulator. Please consider it for inclusion, any criticism is welcome.

Upon re-reviewing the dt binding, I realized I should have referenced
regulator.yaml, so here's v6.

Thanks,
Woodrow Douglass

--
2.39.5

---
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
      regulator: pf530x: dt-bindings: nxp,pf530x-regulator
      regulator: pf530x: Add a driver for the NXP PF5300 Regulator

 .../devicetree/bindings/regulator/nxp,pf5300.yaml  |  54 +++
 MAINTAINERS                                        |   6 +
 drivers/regulator/Kconfig                          |  12 +
 drivers/regulator/Makefile                         |   1 +
 drivers/regulator/pf530x-regulator.c               | 378 +++++++++++++++++++++
 5 files changed, 451 insertions(+)
---
base-commit: b320789d6883cc00ac78ce83bccbfe7ed58afcf0
change-id: 20250902-pf530x-6db7b921120c

Best regards,
-- 
Woodrow Douglass <wdouglass@carnegierobotics.com>

