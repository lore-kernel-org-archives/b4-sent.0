From: =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Wed, 26 Feb 2025 15:17:27 +0100
Subject: [PATCH v2 5/9] usb: storage: initializers: Use const for constant
 array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250226-misc-const-v2-5-ab655a4a29cc@posteo.net>
References: <20250226-misc-const-v2-0-ab655a4a29cc@posteo.net>
In-Reply-To: <20250226-misc-const-v2-0-ab655a4a29cc@posteo.net>
To: Alan Stern <stern@rowland.harvard.edu>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, usb-storage@lists.one-eyed-alien.net, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740579450; l=891;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=E3sv7MUTjUoAFshGx3e7fa3LASnJqeGyCGNhGtip8E4=;
 b=e9djsAqkZ4XnlACb+EI453tnroUtGkD58yGmdSWYpfkInGcsTwB551/xvIIPIytkjdEKrY7V2
 3JcC++IDHIsAQA0IpzE4CRdD36/ISBdF8NxT402z/qLs60wHbX+Ydws
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

init_string is only read, not modified.

Signed-off-by: Jonathan Neuschäfer <j.ne@posteo.net>
---

V2:
- new patch
---
 drivers/usb/storage/initializers.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/usb/storage/initializers.c b/drivers/usb/storage/initializers.c
index f8f9ce8dc71029aff5ceaf4d62f596a30bbceca2..b243bd5521a66deb3ca3603b52ccf603e191a4de 100644
--- a/drivers/usb/storage/initializers.c
+++ b/drivers/usb/storage/initializers.c
@@ -54,7 +54,7 @@ int usb_stor_ucr61s2b_init(struct us_data *us)
 	struct bulk_cs_wrap *bcs = (struct bulk_cs_wrap*) us->iobuf;
 	int res;
 	unsigned int partial;
-	static char init_string[] = "\xec\x0a\x06\x00$PCCHIPS";
+	static const char init_string[] = "\xec\x0a\x06\x00$PCCHIPS";
 
 	usb_stor_dbg(us, "Sending UCR-61S2B initialization packet...\n");
 

-- 
2.48.0.rc1.219.gb6b6757d772

