From: Yang Xiwen <forbidden405@outlook.com>
Date: Sun, 25 Feb 2024 08:38:33 +0800
Subject: [PATCH RESEND] serial: pl01x: set baudrate when probing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240225-b4-pl011-v1-1-2686496c1a17@outlook.com>
To: u-boot@lists.denx.de, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>
Cc: Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708821513; l=1471;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=wFtp8JoYVTLrWd010MWe1rn493w7ENxVoxhvFpDp7q4=;
 b=mwg1kme2Jf0rKcyD0nWu9RqFoZOcw6JZjDRrZdKP1EaqOTJGuQeq3ljfDarZSq/1qBsBKAHJd
 gU3LTYFIXs+DRCczgB04wlQOLdHzn80X4HbY0UiJkRClbWeU3bukLYg
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It is found that when DM is enabled, only generic init function is
called in .probe(). Baudrate is never honored. Add a function call
to .setbrg() when probing so that we can update the baudrate of the
serial device.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/serial/serial_pl01x.c | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/drivers/serial/serial_pl01x.c b/drivers/serial/serial_pl01x.c
index 428a4d210de5..57bbcaf3b619 100644
--- a/drivers/serial/serial_pl01x.c
+++ b/drivers/serial/serial_pl01x.c
@@ -290,6 +290,7 @@ int pl01x_serial_probe(struct udevice *dev)
 {
 	struct pl01x_serial_plat *plat = dev_get_plat(dev);
 	struct pl01x_priv *priv = dev_get_priv(dev);
+	int ret;
 
 #if CONFIG_IS_ENABLED(OF_PLATDATA)
 	struct dtd_serial_pl01x *dtplat = &plat->dtplat;
@@ -301,10 +302,14 @@ int pl01x_serial_probe(struct udevice *dev)
 #endif
 	priv->type = plat->type;
 
-	if (!plat->skip_init)
-		return pl01x_generic_serial_init(priv->regs, priv->type);
-	else
+	if (!plat->skip_init) {
+		ret = pl01x_generic_serial_init(priv->regs, priv->type);
+		if (!ret)
+			return ret;
+		return pl01x_serial_setbrg(dev, gd->baudrate);
+	} else {
 		return 0;
+	}
 }
 
 int pl01x_serial_getc(struct udevice *dev)

---
base-commit: f7cca7ccc5117eaafcc2bde91ad1bed6fee7cfc3
change-id: 20240123-b4-pl011-ee9575ff2a38

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

