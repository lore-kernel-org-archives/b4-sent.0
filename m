From: Rongen Wang <security@nitrohex.com>
Date: Fri, 27 Nov 2026 22:52:18 +0900
Subject: [PATCH v2 1/2] scsi: target: iscsi: Refuse to add a connection to
 a session being closed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-lio-iscsi-session-closing-v2-1-a3ac8e88cbad@nitrohex.com>
References: <20261127-b4-lio-iscsi-session-closing-v2-0-a3ac8e88cbad@nitrohex.com>
In-Reply-To: <20261127-b4-lio-iscsi-session-closing-v2-0-a3ac8e88cbad@nitrohex.com>
To: "Martin K. Petersen" <mkp@kernel.org>
Cc: linux-scsi@vger.kernel.org, target-devel@vger.kernel.org, 
 stable@vger.kernel.org, Rongen Wang <security@nitrohex.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795787544; l=12716;
 i=security@nitrohex.com; s=nitrohex; h=from:subject:message-id;
 bh=6eko8Rh3SWLy4tXq1Kzj6AzCiZ+7fNqYMIqbjmzcoB8=;
 b=Z/ZC7PSe1ADZtSdIgl+dds/8+SdAIx2k0D/WG9E3zFgGSmk7JV7yUhjS/WM3aKshFn476Lydg
 g3h8TtvPpCYAFBtlBvL3kcTkmOAaRejTLCK8cwvv6tkYGd2ZdiJN6Wv
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

If the last connection is instead logged out with reason
CLOSE_CONNECTION, or fails at ErrorRecoveryLevel 2, the session waits
in TARG_SESS_STATE_FAILED and iscsit_close_connection() starts the
Time2Retain timer, which the lookup had no reason to stop. If the timer
expires while the login is pending, iscsit_close_session() finds the
usage count and gives up half way, and the login then adds its
connection to a session that is no longer registered in configfs.
Dropping the usage count completes session_waiting_on_uc_comp with
nobody waiting, so when that connection logs out the session,
iscsit_close_session() does not wait for the usage count held by the
logout and frees the session under it:

  BUG: KASAN: slab-use-after-free in _raw_spin_lock_irq+0x72/0xe0
  Write of size 4 at addr ffff888009aee958 by task iscsi_ttx/160
  Call Trace:
   _raw_spin_lock_irq+0x72/0xe0
   __wait_for_common+0x2b6/0x4a0
   iscsit_logout_post_handler+0x1aa/0x660
   iscsit_response_queue+0xa46/0x19d0
   iscsi_target_tx_thread+0x3c7/0x650
  Freed by task 161:
   kfree+0x127/0x3b0
   iscsit_close_session+0x3a2/0x570
   iscsit_close_connection+0x134d/0x20f0
   iscsit_take_action_for_connection_exit+0x2b7/0x360
   iscsi_target_rx_thread+0x1aa/0x2f0

Before adding the connection, check again what the lookup checked:
session_fall_back_to_erl0, session_logout, session_close and
ISCSI_TF_EXPIRED, under se_tpg->session_lock and sess->conn_lock as
iscsi_check_for_session_reinstatement() and lio_tpg_close_session() do.
iscsit_close_connection() decides under sess->conn_lock whether it
closed the last connection, and the Time2Retain handler sets
ISCSI_TF_EXPIRED under se_tpg->session_lock, so either the new
connection is counted first or the login sees that the session is going
away and is refused. Stop the Time2Retain timer before session_lock is
dropped, so that an expiry that is already pending sees ISCSI_TF_STOP
instead of closing a session that has a connection again. Take over the
session parameters negotiated on the new connection only after the
check, so that a refused login leaves sess->sess_ops alone and
iscsi_target_login_sess_out() records it with the initiator name.

Move the transition to TARG_CONN_STATE_LOGGED_IN after that check. The
RX and TX kthreads were started before the final Login Response was
sent and leave a connection alone while it is still in
TARG_CONN_STATE_IN_LOGIN, so a refused connection can be stopped the
same way the error path of iscsi_target_do_tx_login_io() stops it, and
then released with iscsi_target_login_sess_out(). The initiator has
already received the final Login Response and sees the connection
dropped, as if the session had been closed a moment earlier.

The problem was found and this patch was drafted with the help of AI
assistants (Claude Mythos 5.2 and, for v2, Claude Opus 5.5, Anthropic,
via Claude Code); the result was reviewed and tested as described in
the cover letter.

