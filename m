From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sat, 15 Feb 2025 10:46:47 +0100
Subject: [PATCH] riscv: dts: starfive: fml13v01: increase eMMC bus speed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250215-fml13v01_emmc_speed-v1-1-e3bd224ae0e8@hotmail.com>
X-B4-Tracking: v=1; b=H4sIAIZisGcC/x3MTQqAIBBA4avErBMc0/6uEhGVUw1kiUIE0d2Tl
 t/ivQciBaYIbfZAoIsjn0cC5hnM23isJNgmg5LKSIVGLG7H4pI4kHPzED2RFWVVo5psM2mpIZU
 +0ML3f+369/0AZumOPWUAAAA=
X-Change-ID: 20250215-fml13v01_emmc_speed-67812bd9b404
To: Conor Dooley <conor@kernel.org>, Emil Renner Berthing <kernel@esmil.dk>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-riscv@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739612809; l=1547;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=Qt3zVrtNxWWmhv3zol8ojyDROGvggaowhiJ4UV1nnpE=;
 b=ABsIVsrA7IzSOMBc4BWZIT3O7KPYMp7Yc8IZ6p9dAl9a6kVX4JD1KwgZJwIhwFCZ5hE8xVmRr
 dSiZK0HOv4SBEbNstLQNVK3+ycPP0TrdD42NBGv3rCQEFrVCIdDw6Ni
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The assigned clock speed of 50 MHz is and max-frequency of 100MHz are
limitting this interface which is SDIO 5.0 capable. Sadly at 200MHz it
fails to mount an eMMC drive, 150MHz (really 132 MHz) is the highest it
was able to get.

This improves the seq read/write performance by 2x~

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
I put this in this specific dts instead of the common one as I cannot
test if other boards are also able to handle these speeds.

This patch depends on [1]

[1]: https://lore.kernel.org/all/20250207093618.126636-1-sandie.cao@deepcomputing.io/
---
 arch/riscv/boot/dts/starfive/jh7110-deepcomputing-fml13v01.dts | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/riscv/boot/dts/starfive/jh7110-deepcomputing-fml13v01.dts b/arch/riscv/boot/dts/starfive/jh7110-deepcomputing-fml13v01.dts
index 8d9ce8b69a71be78ca57618ae842c9f415648450..1f4bac9f89463a6af844b8f1743bdfa659e612ab 100644
--- a/arch/riscv/boot/dts/starfive/jh7110-deepcomputing-fml13v01.dts
+++ b/arch/riscv/boot/dts/starfive/jh7110-deepcomputing-fml13v01.dts
@@ -11,6 +11,11 @@ / {
 	compatible = "deepcomputing,fml13v01", "starfive,jh7110";
 };
 
+&mmc0 {
+	max-frequency = <200000000>;
+	assigned-clock-rates = <150000000>;
+};
+
 &pcie1 {
 	perst-gpios = <&sysgpio 21 GPIO_ACTIVE_LOW>;
 	phys = <&pciephy1>;

---
base-commit: 0bc08ec1ff5a32449d2b04704173dbf3ebd6b014
change-id: 20250215-fml13v01_emmc_speed-67812bd9b404

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

