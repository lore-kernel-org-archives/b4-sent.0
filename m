From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Thu, 13 Aug 2026 11:05:43 -0700
Subject: [PATCH] net: pcs: rzn1-miic: Fix config array initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-rzn1-miic-fix-array-v1-1-b58cafcc917e@reliablecontrols.com>
X-B4-Tracking: v=1; b=H4sIAHYHfmoC/x2MywqAIBAAfyX23IJaWfQr0UFsqz1ksUL0wH9PO
 g7DzAuRhClCX7wgdHLkPWTQZQF+dWEh5CkzGGWs6nSF8gSNG7PHmS90Iu5Gso7qujFe6RZyeQh
 l+V+HMaUPc70WemUAAAA=
To: =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-renesas-soc@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786644474; l=955;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=BtDQcKBUscYFPfDwz7/zdJWFfzqi9hfRlPaUZT9xiEk=;
 b=A3twDS2mCEsk2z9LmIcqsg6FCVfB4pvoNTgeU/H8vkyZGDqhPHdv3nL8sYUfL3GCp/RNE8qX1
 D0GqCsLOo6zAL1sNOvbmkErvxWZtiIzD7UF/EeFQGWyifNxfmvEvUP4
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix memset parameters to initialize the entire DT value array

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
 drivers/net/pcs/pcs-rzn1-miic.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/pcs/pcs-rzn1-miic.c b/drivers/net/pcs/pcs-rzn1-miic.c
index 2b72fa98ddf1..ad4433971e50 100644
--- a/drivers/net/pcs/pcs-rzn1-miic.c
+++ b/drivers/net/pcs/pcs-rzn1-miic.c
@@ -683,7 +683,7 @@ static int miic_parse_dt(struct miic *miic, u32 *mode_cfg)
 	if (!dt_val)
 		return -ENOMEM;
 
-	memset(dt_val, MIIC_MODCTRL_CONF_NONE, sizeof(*dt_val));
+	memset(dt_val, MIIC_MODCTRL_CONF_NONE, miic->of_data->conf_conv_count);
 
 	if (of_property_read_u32(np, "renesas,miic-switch-portin", &conf) == 0)
 		dt_val[0] = conf;

---
base-commit: 9006c116dd111d457bf5d074990210f70a4ad2c8
change-id: 20260813-rzn1-miic-fix-array-e6ae4452c017

Best regards,
-- 
Kyle Hendry <khendry@reliablecontrols.com>

