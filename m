From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 14:43:28 +0200
Subject: [PATCH] usb: typec: tipd: Zero-initialize CD321x partner
 descriptor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-tipd-partner-desc-v1-1-073559f142ff@kernel.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMPQ7CMAxA4atUnrHkRNCqXAUx5MeAGUJkB4RU9
 e5NYfyG9xYwVmGD87CA8kdMXqXDHQZIj1DujJK7wZMfaaYR4xGb1Iw1aCusmNkS0jS7U3B+ihS
 gp1X5Jt/f9nL9297xyantL1jXDXtL0+54AAAA
X-Change-ID: 20260906-b4-tipd-partner-desc-07915a127b0a
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: asahi@lists.linux.dev, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1428; i=sven@kernel.org;
 h=from:subject:message-id; bh=F0fgm1i8HFGP9oMA1VAKRxErBO1BdcjfJnpab90e2YQ=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bc+E8/pjcv2yXwrrvGdsf2Ba8/Xj54wZLfxy5rzcdo7
 2n5bnzdHaUsDGJcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJlHQyMmzhWywm9kzqh+if
 dyG/J5hxFT7wWvQs8bSWFI/2qzcJb34y/NMLcxHTn3l/y89DSxS/buqbWWdfrcm+etXEn+umTdq
 nNp0BAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The typec_partner_desc struct isn't initialized and instead filled with
whatever values happen to be on the stack. We especially don't overwrite
the attach/detach callbacks. Just zero initialize it to make sure we don't
run into weird issues in the future.

Fixes: 82432bbfb9e8 ("usb: typec: tipd: Handle mode transitions for CD321x")
Signed-off-by: Sven Peter <sven@kernel.org>
---
I deliberately didn't cc stable@ since we can't even reach the path
that would try to run these callbacks on platforms where this is used.
Just noticed this while working on the USB4/Thunderbolt series for Apple
Silicon.
---
 drivers/usb/typec/tipd/core.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/usb/typec/tipd/core.c b/drivers/usb/typec/tipd/core.c
index 522f56742aa9..07d6d88e3a0e 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -841,7 +841,7 @@ static void cd321x_update_work(struct work_struct *work)
 
 	/* Set up partner if we were previously disconnected (or changed). */
 	if (!tps->partner) {
-		struct typec_partner_desc desc;
+		struct typec_partner_desc desc = { };
 
 		desc.usb_pd = is_pd;
 		desc.accessory = TYPEC_ACCESSORY_NONE; /* XXX: handle accessories */

---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20260906-b4-tipd-partner-desc-07915a127b0a

Best regards,
--  
Sven Peter <sven@kernel.org>

