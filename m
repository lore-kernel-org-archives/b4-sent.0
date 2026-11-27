From: Rongen Wang <security@nitrohex.com>
Subject: [PATCH v2 0/2] scsi: target: iscsi: Fix adding a connection to a
 session that is going away
Date: Fri, 27 Nov 2026 22:52:17 +0900
Message-Id: <20261127-b4-lio-iscsi-session-closing-v2-0-a3ac8e88cbad@nitrohex.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABGLCWsC/42NQQ6CMBBFr0K6dgxtgKor72FY0DKFMdiSDhIM4
 e5SvIDLl7z//ioYIyGLW7aKiDMxBb+DOmXC9o3vEKjdWahcVVIqDaaAgQIQWyZg5DQAOwQm30G
 lXVGWOr8WFsWeGCM6Wo78o/4xv80T7ZSayeiJpxA/x/8sk/fn1SxBgm2dMsagu+jm7mmKocflb
 MNL1Nu2fQGBSs483QAAAA==
X-Change-ID: 20261127-b4-lio-iscsi-session-closing-67f4557094ce
To: "Martin K. Petersen" <mkp@kernel.org>
Cc: linux-scsi@vger.kernel.org, target-devel@vger.kernel.org, 
 stable@vger.kernel.org, Rongen Wang <security@nitrohex.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795787544; l=3684;
 i=security@nitrohex.com; s=nitrohex; h=from:subject:message-id;
 bh=FJxkAExIpijc1W5AmHMxIwSKUeapmDr1hiW+kDfw7Xo=;
 b=DV/GYPuyLxRQ3MobJp3vc/xrY846H6W3PatC7Hp34WPr0ABGiKxeLir4vc/aq1zPCTDzmZnVa
 exQ2xoPdVWJD2n5/+FgFV/5tHPoBNVfFeAOSqo/eRUS5Isw5A8OMxVM
X-Developer-Key: i=security@nitrohex.com; a=ed25519;
 pk=Jk5NuTVJdxr1CTP4RuYaG31zSgsNlyFzVo9sphZTqt0=
X-Endpoint-Received: by B4 Relay for security@nitrohex.com/nitrohex with auth_id=1652
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A Login Request with a non-zero TSIH can complete after the session it
joins has lost its last connection. Patch 1 makes
iscsi_post_login_handler() refuse such a login when the session is
being closed or its Time2Retain timer has expired. Patch 2 keeps the
Time2Retain handler from expiring a session while such a login holds
it; without patch 2 the session that patch 1 refuses to join is never
freed.

Based on mkp/scsi.git 7.4/scsi-fixes (4be084ac36f9). Patch 2 changes
iscsit_time2retain_work() from b30d7199af28 ("scsi: target: iscsi: Run
the Time2Retain handler in process context"), which is in that tree and
marked for stable. Patch 1 also applies to mainline 9437ee8b6cf6.

Tested on that tree under QEMU, iSCSI/TCP, with KASAN and again with
KASAN plus PROVE_LOCKING, DEBUG_ATOMIC_SLEEP and DEBUG_OBJECTS_TIMERS /
DEBUG_OBJECTS_WORK:

- Last connection reset while a TSIH != 0 login is parked (the v1
  case): the login is refused, no report.
- DefaultTime2Retain=2, last connection logged out with CLOSE_CONNECTION
  while a TSIH != 0 login is parked, login finished after the timer ran
  out: the login continues the session, I/O works, and the session is
  freed when that connection is reset or logs out. Without the series,
  and with v1, the connection joins the half closed session and its
  logout gives the KASAN report quoted in patch 1. With patch 1 alone
  the login is refused and the session stays allocated.
- The same with DefaultTime2Retain=1 and the final Login PDU sent
  0.6 s to 1.4 s after the logout, 40 rounds: every login continues its
  session, no session is left allocated, no report. With v1, 14 of the
  16 rounds that ran into the expiry gave KASAN reports; with patch 1
  alone 17 sessions were left allocated.
- MaxConnections=2: adding a connection to a live session, I/O on both,
  logouts, a fresh login, and session continuation after a
  CLOSE_CONNECTION logout still work.
- NodeACL removed while a TSIH != 0 login is parked: no report.

The refusal path in __iscsi_target_login_thread() (login completed by
its first PDU) was not reached by these tests; iSER and cxgbit were not
tested. No W=1 warnings in drivers/target/iscsi/, checkpatch clean.

Reproducers for both cases go to the maintainer privately and are not
posted here.

---
Changes in v2:
- Patch 1: also refuse the login when the Time2Retain timer has
  expired, check under se_tpg->session_lock and sess->conn_lock like
  the session lookups do, and stop the timer before session_lock is
  dropped (Sashiko review)
- Patch 1: take over the session parameters and release
  conn->param_list only after the check (Sashiko review)
- New patch 2: do not let Time2Retain expire a session while a login
  holds a usage count
- Sashiko review of v1: https://sashiko.dev/#/patchset/20261127-b4-lio-iscsi-session-closing-v1-1-cdf2bbbef87a@nitrohex.com
- Link to v1: https://patch.msgid.link/20261127-b4-lio-iscsi-session-closing-v1-1-cdf2bbbef87a@nitrohex.com

---
Rongen Wang (2):
      scsi: target: iscsi: Refuse to add a connection to a session being closed
      scsi: target: iscsi: Do not let Time2Retain expire a session in use

 drivers/target/iscsi/iscsi_target_erl0.c  |  21 ++++++
 drivers/target/iscsi/iscsi_target_login.c | 117 ++++++++++++++++++++++++------
 drivers/target/iscsi/iscsi_target_login.h |   4 +-
 drivers/target/iscsi/iscsi_target_nego.c  |   5 +-
 4 files changed, 121 insertions(+), 26 deletions(-)
---
base-commit: 4be084ac36f95f95e21a1e39207e87326967a73d
change-id: 20261127-b4-lio-iscsi-session-closing-67f4557094ce

Best regards,
--  
Rongen Wang <security@nitrohex.com>

