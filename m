From: Yang Li <yang.li@amlogic.com>
Date: Wed, 29 Jul 2026 14:51:43 +0800
Subject: [PATCH BlueZ bluez v2] bap: fixed the return value of GIOFunc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-fix_iofunc-v2-1-f4043eff6664@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAP6iaWoC/22NwQ6CMBBEf4Xs2Rq6hko9+R+GmLIusAlQ0wpRC
 f9u07PHmZd5s0HkIBzhUmwQeJUofk4BDwXQ4OaelTxSBizRlGe0qpP3XXy3zKTYIDFRhW3NkAb
 PwIlm2Q3aceEvNKkeJL58+OSLVWf4z7ZqpZWpTlSzdYTWXd00+l7oSH6CZt/3H5b2YZ2tAAAA
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785307903; l=1305;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=q+aq5JL61eNx++8p/sEr4k79bC6hbLuCs+m2n68IdDE=;
 b=fk6Vx41A1pLsRmVDE0khF4diCp6VSCM4LxjztDjU2+eZezLRynRuy0Yer5sgb7V/1vuxh945B
 5QBerRvHgobBbNT0oqDUVM01qyUec5rAwyuAA1G0aIFcdocOB7s0LBF
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GIOFunc should return FALSE if the event source should be removed.

Fixes: 322c39a64 ("bap: Start BIG sync after receiving BIGInfo")

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Changes in v2:
- Fix BAD_FIXES_TAG
- Link to v1: https://patch.msgid.link/20260729-fix_iofunc-v1-1-653c8e9ac29a@amlogic.com
---
 profiles/audio/bap.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/profiles/audio/bap.c b/profiles/audio/bap.c
index 473e4cfc2..ff8f58a12 100644
--- a/profiles/audio/bap.c
+++ b/profiles/audio/bap.c
@@ -3683,7 +3683,6 @@ static gboolean iso_do_big_sync(GIOChannel *io, GIOCondition cond,
 			BT_IO_OPT_INVALID)) {
 		error("bt_io_set: %s", err->message);
 		g_error_free(err);
-		return FALSE;
 	}
 
 	if (!bt_io_bcast_accept(io,
@@ -3694,10 +3693,9 @@ static gboolean iso_do_big_sync(GIOChannel *io, GIOCondition cond,
 			iso_bc_addr.bc_bis, BT_IO_OPT_INVALID)) {
 		error("bt_io_bcast_accept: %s", err->message);
 		g_error_free(err);
-		return FALSE;
 	}
 
-	return TRUE;
+	return FALSE;
 }
 
 static void long_pa_sync_confirm_cb(GIOChannel *io, void *user_data)

---
base-commit: 729f96089cf66831d911385623ca932e0c245913
change-id: 20260729-fix_iofunc-e62cecc52b8e

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

