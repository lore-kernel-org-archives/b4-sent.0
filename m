From: Oleg Kombarov <ok563595@gmail.com>
Date: Fri, 14 Aug 2026 20:42:55 +0700
Subject: [PATCH] pci: pcie_dw_rockchip: add PCIe reset configuration delay
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260814-pci-rockchip-perst-delay-v1-1-dde1904d9b87@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CQAxA0auQrm3CDEbAqxgWQylQNTBpgWgId
 3fU5Vv8v4OxChtcsx2UNzGZpwR3yoDGMA2M0iWDz/0lr9wZIwnqTA8aJWJktQU7foY31nXliyK
 Urm8dpDwq9/L6rW/N37a2d6bl+4Pj+AACBS1LfAAAAA==
X-Change-ID: 20260814-pci-rockchip-perst-delay-998233a71fb1
To: Simon Glass <sjg@chromium.org>, u-boot@lists.u-boot-project.org
Cc: Quentin Schulz <u-boot@0leil.net>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Yao Zi <me@ziyao.cc>, Peng Fan <peng.fan@nxp.com>, 
 Oleg Kombarov <ok563595@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786714975; l=2135;
 i=ok563595@gmail.com; s=20260814; h=from:subject:message-id;
 bh=74wBb9m2GnuOkRHqU23/NIffQe3sJ6lsA4lNCCBSlvQ=;
 b=X4FxivtvX9HcEVsz7UYEeN44WQ0HFLggRa3fil3mraHUKXjLxs8mZf3oC+ZvbnbWNWk6VysXs
 U7DsQT9+Za4C8tvhTcijYTOG1tNJJxeOdQ0wnT4cFAZAgddXQSrudlz
X-Developer-Key: i=ok563595@gmail.com; a=ed25519;
 pk=BkA5Dnbry6YAJS4cn/HnsXFv/FmHKxoQUkfowiJxipI=
X-Endpoint-Received: by B4 Relay for ok563595@gmail.com/20260814 with auth_id=949
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PCIe r6.0 sec 6.6.1 requires a 100 ms delay before the first
Configuration Request.

For ports supporting up to 5.0 GT/s, the delay is measured from
the end of Conventional Reset. For faster ports, it is measured
from the end of Link Training.

The Rockchip DesignWare PCIe driver currently deasserts PERST# and
proceeds after Link Training without guaranteeing these delays.
A fast-training endpoint may therefore receive its first
Configuration Request too early.

Apply the required delay according to the maximum supported link
speed.

This fixes PCIe enumeration of a MAXIO MAP1202 NVMe device on an
Orange Pi 5 (RK3588S), where enumeration was timing-sensitive and
could hang without the additional delay.

Signed-off-by: Oleg Kombarov <ok563595@gmail.com>
---
 drivers/pci/pcie_dw_rockchip.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/pci/pcie_dw_rockchip.c b/drivers/pci/pcie_dw_rockchip.c
index 61117fa95e6..322b0be9771 100644
--- a/drivers/pci/pcie_dw_rockchip.c
+++ b/drivers/pci/pcie_dw_rockchip.c
@@ -267,6 +267,14 @@ static int rk_pcie_link_up(struct rk_pcie *priv)
 	mdelay(100);
 	if (dm_gpio_is_valid(&priv->rst_gpio))
 		dm_gpio_set_value(&priv->rst_gpio, 1);
+	/*
+	 * PCIe r6.0 sec 6.6.1 requires a 100 ms delay before the first
+	 * Configuration Request. For ports supporting up to 5.0 GT/s, measure
+	 * the delay from the end of Conventional Reset. For faster ports,
+	 * measure it from the end of Link Training.
+	 */
+	if (priv->gen <= LINK_SPEED_GEN_2)
+		mdelay(100);
 
 	/* Check if the link is up or not */
 	for (retries = 0; retries < 10; retries++) {
@@ -282,6 +290,9 @@ static int rk_pcie_link_up(struct rk_pcie *priv)
 		return -EIO;
 	}
 
+	if (priv->gen > LINK_SPEED_GEN_2)
+		mdelay(100);
+
 	dev_info(priv->dw.dev, "PCIe Link up, LTSSM is 0x%x\n",
 		 rk_pcie_readl_apb(priv, PCIE_CLIENT_LTSSM_STATUS));
 	rk_pcie_debug_dump(priv);

---
base-commit: 527115ef6783cec49e5610c523c124b399011361
change-id: 20260814-pci-rockchip-perst-delay-998233a71fb1

Best regards,
--  
Oleg Kombarov <ok563595@gmail.com>

