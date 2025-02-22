From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sat, 22 Feb 2025 14:34:15 +0100
Subject: [PATCH v2 1/2] riscv: dts: starfive: jh7110-common: increase mmc0
 max-frequency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250222-fml13v01_emmc_speed-v2-1-3ffc5b1f5663@hotmail.com>
References: <20250222-fml13v01_emmc_speed-v2-0-3ffc5b1f5663@hotmail.com>
In-Reply-To: <20250222-fml13v01_emmc_speed-v2-0-3ffc5b1f5663@hotmail.com>
To: Conor Dooley <conor@kernel.org>, Emil Renner Berthing <kernel@esmil.dk>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-riscv@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740231263; l=940;
 i=maud_spierings@hotmail.com; s=20250222; h=from:subject:message-id;
 bh=9gpWZSvQty4+e5gTi1J7LPpp/QLLJlyJMT9QPxYPoKE=;
 b=rQTRH8W8l+k+6KB0J0uKhxBq/QXMk1rJFTrbIikh0K5xR2A2el+LTzrFxUY/2eLhWxsKKKjOe
 zpIVYF513UsARWE/+kqYcS0q6813bnBnPMX+/60ALoEeN0RWuHr3BK/
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=Z2m97WkDS9Sm3JnKpIpH4JwQtLm2Yw8oFCNw6uMBqb8=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20250222 with auth_id=346
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This sdio interface is capable of more than 100 MHz as already indicated
by the cap_hs200-1_8v attribute. Increase the max-frequency to 200 MHz
so users of this dtsi can increase their SDIO bus speed.

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 arch/riscv/boot/dts/starfive/jh7110-common.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/riscv/boot/dts/starfive/jh7110-common.dtsi b/arch/riscv/boot/dts/starfive/jh7110-common.dtsi
index dd2eefc295e5c8b568a02104ec2189e66b378904..19ca8dc24617c2ad565a4a9b2d9af9bd9491f22e 100644
--- a/arch/riscv/boot/dts/starfive/jh7110-common.dtsi
+++ b/arch/riscv/boot/dts/starfive/jh7110-common.dtsi
@@ -258,7 +258,7 @@ &i2c6 {
 };
 
 &mmc0 {
-	max-frequency = <100000000>;
+	max-frequency = <200000000>;
 	assigned-clocks = <&syscrg JH7110_SYSCLK_SDIO0_SDCARD>;
 	assigned-clock-rates = <50000000>;
 	bus-width = <8>;

-- 
2.48.1

