From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 30 May 2026 10:20:22 +0200
Subject: [PATCH] Revert "usb: typec: mux: avoid duplicated mux switches"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260530-typc-mux-modeset-v1-1-64b0281e2cd6@oldschoolsolutions.biz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avErBuYCkO6SrQQm2oWWmhFId49a
 fkW/yeIHIQjDFWCwLdE2X1BU1dgN+NXRpmLoaW2J9URnu9h0V0Pun3myCeyWrTptGmILJTsCLz
 I8y/HKecPE3cNz2IAAAA=
X-Change-ID: 20260530-typc-mux-modeset-e5f8a38a100c
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780129223; l=2278;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=DsZwGjXI8H6vKbDo005iChwLLRz9y8hmwTBYCgo3fxg=;
 b=FQ+2pUnmupin9eRRqG37HNI8PVQy6nXa4FefM8P6Os36IVBWoa+JJXbStSiNHl8c7M34qNk3p
 Us0k47MlUpyAeLAV0JNH9B6pSbsQRRRW5Cw15RlhpkvRbhOVnZsYY7F
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This reverts commit b145c3f29d62f71cc9d2d714e2d4ae4c8d3f863d.

The deduplication logic appears to cause issues with separate
SBU muxes. The mode-switch call on these (like gpio-sbu-mux)
never appeared, so no successful mode-switch happened. The more
high-end Parade PS883X redrivers are not affected due to being
retimer-switch. The revert fixes dp altmode mode-switch for both.

Tested on:
  Lenovo Thinkbook 16 G7 QOY
  Lenovo Ideapad 5 2in1 14Q8X9
  Microsoft Windows Dev Kit 2023 (Blackrock)
  Lenovo Thinkpad T14s G6

Fixes: b145c3f29d62 ("usb: typec: mux: avoid duplicated mux switches")

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/usb/typec/mux.c | 13 +------------
 1 file changed, 1 insertion(+), 12 deletions(-)

diff --git a/drivers/usb/typec/mux.c b/drivers/usb/typec/mux.c
index db5e4a4c0a996..9b908c46bd7df 100644
--- a/drivers/usb/typec/mux.c
+++ b/drivers/usb/typec/mux.c
@@ -275,9 +275,7 @@ static int mux_fwnode_match(struct device *dev, const void *fwnode)
 static void *typec_mux_match(const struct fwnode_handle *fwnode,
 			     const char *id, void *data)
 {
-	struct typec_mux_dev **mux_devs = data;
 	struct device *dev;
-	int i;
 
 	/*
 	 * Device graph (OF graph) does not give any means to identify the
@@ -293,14 +291,6 @@ static void *typec_mux_match(const struct fwnode_handle *fwnode,
 	dev = class_find_device(&typec_mux_class, NULL, fwnode,
 				mux_fwnode_match);
 
-	/* Skip duplicates */
-	for (i = 0; i < TYPEC_MUX_MAX_DEVS; i++)
-		if (to_typec_mux_dev(dev) == mux_devs[i]) {
-			put_device(dev);
-			return NULL;
-		}
-
-
 	return dev ? to_typec_mux_dev(dev) : ERR_PTR(-EPROBE_DEFER);
 }
 
@@ -326,8 +316,7 @@ struct typec_mux *fwnode_typec_mux_get(struct fwnode_handle *fwnode)
 		return ERR_PTR(-ENOMEM);
 
 	count = fwnode_connection_find_matches(fwnode, "mode-switch",
-					       (void **)mux_devs,
-					       typec_mux_match,
+					       NULL, typec_mux_match,
 					       (void **)mux_devs,
 					       ARRAY_SIZE(mux_devs));
 	if (count <= 0) {

---
base-commit: 7da7f07112610a520567421dd2ffcb51beaefbcc
change-id: 20260530-typc-mux-modeset-e5f8a38a100c

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

