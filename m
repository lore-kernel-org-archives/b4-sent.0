From: Miles Krause <mileskrause5200@gmail.com>
Date: Sun, 12 Jul 2026 21:07:11 -0400
Subject: [PATCH] auxdisplay: panel: Remove unused callback binding code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260712-panel-remove-dead-callback-v1-1-1091ce75b8d5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAD46VGoC/yXMQQ6CMBAF0KuQWTsJbQATr2JcTNuPjtZCWiUmh
 LtbdPk2b6WCrCh0albKWLTolCrMoSF/k3QFa6gm29qhPRrLsyREznhOCzhAAnuJ0Yl/cDc4a3u
 DboSjGswZo35++fnyd3m7O/xrH2nbvs/cG1R+AAAA
X-Change-ID: 20260712-panel-remove-dead-callback-46b2251e4feb
To: Willy Tarreau <willy@haproxy.com>, 
 Ksenija Stanojevic <ksenija.stanojevic@gmail.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Geert Uytterhoeven <geert@linux-m68k.org>
Cc: linux-kernel@vger.kernel.org, Miles Krause <mileskrause5200@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783904830; l=2301;
 i=mileskrause5200@gmail.com; s=20260710; h=from:subject:message-id;
 bh=1uSWTROps+iQmdfCIRsMqqO+F3wcn3YcqYKwgjFvpQk=;
 b=8iHVN1Ks24K+sQAWiijIGZp9d1fwcePl1Is+19IeoxYL2isnr82SUKl8TnY+oQ+MGjD8GrXR4
 rE7iFu/6ZzcBeIkgjpKYXvuiT5L5QjACQfeSWRwAJhkYNIEFgPdrRl+
X-Developer-Key: i=mileskrause5200@gmail.com; a=ed25519;
 pk=QNhNjcQarqig3ColJBIEr3DYfWM1PHpP7z+6thxWXaU=
X-Endpoint-Received: by B4 Relay for mileskrause5200@gmail.com/20260710 with auth_id=861
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panel_bind_callback() has been compiled out with #if 0 since it was
introduced and has no callers. Remove the dead function to reduce
maintenance burden.

No functional change.

Signed-off-by: Miles Krause <mileskrause5200@gmail.com>
---
Compile-tested on x86_64 with:

  make O=out allmodconfig
  make O=out W=1 drivers/auxdisplay/panel.o

Sparse-tested with:

  make O=out C=2 CHECK=sparse drivers/auxdisplay/panel.o
---
 drivers/auxdisplay/panel.c | 37 -------------------------------------
 1 file changed, 37 deletions(-)

diff --git a/drivers/auxdisplay/panel.c b/drivers/auxdisplay/panel.c
index d8854cf15268..a7dfc53157bc 100644
--- a/drivers/auxdisplay/panel.c
+++ b/drivers/auxdisplay/panel.c
@@ -1450,43 +1450,6 @@ static struct logical_input *panel_bind_key(const char *name, const char *press,
 	return key;
 }
 
-#if 0
-/* tries to bind a callback function to the signal name <name>. The function
- * <press_fct> will be called with the <press_data> arg when the signal is
- * activated, and so on for <release_fct>/<release_data>
- * Returns the pointer to the new signal if ok, NULL if the signal could not
- * be bound.
- */
-static struct logical_input *panel_bind_callback(char *name,
-						 void (*press_fct)(int),
-						 int press_data,
-						 void (*release_fct)(int),
-						 int release_data)
-{
-	struct logical_input *callback;
-
-	callback = kmalloc(sizeof(*callback), GFP_KERNEL);
-	if (!callback)
-		return NULL;
-
-	memset(callback, 0, sizeof(struct logical_input));
-	if (!input_name2mask(name, &callback->mask, &callback->value,
-			     &scan_mask_i, &scan_mask_o))
-		return NULL;
-
-	callback->type = INPUT_TYPE_STD;
-	callback->state = INPUT_ST_LOW;
-	callback->rise_time = 1;
-	callback->fall_time = 1;
-	callback->u.std.press_fct = press_fct;
-	callback->u.std.press_data = press_data;
-	callback->u.std.release_fct = release_fct;
-	callback->u.std.release_data = release_data;
-	list_add(&callback->list, &logical_inputs);
-	return callback;
-}
-#endif
-
 static void keypad_init(void)
 {
 	int keynum;

---
base-commit: 30a41cf47aecb4dafb81183b5e046e93498773ff
change-id: 20260712-panel-remove-dead-callback-46b2251e4feb

Best regards,
--  
Miles Krause <mileskrause5200@gmail.com>

