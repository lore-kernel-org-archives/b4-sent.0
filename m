From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH v2 0/2] can: bcm: add/fix locking for config updates at
 runtime
Date: Thu, 19 Feb 2026 13:47:30 +0100
Message-Id: <20260219-bcm_spin_lock_init-v2-0-694352bfca62@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGMGl2kC/32NwQ6CMBAFf4Xs2RpaKame/A9DGlpWWdG2aSvRE
 P5dwLvHSebNmyBhJExwKiaIOFIi7xYQuwJs37obMuoWBlGKuhRcMWOfOgVy+uHtoMlRZkJyhUZ
 1lSw5LMMQ8UrvLXppfpxe5o42r6XV6CllHz/b68hX7+/ByBln8ijqQ2VVK408923Mgw9h7zBDM
 8/zF3H0nk7JAAAA
X-Change-ID: 20260218-bcm_spin_lock_init-2518eb8d4501
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 "David S. Miller" <davem@davemloft.net>, 
 Urs Thuermann <urs.thuermann@volkswagen.de>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Oliver Hartkopp <socketcan@hartkopp.net>, 
 syzbot+5b11eccc403dd1cea9f8@syzkaller.appspotmail.com, 
 syzbot+75e5e4ae00c3b4bb544e@syzkaller.appspotmail.com
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771505254; l=869;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=cpBnC8pH/PiD3SRicQ3PJ1gVjD/QbqD3gNTHM2XRWnM=;
 b=UfrzPc03KntdzKKCeEksDrBUy1B0dRbzpJbA9/PqKuCtStIfLZ/rk8mEH4mC4kRBXQ75eQuNp
 qRMUx/fj9/IDy0cRqXyA4yemjjiVb2ELzZDSs31IvhDLt8PsfYXvq1Q
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Address two locking issues detected by KASAN and KCSAN.

The first patch fixes an unintialized spin_lock in the KASAN fix.
The second patch addresses the update of content in bcm_rx_setup().

Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
Changes in v2:
- Add a second patch addressing the KCSAN report
- Link to v1: https://patch.msgid.link/20260218-bcm_spin_lock_init-v1-1-592634c8a5b5@hartkopp.net

---
Oliver Hartkopp (2):
      can: bcm: fix locking for bcm_op runtime updates
      can: bcm: add locking when updating filter and timer values

 net/can/bcm.c | 40 +++++++++++++++++++++++++++++++++-------
 1 file changed, 33 insertions(+), 7 deletions(-)
---
base-commit: 2961f841b025fb234860bac26dfb7fa7cb0fb122
change-id: 20260218-bcm_spin_lock_init-2518eb8d4501

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

