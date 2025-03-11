From: Amit Sunil Dhamne <amitsd@google.com>
Date: Mon, 10 Mar 2025 19:19:07 -0700
Subject: [PATCH] usb: typec: tcpm: fix state transition for
 SNK_WAIT_CAPABILITIES state in run_state_machine()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250310-fix-snk-wait-timeout-v6-14-rc6-v1-1-5db14475798f@google.com>
X-B4-Tracking: v=1; b=H4sIAJqdz2cC/x2NQQqDMBQFryJ/7YPEWiW9irgw8Vs/pbEkqQri3
 Q0uZzEzB0UOwpFexUGBV4my+Ay6LMjNg38zZMxMlaqe6qEVJtkR/QfbIAlJvrz8E9YGukZwDVp
 bj2ayxjpjKEd+gbNxD7r+PC8ebybscAAAAA==
X-Change-ID: 20250310-fix-snk-wait-timeout-v6-14-rc6-7b4d9fb9bc99
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 RD Babiera <rdbabiera@google.com>, Kyle Tso <kyletso@google.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Xu Yang <xu.yang_2@nxp.com>, stable@vger.kernel.org, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741659565; l=1869;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=XWKs46l6MPTHMIBPMpAx7vxNIqzh3Rjw4va51+i3hu0=;
 b=mOi/HQ11Z/dzJ5PxxlT67S+U9on/YeTBQANmHH5IF/SogEd0hxlPmReJW7KBH8mte5yaCXODy
 Z0P5YiKv/lqDw0c7ak5BFfx5wnO/acB2v7BH7AEhFAbAbhHPwrtfGqe
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A subtle error got introduced while manually fixing merge conflict in
tcpm.c for commit 85c4efbe6088 ("Merge v6.12-rc6 into usb-next"). As a
result of this error, the next state is unconditionally set to
SNK_WAIT_CAPABILITIES_TIMEOUT while handling SNK_WAIT_CAPABILITIES state
in run_state_machine(...).

Fix this by setting new state of TCPM state machine to `upcoming_state`
(that is set to different values based on conditions).

Cc: stable@vger.kernel.org
Fixes: 85c4efbe60888 ("Merge v6.12-rc6 into usb-next")
Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
Reviewed-by: Badhri Jagan Sridharan <badhri@google.com>
---
 drivers/usb/typec/tcpm/tcpm.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/typec/tcpm/tcpm.c b/drivers/usb/typec/tcpm/tcpm.c
index 47be450d2be352698e9dee2e283664cd4db8081b..758933d4ac9e4e55d45940b068f3c416e7e51ee8 100644
--- a/drivers/usb/typec/tcpm/tcpm.c
+++ b/drivers/usb/typec/tcpm/tcpm.c
@@ -5117,16 +5117,16 @@ static void run_state_machine(struct tcpm_port *port)
 		 */
 		if (port->vbus_never_low) {
 			port->vbus_never_low = false;
-			tcpm_set_state(port, SNK_SOFT_RESET,
-				       port->timings.sink_wait_cap_time);
+			upcoming_state = SNK_SOFT_RESET;
 		} else {
 			if (!port->self_powered)
 				upcoming_state = SNK_WAIT_CAPABILITIES_TIMEOUT;
 			else
 				upcoming_state = hard_reset_state(port);
-			tcpm_set_state(port, SNK_WAIT_CAPABILITIES_TIMEOUT,
-				       port->timings.sink_wait_cap_time);
 		}
+
+		tcpm_set_state(port, upcoming_state,
+			       port->timings.sink_wait_cap_time);
 		break;
 	case SNK_WAIT_CAPABILITIES_TIMEOUT:
 		/*

---
base-commit: 5c8c229261f14159b54b9a32f12e5fa89d88b905
change-id: 20250310-fix-snk-wait-timeout-v6-14-rc6-7b4d9fb9bc99

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

