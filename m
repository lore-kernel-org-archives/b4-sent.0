From: Maud Spierings <maudspierings@gocontroll.com>
Date: Fri, 14 Nov 2025 16:05:17 +0100
Subject: [PATCH] net: designware-imx: don't set txclk when mode is (r)mii
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251114-eqos_rmii-v1-1-4a20cf7cb4c0@gocontroll.com>
X-B4-Tracking: v=1; b=H4sIACxFF2kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQ0MT3dTC/OL4otzMTN2U5FRjY2PDxBQzSyMloPqCotS0zAqwWdGxtbU
 AMT8SMlsAAAA=
X-Change-ID: 20251114-eqos_rmii-dce3331ad692
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763132724; l=1670;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=tOSLmMs/KpGwyt0ek3xHU7qFx3qbudcwf+JlrqEQhdw=;
 b=Snv/t+eDOO5OiW80jIPvSfeLBD+TDJjgDXKIJf4gxD8hSO9cnoNdybUfLYrBndsoAGZnpDiyO
 ZVm9ugFZ9G0DtUFvAvki4D9H4mgKEhbiCILEy2EJBc+2z8gXvBoTc1z
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an early exit to eqos_set_txclk() when the mode is (r)mii.

The "tx" clock is actually something called the "slice 81 clock" which
must always be 50M for the rmii mode. This will later get divided into
the actual tx clock /2 or /20 which does match those clock rates. Still
the provided clock != tx clock when the mode is rmii.

Linux also excludes the mii mode from this clock lookup, even though
the clock rates actually seem to match there. I am not aware why it is
also excluded, it may be best to wait with merging this until [1] has
found an answer. But for now I thought it would be best to match Linux
behaviour.

Link: https://lore.kernel.org/all/aRclKDeHzfJSzpQ3@shell.armlinux.org.uk/ [1]

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 drivers/net/designware_imx.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/net/designware_imx.c b/drivers/net/designware_imx.c
index ec3558fad0..bc3136f8ff 100644
--- a/drivers/net/designware_imx.c
+++ b/drivers/net/designware_imx.c
@@ -59,10 +59,15 @@ static unsigned long eqos_get_csr_clk_rate_imx(struct eqos *eqos)
 
 static int eqos_set_txclk(struct eqos *eqos, int speed)
 {
+	phy_interface_t interface = eqos->interface;
 	struct eqos_imx_priv *priv = eqos->priv;
 	unsigned long rate;
 	int ret;
 
+	if (interface == PHY_INTERFACE_MODE_RMII ||
+	    interface == PHY_INTERFACE_MODE_MII)
+		return 0;
+
 	switch (speed) {
 	case SPEED_10:
 		rate = 2500000;

---
base-commit: f485ddfccf960959d25462073528d314b8bf1aea
change-id: 20251114-eqos_rmii-dce3331ad692

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

