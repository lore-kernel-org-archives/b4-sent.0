From: Maud Spierings <maud_spierings@hotmail.com>
Subject: [PATCH v2 0/2] riscv: dts: starfive: jh7110: increase eMMC bus
 speed
Date: Sat, 22 Feb 2025 14:34:14 +0100
Message-Id: <20250222-fml13v01_emmc_speed-v2-0-3ffc5b1f5663@hotmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFbSuWcC/32NQQ6CMBBFr0JmbU1nAEVX3sMQAnSQSSglLWk0h
 LtbOYDL95L//gaBvXCAe7aB5yhB3JyAThn0Yzu/WIlJDKSp1ISlGuyEedTYsLV9ExZmoy7XCqk
 zt67QBaTl4nmQ91F91olHCavzn+Mk4s/+70VUqDjvDFHRsubqMbrVtjKde2eh3vf9Cxahi4m4A
 AAA
X-Change-ID: 20250215-fml13v01_emmc_speed-67812bd9b404
To: Conor Dooley <conor@kernel.org>, Emil Renner Berthing <kernel@esmil.dk>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-riscv@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740231263; l=1048;
 i=maud_spierings@hotmail.com; s=20250222; h=from:subject:message-id;
 bh=H4tUwQx9kES2MajEfXKp73q3XQ8Ce/GEw2CwrT3eRLI=;
 b=AKDOcG4/fMadkNRP0txy87XkPD7kQ0hQednAf1KSYpBbTV8P4jL3Ix2rrQUFz2EQo2GXT32kU
 zYr1qxlZp8ID1p+0GI8Vt88E2EzaXlaGc38fx7tPZF1slc3bJXvwH+n
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=Z2m97WkDS9Sm3JnKpIpH4JwQtLm2Yw8oFCNw6uMBqb8=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20250222 with auth_id=346
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The deepcomputing fml13v01 eMMC memory slot is currently limited in
speed by the common definition, increase the common max-frequency
parameter and specifically increase the clock on the fml13v01 board.

This achieves a x2~ speed increase in seq read/write performance.

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
Changes in v2:
- Move max-frequency increase to jh7110-common
- Link to v1: https://lore.kernel.org/r/20250215-fml13v01_emmc_speed-v1-1-e3bd224ae0e8@hotmail.com

---
Maud Spierings (2):
      riscv: dts: starfive: jh7110-common: increase mmc0 max-frequency
      riscv: dts: starfive: fml13v01: increase eMMC bus speed

 arch/riscv/boot/dts/starfive/jh7110-common.dtsi                | 2 +-
 arch/riscv/boot/dts/starfive/jh7110-deepcomputing-fml13v01.dts | 4 ++++
 2 files changed, 5 insertions(+), 1 deletion(-)
---
base-commit: 0bc08ec1ff5a32449d2b04704173dbf3ebd6b014
change-id: 20250215-fml13v01_emmc_speed-67812bd9b404

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

