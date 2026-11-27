From: Rongen Wang <security@nitrohex.com>
Date: Fri, 27 Nov 2026 21:00:44 +0900
Subject: [PATCH] scsi: target: iscsi: Refuse to add a connection to a
 session being closed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-lio-iscsi-session-closing-v1-1-cdf2bbbef87a@nitrohex.com>
X-B4-Tracking: v=1; b=H4sIAOxwCWsC/yXMQQrCMBBG4auUWTvQhLRBryIu7DitIyWR/FWE0
 rub6vJbvLcStJiCTs1KRd8Gy6nCHRqS+zVNynarJt/63jkfeQg8W2aDwBiKPWCZMyxN3McxdF1
 sj0GU6uJZdLTPb3++/I3X8FBZ9idt2xcy63D0gAAAAA==
X-Change-ID: 20261127-b4-lio-iscsi-session-closing-67f4557094ce
To: "Martin K. Petersen" <mkp@kernel.org>
Cc: linux-scsi@vger.kernel.org, target-devel@vger.kernel.org, 
 stable@vger.kernel.org, Rongen Wang <security@nitrohex.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795780851; l=10396;
 i=security@nitrohex.com; s=nitrohex; h=from:subject:message-id;
 bh=Y5v0HOOMEKgzfoq/9MoX/iEb5+HGxicU3xh+mZENOQ8=;
 b=BDDiYemAcGDuyuLAg16rCjpOCy7tcgZcTujnLSdYtXekAJOlFEc/kEhSNJHh0xQQYzTCMozy+
 f0xmshGvAeUAVHdGQq6QvSCOb064riLUrmxR3THC4LRNlNC8ciZ405D
X-Developer-Key: i=security@nitrohex.com; a=ed25519;
 pk=Jk5NuTVJdxr1CTP4RuYaG31zSgsNlyFzVo9sphZTqt0=
X-Endpoint-Received: by B4 Relay for security@nitrohex.com/nitrohex with auth_id=1652
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A Login Request with a non-zero TSIH adds a connection to an existing
session. iscsi_login_non_zero_tsih_s2() looks the session up when the
first Login PDU arrives, checks once that it is not being closed and
takes a session usage count. The login then stays pending for as long
as the initiator delays its next Login PDU.

If the last connection of the session fails in the meantime,
iscsit_close_connection() sets session_fall_back_to_erl0 and calls
iscsit_close_session(), which waits for the usage count held by the
pending login. Nothing stops that login from completing:
iscsi_login_post_auth_non_zero_tsih() only compares nconn + 1 with
MaxConnections, and iscsi_post_login_handler() adds the connection to
sess->sess_conn_list and drops the usage count. iscsit_close_session()
then frees the session while the new connection is in full feature
phase, and the first PDU received on it reads the freed session:

  BUG: KASAN: slab-use-after-free in iscsit_get_rx_pdu+0x2338/0x3330
  Read of size 8 at addr ffff88800b19fde0 by task iscsi_trx/156
  Call Trace:
   iscsit_get_rx_pdu+0x2338/0x3330
   iscsi_target_rx_thread+0x139/0x2f0
   kthread+0x2e8/0x3c0
  Freed by task 154:
   kfree+0x127/0x3b0
   iscsit_close_session+0x3a2/0x570
   iscsit_close_connection+0x134d/0x20f0
   iscsit_take_action_for_connection_exit+0x1b5/0x360
   iscsi_target_rx_thread+0x251/0x2f0

Without KASAN the same sequence ends in a NULL pointer dereference in
iscsit_get_rx_pdu() and, when the NOP-In timer of the new connection
fires, in a panic in softirq context.

Check the session state again in iscsi_post_login_handler(), under
sess->conn_lock, before the connection is added.
iscsit_close_connection() decides under the same lock whether it closed
the last connection, so either the new connection is counted before
that decision or the login sees the flags and is refused.

Move the transition to TARG_CONN_STATE_LOGGED_IN after that check. The
RX and TX kthreads were started before the final Login Response was
sent and leave a connection alone while it is still in
TARG_CONN_STATE_IN_LOGIN, so a refused connection can be stopped the
same way the error path of iscsi_target_do_tx_login_io() stops it, and
then released with iscsi_target_login_sess_out(). The initiator has
already received the final Login Response and sees the connection
dropped, as if the session had been closed a moment earlier.

The problem was found and this patch was drafted with the help of an AI
assistant (Claude Mythos 5.2, Anthropic, via Claude Code); the result
was reviewed and tested as described below the cut line.

Fixes: e48354ce078c ("iscsi-target: Add iSCSI fabric support for target v4.1")
Cc: stable@vger.kernel.org
Signed-off-by: Rongen Wang <security@nitrohex.com>
---
Based on mkp/scsi.git 7.4/scsi-fixes (4be084ac36f9). It also applies
to mainline 9437ee8b6cf6 and to linux-7.3.y, 6.18.y and 6.12.y.

