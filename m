From: Ben Zong-You Xie <ben717@andestech.com>
Subject: [PATCH v5 0/4] i2c: add support for Andes platform
Date: Tue, 11 Aug 2026 14:29:47 +0800
Message-Id: <20260811-atciic100-v5-0-1d306c21dba3@andestech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFvBemoC/22Q3UrEMBBGX2XJtVkmM2nTeuV7iBftZGIj2C5ND
 crSdzdZEYvs5QffOfNzVUnWKEk9nq5qlRxTXOYSmoeT4mmYX0VHX7JCwBYMgh42jpENgPYDCbd
 dcONoVelfVgnx8+Z6fvnJ6WN8E96qoDammLZl/boNy6b2qrcBBAdoeqQz9gbJkTZ6lNkZ9zTMX
 tImPJ15eVdVm/EXrAvhYaGMGrRrmt5Q68FxuEfTke6ONBW6YwAMzFhuukfbP5ro+IxsC+0tdIi
 hJbHyn973/RuQfjhnbQEAAA==
X-Change-ID: 20260120-atciic100-da3ec68f7bb4
To: Andi Shyti <andi.shyti@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-i2c@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-riscv@lists.infradead.org, 
 Ben Zong-You Xie <ben717@andestech.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15-dev-09770
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786429789; l=2993;
 i=ben717@andestech.com; s=20260120; h=from:subject:message-id;
 bh=F0l8Ut4ZSPuzkllETcP01MYrU4Q5hmpjs05TRDA+HiQ=;
 b=HKTFdPEC6pUA6QPei0OVVHl8dgqgE4cYDe1MsiqCWNO/e6ODJ+BEX8vpehIgjfJCIRHExBDsI
 3uKnwMHbA1jAjno/ou9kgNMNBdYEunwaYt/pdVd9kIW+oXf2JdWLAkd
X-Developer-Key: i=ben717@andestech.com; a=ed25519;
 pk=nb8L7zQKGJpYk0yvrYKjViOZ34A36g1ZIsCmCsP518s=
X-Endpoint-Received: by B4 Relay for ben717@andestech.com/20260120 with auth_id=610
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds I2C support to Andes platform, such as AE350 and
QiLai SoC.

Signed-off-by: Ben Zong-You Xie <ben717@andestech.com>
---
Changes in v5:
- Rebased on andi.shyti/i2c/i2c-host-next. No logical changes.
- Link to v4: https://patch.msgid.link/20260330-atciic100-v4-0-d40822f63e4e@andestech.com

Changes in v4:
- Rebased on andi.shyti/i2c/i2c-host-next.
- (1/4)
  - Added Conor's acked by tag.

- Link to v3: https://patch.msgid.link/20260128-atciic100-v3-0-8c002fcc2bb4@andestech.com

Changes in v3:
- (1/4)
  - Rewrote the commit message to provide a detailed hardware
    description and explain the relationship between the ATCIIC100 IP,
    the AE350 platform, and the QiLai SoC. (Krzysztof)

- Link to v2: https://patch.msgid.link/20260122-atciic100-v2-0-7559136d07cf@andestech.com

Changes in v2:
- ATCIIC100 is the hardware name for the Andes I2C controller and was used
  throughout v1. However, since Device Tree bindings should reflect the hardware
  identity and driver/config naming typically follows the i2c-<soc/platform>
  convention, this version replaces occurrences of "atciic100" with more
  appropriate names, such as "i2c-andes" or "andes_i2c," to align with upstream
  standards.
- Updated cover letter title and the description.
- Rebased on andi.shyti/i2c/i2c-host-next.
- (1/4)
  - Updated the title and the description of the patch.
  - Specified what the hardware is, and modify the title and compatibles. (Krzysztof)
  - Corrected device register size.
- (2/4)
  - Updated the title and the description of the patch.
  - Replaced the readl/writel operations with regmap APIs.
  - Replaced all occurrences of atciic100 with proper names.
  - Used module_platform_driver() to initialize. (Andi)
  - Moved CONFIG_I2C_ANDES (CONFIG_I2C_ATCIIC100 in v1) to the
    "Embedded system I2C/SMBus host controller drivers" section.
  - Made CONFIG_I2C_ANDES depend on ARCH_ANDES
- (3/4) (new)
  - Added an entry to the MAINTAINERS file.
- (4/4) (new)
  - Added the I2C node to QiLai DTS.

- Link to v1: https://patch.msgid.link/20250207021923.2912373-1-ben717@andestech.com

---
Ben Zong-You Xie (4):
      dt-bindings: i2c: add support for AE350 I2C controller
      i2c: add Andes I2C driver support
      MAINTAINERS: add an entry for Andes I2C driver
      riscv: dts: andes: qilai: add I2C controller

 .../bindings/i2c/andestech,ae350-i2c.yaml          |  45 +++
 MAINTAINERS                                        |   6 +
 arch/riscv/boot/dts/andes/qilai.dtsi               |   7 +
 drivers/i2c/busses/Kconfig                         |  10 +
 drivers/i2c/busses/Makefile                        |   1 +
 drivers/i2c/busses/i2c-andes.c                     | 341 +++++++++++++++++++++
 6 files changed, 410 insertions(+)
---
base-commit: 04e9bf1648f846976b543e91c1838a712433772a
change-id: 20260120-atciic100-da3ec68f7bb4

Best regards,
--  
Ben Zong-You Xie <ben717@andestech.com>

