From: Roland Dreier <rolanddreier@rivian.com>
Subject: [PATCH v2 0/2] Couple of SCMI race fixes
Date: Wed, 09 Sep 2026 04:32:26 +0000
Message-Id: <20260909-scmi-async-done-race-v2-0-cc5dec25c6be@rivian.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFrhoGoC/4WNQQ6CMBBFr0Jm7RimCKgr72FYlHaQMaE1LTYSw
 t0FPIDLl7z//gyRg3CEazZD4CRRvFtBHTIwvXYPRrErg8pVlZ/phNEMgjpOzqD1jjFow6guRHV
 niS+6hHX6CtzJZ8/emx/Hd/tkM26tzegljj5M+2+izftzkQhzLIqypaqwdc18C5JEu6PxAzTLs
 nwB6wXKZcsAAAA=
X-Change-ID: 20260814-scmi-async-done-race-29117fd1e9a5
To: Sudeep Holla <sudeep.holla@kernel.org>, 
 Cristian Marussi <cristian.marussi@arm.com>
Cc: arm-scmi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Roland Dreier <rolanddreier@rivian.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788928354; l=2176;
 i=rolanddreier@rivian.com; s=20260814; h=from:subject:message-id;
 bh=GGvaoobDFjXxyynB7itBjEHKaBgEXjrPgUkJXaWfKWw=;
 b=Wd3xx9+HBZXxwiSDuiO7nMb+AEUibpqrk8KVUL3jzg0Bh28DAiyPw4TOmweKDH1VM+Mg5SHLi
 tzBihPf2lgkABSv8mRAU7bwcEeXfDyZXtFMpa+B81Vyce6sluDwTlQw
X-Developer-Key: i=rolanddreier@rivian.com; a=ed25519;
 pk=C7SBXsDIlarq7BpINqyDL67XV/AGNqNt09NCCpFcExk=
X-Endpoint-Received: by B4 Relay for rolanddreier@rivian.com/20260814 with auth_id=952
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Noticed a couple of races in SCMI code around delayed responses that
time out. These are probably nearly impossible to hit in practice but
the fixes are pretty straightforward and it seems worth having the
code be sound.

The v1 fixes were correct as posted, despite Sashiko warning that the
new "delayed_response_dropped" debug counter might never increment.
However, that review made me think that a new debug counter for a
one-in-a-gazillion race condition is probably less useful than a
kernel error message. So the change in v2 is having the first patch
log an error for a delayed response that arrives in the race window it
closes (matching the existing "Delayed Response not expected" error in
scmi_msg_response_validate()). The new error is expected to be
extremely rare but it makes sure there is no path where a delayed
response gets matched and then discarded without any logging.

Signed-off-by: Roland Dreier <rolanddreier@rivian.com>
---
Changes in v2:
- Patch 1: replace the new delayed_response_dropped debugfs counter
  with a dev_err() log message, since the condition is rare enough
  that logging is more useful than counting (per sashiko review of v1).
- Link to v1: https://patch.msgid.link/20260814-scmi-async-done-race-v1-0-335b163d77ee@rivian.com

To: Sudeep Holla <sudeep.holla@kernel.org>
To: Cristian Marussi <cristian.marussi@arm.com>
Cc: arm-scmi@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-kernel@vger.kernel.org

---
Roland Dreier (2):
      firmware: arm_scmi: Protect xfer->async_done with xfer->lock
      firmware: arm_scmi: Don't reuse raw xfers with async_done still armed

 drivers/firmware/arm_scmi/common.h    | 22 ++++++++++++++++++++
 drivers/firmware/arm_scmi/driver.c    | 38 ++++++++++++++++++++++++++++++-----
 drivers/firmware/arm_scmi/protocols.h |  9 ++++++---
 drivers/firmware/arm_scmi/raw_mode.c  | 29 ++++++++++++++++++++------
 4 files changed, 84 insertions(+), 14 deletions(-)
---
base-commit: 786262be6048deab760f68c8acc2c85607165894
change-id: 20260814-scmi-async-done-race-29117fd1e9a5

Best regards,
--  
Roland Dreier <rolanddreier@rivian.com>