Tested on that tree with KASAN under QEMU, iSCSI/TCP: the reproducer's
second login is refused ("iSCSI session SID 1 is shutting down,
refusing to add CID 2") without a KASAN report, and adding a connection
to a live session with MaxConnections=2, logouts, a fresh login and
session continuation after a CLOSE_CONNECTION logout still work.
Without the patch the same tree gives the report above. The refusal
path in __iscsi_target_login_thread() (login completed by its first
PDU) was not reached by these tests; iSER and cxgbit were not tested.
No W=1 warnings in drivers/target/iscsi/.

The reproducer was sent to the maintainer privately and is not posted
here.
---
 drivers/target/iscsi/iscsi_target_login.c | 85 ++++++++++++++++++++++++++-----
 drivers/target/iscsi/iscsi_target_login.h |  4 +-
 drivers/target/iscsi/iscsi_target_nego.c  |  5 +-
 3 files changed, 80 insertions(+), 14 deletions(-)

diff --git a/drivers/target/iscsi/iscsi_target_login.c b/drivers/target/iscsi/iscsi_target_login.c
index fda04eb15d..7176280004 100644
--- a/drivers/target/iscsi/iscsi_target_login.c
+++ b/drivers/target/iscsi/iscsi_target_login.c
@@ -644,10 +644,41 @@ int iscsit_start_kthreads(struct iscsit_conn *conn)
 	return ret;
 }
 
