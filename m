From: Michael Reeves <michael.reeves077@gmail.com>
Date: Sat, 07 Nov 2026 10:06:17 +0000
Subject: [PATCH] usb: typec: tipd: assign partner identity to persistent
 memory
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-tipd-stack-uaf-fix-v1-1-efcb517924ec@gmail.com>
X-B4-Tracking: v=1; b=H4sIABj47moC/x2MSQqAMAwAvyI5G2jc9SviobSpBkGlVRGKf7d4n
 IGZCIG9cIAhi+D5liD7loDyDMyit5lRbGIoVNEQqRZPOSyGU5sVL+3QyYO2pKpTdW8UtZDCw3P
 S/3Sc3vcDewcuVmQAAAA=
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Janne Grunau <j@jannau.net>, Sven Peter <sven@kernel.org>, 
 Hector Martin <marcan@marcan.st>
Cc: Neal Gompa <neal@gompa.dev>, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nicole Mazzuca <nicole@streganil.no>, 
 stable@vger.kernel.org, Michael Reeves <michael.reeves077@gmail.com>, 
 asahi@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794045978; l=2080;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=11jWNoNyYcLtaaM1fNLvBsJPDBw5EU5pTtOvCfnWMwo=;
 b=G8zeiNyKG6OsjYAWHxwP2e7A8a0o4EJnDAxqrHOhnh3417IfBii0p81xO2n0aHm5VtGC5oEU+
 uFXHj/X3vdEB84NUrq78FxoXHyWuPOrJIdBMg3CrPlL7H6qxZF9Q4MH
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cd321x_update_work() passes a pointer to a local stack variable
(&st.partner_identity) to typec_register_partner(). The Type-C core
caches this pointer, leading to a stack-use-after-free and a kernel
Oops when accessed later (e.g., via get_pd_product_type()).

Fix this by copying the identity to the heap-allocated cd321x struct
and passing a pointer to that persistent memory instead. Move up
the assignment to cd321x->cur_partner_identity, so this works.

Reported-by: Nicole Mazzuca <nicole@streganil.no>
Closes: https://github.com/AsahiLinux/linux/issues/668
Fixes: 82432bbfb9e8 ("usb: typec: tipd: Handle mode transitions for CD321x")
Cc: stable@vger.kernel.org
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
Cc: Nicole Mazzuca <nicole@streganil.no>
Cc: asahi@lists.linux.dev
---
 drivers/usb/typec/tipd/core.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/usb/typec/tipd/core.c b/drivers/usb/typec/tipd/core.c
index 02539378ffed..dce0aa8be5e0 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -855,8 +855,10 @@ static void cd321x_update_work(struct work_struct *work)
 		desc.usb_pd = is_pd;
 		desc.accessory = TYPEC_ACCESSORY_NONE; /* XXX: handle accessories */
 
-		if (desc.usb_pd)
-			desc.identity = &st.partner_identity;
+		if (desc.usb_pd) {
+			cd321x->cur_partner_identity = st.partner_identity;
+			desc.identity = &cd321x->cur_partner_identity;
+		}
 
 		tps->partner = typec_register_partner(tps->port, &desc);
 		if (IS_ERR(tps->partner)) {
@@ -864,10 +866,8 @@ static void cd321x_update_work(struct work_struct *work)
 			return;
 		}
 
-		if (desc.identity) {
+		if (desc.identity)
 			typec_partner_set_identity(tps->partner);
-			cd321x->cur_partner_identity = st.partner_identity;
-		}
 	}
 
 	/* Update the TypeC MUX/PHY state */

---
base-commit: d48723711bae9b8cdc56719c448ba42fef28cbee
change-id: 20261107-tipd-stack-uaf-fix-d3148059c017

Best regards,
-- 
Michael Reeves <michael.reeves077@gmail.com>

