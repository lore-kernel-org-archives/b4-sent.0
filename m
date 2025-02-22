From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sat, 22 Feb 2025 14:34:16 +0100
Subject: [PATCH v2 2/2] riscv: dts: starfive: fml13v01: increase eMMC bus
 speed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250222-fml13v01_emmc_speed-v2-2-3ffc5b1f5663@hotmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740231263; l=1059;
 i=maud_spierings@hotmail.com; s=20250222; h=from:subject:message-id;
 bh=6oKEZmpEgAskDT6drBgPswULe7sk6pmiFucVopPkPkQ=;
 b=HISq9mxkhULqrOz8w55mew/rcWCHUqglVyJ7IgxAcKmWD/2YQN766hisLl/aobRLIwGdeNfp3
 sjHDAQxsHuyAQDKnhr3zIIoSHBveLa/iQIAvP6iCeHcVt98HumFzn2c
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=Z2m97WkDS9Sm3JnKpIpH4JwQtLm2Yw8oFCNw6uMBqb8=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20250222 with auth_id=346
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The assigned clock speed of 50 MHz is limitting this interface which is
SDIO 5.0 capable. Sadly at 200MHz it fails to mount an eMMC drive,
150MHz (really 132 MHz) is the highest it was able to get.

This improves the seq read/write performance by 2x~

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 arch/riscv/boot/dts/starfive/jh7110-deepcomputing-fml13v01.dts | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/riscv/boot/dts/starfive/jh7110-deepcomputing-fml13v01.dts b/arch/riscv/boot/dts/starfive/jh7110-deepcomputing-fml13v01.dts
index 8d9ce8b69a71be78ca57618ae842c9f415648450..63b539bedd63d39dbe2096f85aaf70ba6ab64d29 100644
--- a/arch/riscv/boot/dts/starfive/jh7110-deepcomputing-fml13v01.dts
+++ b/arch/riscv/boot/dts/starfive/jh7110-deepcomputing-fml13v01.dts
@@ -11,6 +11,10 @@ / {
 	compatible = "deepcomputing,fml13v01", "starfive,jh7110";
 };
 
+&mmc0 {
+	assigned-clock-rates = <150000000>;
+};
+
 &pcie1 {
 	perst-gpios = <&sysgpio 21 GPIO_ACTIVE_LOW>;
 	phys = <&pciephy1>;

-- 
2.48.1

