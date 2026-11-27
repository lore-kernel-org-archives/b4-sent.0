From: Rongen Wang <security@nitrohex.com>
Date: Fri, 27 Nov 2026 22:52:19 +0900
Subject: [PATCH v2 2/2] scsi: target: iscsi: Do not let Time2Retain expire
 a session in use
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-lio-iscsi-session-closing-v2-2-a3ac8e88cbad@nitrohex.com>
References: <20261127-b4-lio-iscsi-session-closing-v2-0-a3ac8e88cbad@nitrohex.com>
In-Reply-To: <20261127-b4-lio-iscsi-session-closing-v2-0-a3ac8e88cbad@nitrohex.com>
To: "Martin K. Petersen" <mkp@kernel.org>
Cc: linux-scsi@vger.kernel.org, target-devel@vger.kernel.org, 
 stable@vger.kernel.org, Rongen Wang <security@nitrohex.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795787544; l=4058;
 i=security@nitrohex.com; s=nitrohex; h=from:subject:message-id;
 bh=5/Dtu7CSdvDwnXX4ATjaK74rHeFBYAS3kkaixR0Ih+M=;
 b=RhFiaOEd5YjmyHVMNjJK0beLTbUDvNkrMfUCFmcW+6LhHZeSfNzvEx9PJU8vQfntoJuHjBDCi
 8uuvPm0J858BNskLO5lTY5vKDOU5Ip6Dme6Lv9H6Y+nxes7e1vnYCv1
X-Developer-Key: i=security@nitrohex.com; a=ed25519;
 pk=Jk5NuTVJdxr1CTP4RuYaG31zSgsNlyFzVo9sphZTqt0=
X-Endpoint-Received: by B4 Relay for security@nitrohex.com/nitrohex with auth_id=1652
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A Login Request with a non-zero TSIH holds a session usage count from
iscsi_login_non_zero_tsih_s2() until the login completes. If the last
connection of the session is logged out with reason CLOSE_CONNECTION
while such a login is pending, iscsit_close_connection() moves the
session to TARG_SESS_STATE_FAILED and starts the Time2Retain timer. The
lookup found the session logged in and had no timer to stop.

When the timer expires, iscsit_time2retain_work() marks the session
ISCSI_TF_EXPIRED and calls iscsit_close_session(sess, false). That
removes the session from configfs and sets session_reinstatement, then
finds the usage count held by the login, clears session_logout again
and tries to restart the timer. As commit b30d7199af28 ("scsi: target:
iscsi: Run the Time2Retain handler in process context") notes, that
restart does nothing because ISCSI_TF_RUNNING is still set, and a later
expiry would stop at session_reinstatement anyway. Every lookup skips
an expired session, so nothing frees it after that. With the previous
patch the login is refused, and the session, its se_session and its
command tag pool stay allocated while the target keeps counting the
session. An initiator can repeat this with new ISIDs.

Handle such a login like one into a session that has already failed,
which stops the timer when it looks the session up: while a usage count
is held, leave the session alone and clear ISCSI_TF_RUNNING. The login
then stops the timer when it adds its connection, or starts it again
from iscsi_target_login_sess_out() when it fails. The other paths that
take a usage count on a session without connections set
session_reinstatement first, which the handler already checks.

The Time2Retain case was pointed out by the Sashiko AI review of v1 of
the previous patch; this patch was drafted with the help of an AI
assistant (Claude Opus 5.5, Anthropic, via Claude Code), and the result
was reviewed and tested as described in the cover letter.

Fixes: e48354ce078c ("iscsi-target: Add iSCSI fabric support for target v4.1")
Cc: stable@vger.kernel.org
Signed-off-by: Rongen Wang <security@nitrohex.com>
---
 drivers/target/iscsi/iscsi_target_erl0.c | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/drivers/target/iscsi/iscsi_target_erl0.c b/drivers/target/iscsi/iscsi_target_erl0.c
index 036ddc1002..35e2eed117 100644
--- a/drivers/target/iscsi/iscsi_target_erl0.c
+++ b/drivers/target/iscsi/iscsi_target_erl0.c
@@ -747,6 +747,7 @@ void iscsit_time2retain_work(struct work_struct *work)
 						   time2retain_work);
 	struct iscsi_portal_group *tpg = sess->tpg;
 	struct se_portal_group *se_tpg = &tpg->tpg_se_tpg;
+	bool in_use;
 
 	spin_lock_bh(&se_tpg->session_lock);
 	/* A stop after the timer fired takes ->time2retain_fired back. */
@@ -761,6 +762,26 @@ void iscsit_time2retain_work(struct work_struct *work)
 		spin_unlock_bh(&se_tpg->session_lock);
 		return;
 	}
+	/*
+	 * A login that adds a connection to this session holds a usage count
+	 * from iscsi_login_non_zero_tsih_s2() until it completes.  It started
+	 * before the session failed, so there was no timer for it to stop.
+	 * Handle it like a login into a failed session: leave the session
+	 * alone, and let the login stop the timer if it succeeds or start it
+	 * again in iscsi_target_login_sess_out() if it fails.  Expiring the
+	 * session now would make iscsit_close_session() find the usage count
+	 * and give up half way, after which nothing frees the session.
+	 */
+	spin_lock(&sess->session_usage_lock);
+	in_use = sess->session_usage_count != 0;
+	spin_unlock(&sess->session_usage_lock);
+	if (in_use) {
+		pr_debug("Time2Retain timer for SID: %u expired during a login, deferring\n",
+			 sess->sid);
+		sess->time2retain_timer_flags &= ~ISCSI_TF_RUNNING;
+		spin_unlock_bh(&se_tpg->session_lock);
+		return;
+	}
 	sess->time2retain_timer_flags |= ISCSI_TF_EXPIRED;
 
 	pr_err("Time2Retain timer expired for SID: %u, cleaning up"

-- 
2.34.1