Fixes: e48354ce078c ("iscsi-target: Add iSCSI fabric support for target v4.1")
Cc: stable@vger.kernel.org
Signed-off-by: Rongen Wang <security@nitrohex.com>
---
 drivers/target/iscsi/iscsi_target_login.c | 117 ++++++++++++++++++++++++------
 drivers/target/iscsi/iscsi_target_login.h |   4 +-
 drivers/target/iscsi/iscsi_target_nego.c  |   5 +-
 3 files changed, 100 insertions(+), 26 deletions(-)

diff --git a/drivers/target/iscsi/iscsi_target_login.c b/drivers/target/iscsi/iscsi_target_login.c
index fda04eb15d..7c465a22d6 100644
--- a/drivers/target/iscsi/iscsi_target_login.c
+++ b/drivers/target/iscsi/iscsi_target_login.c
@@ -644,10 +644,41 @@ out_bitmap:
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
@@ -657,23 +688,43 @@ void iscsi_post_login_handler(
 
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
 	 */
 	if (!zero_tsih) {
-		iscsi_set_session_parameters(sess->sess_ops,
-				conn->param_list, 0);
-		iscsi_release_param_list(conn->param_list);
-		conn->param_list = NULL;
+		/*
+		 * The session was located from ISID+TSIH when the first Login
+		 * Request arrived, and since then only the session usage count
+		 * kept it alive.  If its last connection went away in the
+		 * meantime, iscsit_close_connection() either committed to
+		 * iscsit_close_session(), or moved the session to
+		 * TARG_SESS_STATE_FAILED and started the Time2Retain timer,
+		 * which may have expired since.  Check again what
+		 * iscsi_login_non_zero_tsih_s2() checked, under the locks
+		 * iscsi_check_for_session_reinstatement() uses, and do not
+		 * attach a new connection to a session that is shutting down.
+		 */
+		spin_lock_bh(&se_tpg->session_lock);
+		spin_lock(&sess->conn_lock);
+		if (atomic_read(&sess->session_fall_back_to_erl0) ||
+		    atomic_read(&sess->session_logout) ||
+		    atomic_read(&sess->session_close) ||
+		    (sess->time2retain_timer_flags & ISCSI_TF_EXPIRED)) {
+			spin_unlock(&sess->conn_lock);
+			spin_unlock_bh(&se_tpg->session_lock);
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
 
-		spin_lock_bh(&sess->conn_lock);
 		atomic_set(&sess->session_continuation, 0);
 		if (sess->session_state == TARG_SESS_STATE_FAILED) {
 			pr_debug("Moving to"
@@ -691,7 +742,21 @@ void iscsi_post_login_handler(
 		pr_debug("Incremented iSCSI Connection count to %d"
 			" from node: %s\n", atomic_read(&sess->nconn),
 			sess->sess_ops->InitiatorName);
-		spin_unlock_bh(&sess->conn_lock);
+		spin_unlock(&sess->conn_lock);
+		/*
+		 * Stop the Time2Retain timer before session_lock is dropped, as
+		 * lio_tpg_close_session() does, so that an expiry that is
+		 * already pending sees ISCSI_TF_STOP instead of closing a
+		 * session that has a connection again.
+		 */
+		if (stop_timer)
+			iscsit_stop_time2retain_timer(sess);
+		spin_unlock_bh(&se_tpg->session_lock);
+
+		iscsi_set_session_parameters(sess->sess_ops, conn->param_list,
+					     0);
+		iscsi_release_param_list(conn->param_list);
+		conn->param_list = NULL;
 
 		iscsi_post_login_start_timers(conn);
 		/*
@@ -707,16 +772,16 @@ void iscsi_post_login_handler(
 		 */
 		complete(&conn->rx_login_comp);
 		iscsit_dec_conn_usage_count(conn);
-
-		if (stop_timer) {
-			spin_lock_bh(&se_tpg->session_lock);
-			iscsit_stop_time2retain_timer(sess);
-			spin_unlock_bh(&se_tpg->session_lock);
-		}
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
@@ -769,6 +834,7 @@ void iscsi_post_login_handler(
 	 */
 	complete(&conn->rx_login_comp);
 	iscsit_dec_conn_usage_count(conn);
+	return 0;
 }
 
 int iscsit_setup_np(
@@ -1321,7 +1387,10 @@ static int __iscsi_target_login_thread(struct iscsi_np *np)
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

-- 
2.34.1