-void iscsi_post_login_handler(
-	struct iscsi_np *np,
-	struct iscsit_conn *conn,
-	u8 zero_tsih)
+/*
+ * Undo iscsit_start_kthreads() for a connection that is still in
+ * TARG_CONN_STATE_IN_LOGIN.  Both kthreads leave the connection alone in
+ * that state and only wait for kthread_stop().
+ */
+void iscsit_stop_kthreads(struct iscsit_conn *conn)
+{
+	if (conn->rx_thread && conn->rx_thread_active) {
+		send_sig(SIGINT, conn->rx_thread, 1);
+		complete(&conn->rx_login_comp);
+		kthread_stop(conn->rx_thread);
+		conn->rx_thread_active = false;
+	}
+	if (conn->tx_thread && conn->tx_thread_active) {
+		send_sig(SIGINT, conn->tx_thread, 1);
+		kthread_stop(conn->tx_thread);
+		conn->tx_thread_active = false;
+	}
+	spin_lock(&iscsit_global->ts_bitmap_lock);
+	bitmap_release_region(iscsit_global->ts_bitmap, conn->bitmap_id,
+			      get_order(1));
+	spin_unlock(&iscsit_global->ts_bitmap_lock);
+}
+
+/*
+ * Returns 0 once the connection has been made part of its session.
+ *
+ * Returns -1 if a connection that is being added to an existing session
+ * (TSIH != 0) can not be attached because the session started to shut down
+ * while the login was in progress.  The connection is then still in
+ * TARG_CONN_STATE_IN_LOGIN and the caller has to stop its kthreads and
+ * release it with iscsi_target_login_sess_out().
+ */
+int iscsi_post_login_handler(struct iscsi_np *np, struct iscsit_conn *conn,
+			     u8 zero_tsih)
 {
 	int stop_timer = 0;
 	struct iscsit_session *sess = conn->sess;
@@ -657,12 +688,6 @@ void iscsi_post_login_handler(
 
 	iscsit_inc_conn_usage_count(conn);
 
-	iscsit_collect_login_stats(conn, ISCSI_STATUS_CLS_SUCCESS,
-			ISCSI_LOGIN_STATUS_ACCEPT);
-
-	pr_debug("Moving to TARG_CONN_STATE_LOGGED_IN.\n");
-	conn->conn_state = TARG_CONN_STATE_LOGGED_IN;
-
 	iscsi_set_connection_parameters(conn->conn_ops, conn->param_list);
 	/*
 	 * SCSI Initiator -> SCSI Target Port Mapping
@@ -674,6 +699,32 @@ void iscsi_post_login_handler(
 		conn->param_list = NULL;
 
 		spin_lock_bh(&sess->conn_lock);
+		/*
+		 * The session was located from ISID+TSIH when the first Login
+		 * Request arrived, and since then only the session usage count
+		 * kept it alive.  If its last connection went away in the
+		 * meantime, iscsit_close_connection() has already committed to
+		 * iscsit_close_session(), which frees the session as soon as
+		 * the usage count is dropped.  Do not attach a new connection
+		 * to a session that is being shut down.  iscsit_close_connection()
+		 * makes that decision under sess->conn_lock as well.
+		 */
+		if (atomic_read(&sess->session_fall_back_to_erl0) ||
+		    atomic_read(&sess->session_logout) ||
+		    atomic_read(&sess->session_close)) {
+			spin_unlock_bh(&sess->conn_lock);
+			pr_err("iSCSI session SID %u is shutting down, refusing to add CID %u\n",
+			       sess->sid, conn->cid);
+			iscsit_dec_conn_usage_count(conn);
+			return -1;
+		}
+
+		iscsit_collect_login_stats(conn, ISCSI_STATUS_CLS_SUCCESS,
+					   ISCSI_LOGIN_STATUS_ACCEPT);
+
+		pr_debug("Moving to TARG_CONN_STATE_LOGGED_IN.\n");
+		conn->conn_state = TARG_CONN_STATE_LOGGED_IN;
+
 		atomic_set(&sess->session_continuation, 0);
 		if (sess->session_state == TARG_SESS_STATE_FAILED) {
 			pr_debug("Moving to"
@@ -714,9 +765,15 @@ void iscsi_post_login_handler(
 			spin_unlock_bh(&se_tpg->session_lock);
 		}
 		iscsit_dec_session_usage_count(sess);
-		return;
+		return 0;
 	}
 
+	iscsit_collect_login_stats(conn, ISCSI_STATUS_CLS_SUCCESS,
+				   ISCSI_LOGIN_STATUS_ACCEPT);
+
+	pr_debug("Moving to TARG_CONN_STATE_LOGGED_IN.\n");
+	conn->conn_state = TARG_CONN_STATE_LOGGED_IN;
+
 	iscsi_set_session_parameters(sess->sess_ops, conn->param_list, 1);
 	iscsi_release_param_list(conn->param_list);
 	conn->param_list = NULL;
@@ -769,6 +826,7 @@ void iscsi_post_login_handler(
 	 */
 	complete(&conn->rx_login_comp);
 	iscsit_dec_conn_usage_count(conn);
+	return 0;
 }
 
 int iscsit_setup_np(
@@ -1321,7 +1379,10 @@ static int __iscsi_target_login_thread(struct iscsi_np *np)
 	if (ret == 1) {
 		tpg_np = conn->tpg_np;
 
-		iscsi_post_login_handler(np, conn, zero_tsih);
+		if (iscsi_post_login_handler(np, conn, zero_tsih) < 0) {
+			iscsit_stop_kthreads(conn);
+			goto new_sess_out;
+		}
 		iscsit_deaccess_np(np, tpg, tpg_np);
 	}
 
diff --git a/drivers/target/iscsi/iscsi_target_login.h b/drivers/target/iscsi/iscsi_target_login.h
index 03c7d695d5..d2c6169adb 100644
--- a/drivers/target/iscsi/iscsi_target_login.h
+++ b/drivers/target/iscsi/iscsi_target_login.h
@@ -20,7 +20,9 @@ extern int iscsit_get_login_rx(struct iscsit_conn *, struct iscsi_login *);
 extern int iscsit_put_login_tx(struct iscsit_conn *, struct iscsi_login *, u32);
 extern void iscsit_free_conn(struct iscsit_conn *);
 extern int iscsit_start_kthreads(struct iscsit_conn *);
-extern void iscsi_post_login_handler(struct iscsi_np *, struct iscsit_conn *, u8);
+void iscsit_stop_kthreads(struct iscsit_conn *conn);
+int iscsi_post_login_handler(struct iscsi_np *np, struct iscsit_conn *conn,
+			     u8 zero_tsih);
 extern void iscsi_target_login_sess_out(struct iscsit_conn *, bool, bool);
 extern int iscsi_target_login_thread(void *);
 
diff --git a/drivers/target/iscsi/iscsi_target_nego.c b/drivers/target/iscsi/iscsi_target_nego.c
index ccd468e26f..23f6dffb79 100644
--- a/drivers/target/iscsi/iscsi_target_nego.c
+++ b/drivers/target/iscsi/iscsi_target_nego.c
@@ -640,7 +640,10 @@ static void iscsi_target_do_login_rx(struct work_struct *work)
 		iscsit_stop_login_timer(conn);
 		cancel_delayed_work(&conn->login_work);
 		iscsi_target_nego_release(conn);
-		iscsi_post_login_handler(np, conn, zero_tsih);
+		if (iscsi_post_login_handler(np, conn, zero_tsih) < 0) {
+			iscsit_stop_kthreads(conn);
+			iscsi_target_login_sess_out(conn, zero_tsih, true);
+		}
 		iscsit_deaccess_np(np, tpg, tpg_np);
 	}
 	return;

---
base-commit: 4be084ac36f95f95e21a1e39207e87326967a73d
change-id: 20261127-b4-lio-iscsi-session-closing-67f4557094ce

Best regards,
--  
Rongen Wang <security@nitrohex.com>

