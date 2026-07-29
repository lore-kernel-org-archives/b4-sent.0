From: Yang Li <yang.li@amlogic.com>
Date: Wed, 29 Jul 2026 09:47:16 +0800
Subject: [PATCH BlueZ bluez] bap: fixed the return value of GIOFunc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-fix_iofunc-v1-1-653c8e9ac29a@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAKRbaWoC/x2M3QpAQBBGX0VzbYspv68iifFhSku7kci721yeT
 uc85OEUnuroIYdTvW42QBpHJEtvZxgdAxMnnCcFV2bSq9NtOqwY5CwQyXgoQSHYHYL9Zw0N64G
 b2vf9AMd6gZFjAAAA
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785289636; l=1171;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=/hbuF3t2bg82xqd+B+KApp2WG+Bkz75KXCTrlPmc4Zw=;
 b=T5dq7cOQoNvxWnGCFggc7dSUUk52e2TLreLMea6IQjuzw9Bl9+YrerdgJvX7jFdaG66d2yFWD
 sRkjA+3xKHLB8oI0cvRRX8DeJxaapfFYkdJcrL7jxNoXW11KHcp129j
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GIOFunc should return FALSE if the event source should be removed.

Fixes: 322c39a64 (bap: Start BIG sync after receiving BIGInfo)

Signed-off-by: Yang Li <yang.li@amlogic.com>
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

