From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 16:38:50 +0000
Subject: [PATCH 4/9] soc: rockchip: grf: Assign the StreamIDs of the RK3588
 PHP SMMU masters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-mmu600-php-v1-4-231196049a3b@gmail.com>
References: <20261113-mmu600-php-v1-0-231196049a3b@gmail.com>
In-Reply-To: <20261113-mmu600-php-v1-0-231196049a3b@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 David Wu <david.wu@rock-chips.com>, Damien Le Moal <dlemoal@kernel.org>, 
 Niklas Cassel <cassel@kernel.org>, Serge Semin <fancer.lancer@gmail.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-ide@vger.kernel.org, 
 Pranjal Shrivastava <praan@google.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, iommu@lists.linux.dev, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794587927; l=2945;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=dag37i6gDSZWIaoVMOYxt4y005R4Dlb0YjRF9trI+6U=;
 b=49vGgwLh6srLC7rCeOZiRR3OVoJMQYsRvrYhsqpaivjD3acouGe/Nn0e/f0GYUOS9aM3SRTPP
 FuVd8+F7g/nB7Fcqp21LSa4kZV0RLSB5Fg7shF028mEe1uA5poQrzgy
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The StreamIDs of the six masters behind the RK3588 PHP SMMU come from
PHP GRF registers that reset to 0 and are never programmed, so the SMMU
can not tell the masters apart.

Assign StreamIDs 1-6 on both AXI channels. 0 stays unused, so a master
that loses its ID is aborted instead of using another device's tables.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/soc/rockchip/grf.c | 37 +++++++++++++++++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/drivers/soc/rockchip/grf.c b/drivers/soc/rockchip/grf.c
index b459607c118a..3f0f82a2119f 100644
--- a/drivers/soc/rockchip/grf.c
+++ b/drivers/soc/rockchip/grf.c
@@ -168,6 +168,40 @@ static const struct rockchip_grf_info rk3588_sysgrf __initconst = {
 	.num_values = ARRAY_SIZE(rk3588_defaults),
 };
 
+/* PHP SMMU StreamIDs: bits 15:0, no write-enable mask */
+#define RK3588_PHP_GRF_GMAC0_SID_AW	0x0074
+#define RK3588_PHP_GRF_GMAC1_SID_AW	0x007c
+#define RK3588_PHP_GRF_SATA0_SID_AW	0x0084
+#define RK3588_PHP_GRF_SATA1_SID_AW	0x008c
+#define RK3588_PHP_GRF_SATA2_SID_AW	0x0094
+#define RK3588_PHP_GRF_GMAC0_SID_AR	0x009c
+#define RK3588_PHP_GRF_GMAC1_SID_AR	0x00a4
+#define RK3588_PHP_GRF_SATA0_SID_AR	0x00ac
+#define RK3588_PHP_GRF_SATA1_SID_AR	0x00b4
+#define RK3588_PHP_GRF_SATA2_SID_AR	0x00bc
+#define RK3588_PHP_GRF_USB3OTG2_SID_AR	0x00c4
+#define RK3588_PHP_GRF_USB3OTG2_SID_AW	0x00cc
+
+static const struct rockchip_grf_value rk3588_defaults_php_grf[] __initconst = {
+	{ "gmac0 write streamid", RK3588_PHP_GRF_GMAC0_SID_AW, 1 },
+	{ "gmac0 read streamid", RK3588_PHP_GRF_GMAC0_SID_AR, 1 },
+	{ "gmac1 write streamid", RK3588_PHP_GRF_GMAC1_SID_AW, 2 },
+	{ "gmac1 read streamid", RK3588_PHP_GRF_GMAC1_SID_AR, 2 },
+	{ "sata0 write streamid", RK3588_PHP_GRF_SATA0_SID_AW, 3 },
+	{ "sata0 read streamid", RK3588_PHP_GRF_SATA0_SID_AR, 3 },
+	{ "sata1 write streamid", RK3588_PHP_GRF_SATA1_SID_AW, 4 },
+	{ "sata1 read streamid", RK3588_PHP_GRF_SATA1_SID_AR, 4 },
+	{ "sata2 write streamid", RK3588_PHP_GRF_SATA2_SID_AW, 5 },
+	{ "sata2 read streamid", RK3588_PHP_GRF_SATA2_SID_AR, 5 },
+	{ "usb3otg2 write streamid", RK3588_PHP_GRF_USB3OTG2_SID_AW, 6 },
+	{ "usb3otg2 read streamid", RK3588_PHP_GRF_USB3OTG2_SID_AR, 6 },
+};
+
+static const struct rockchip_grf_info rk3588_phpgrf __initconst = {
+	.values = rk3588_defaults_php_grf,
+	.num_values = ARRAY_SIZE(rk3588_defaults_php_grf),
+};
+
 static const struct of_device_id rockchip_grf_dt_match[] __initconst = {
 	{
 		.compatible = "rockchip,rk3036-grf",
@@ -202,6 +236,9 @@ static const struct of_device_id rockchip_grf_dt_match[] __initconst = {
 	}, {
 		.compatible = "rockchip,rk3576-ioc-grf",
 		.data = (void *)&rk3576_iocgrf,
+	}, {
+		.compatible = "rockchip,rk3588-php-grf",
+		.data = (void *)&rk3588_phpgrf,
 	}, {
 		.compatible = "rockchip,rk3588-sys-grf",
 		.data = (void *)&rk3588_sysgrf,

-- 
2.55.0

