From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH v3 0/3] can: bcm: add/fix locking for config updates at
 runtime
Date: Thu, 19 Feb 2026 17:51:16 +0100
Message-Id: <20260219-bcm_spin_lock_init-v3-0-c61026740d7b@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIU/l2kC/32N0Q6CIBhGX6VxHQ1+hWFXvUdrThDzz0IHxGrOd
 0/tprXW5dm+75yRBOvRBrLfjMTbhAF7N0O23RDTVu5sKdYzE2AgGXBFtbmVYUBXXnvTlegwUhB
 cWa3qXDBO5uPgbYOPVXo8vTnc9cWauJiWRYsh9v65VhNfdn8DiVNORQEyy42qhBaHtvKx64dh5
 2wkSyPBp6X4aQHKqCzyTIBuTCXhyzJN0wsXgEGcDwEAAA==
X-Change-ID: 20260218-bcm_spin_lock_init-2518eb8d4501
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 "David S. Miller" <davem@davemloft.net>, 
 Urs Thuermann <urs.thuermann@volkswagen.de>, 
 Vincent Mailhol <mailhol@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Oliver Hartkopp <socketcan@hartkopp.net>, 
 syzbot+5b11eccc403dd1cea9f8@syzkaller.appspotmail.com, 
 syzbot+75e5e4ae00c3b4bb544e@syzkaller.appspotmail.com
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771519907; l=1272;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=FX/CbMPTMHFx6PJAqRVJn6ooY06+Q38yaEEBkyuTcGg=;
 b=tZTXSv3ygDdMjIucb6FBaPaLJg77BzmIBjTfOEGen762JZ7wa9bBf9fo0/+NL7AE3bUUWQ1l3
 7hKCupNJD7fCjJ0cdKLAkWTVXX6oxCbiRv9dHg93hlu23GnGry+lVIx
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Address three locking issues detected by KASAN and KCSAN.

The first patch fixes an unintialized spin_lock in the KASAN fix.
The second patch addresses the update of content in bcm_rx_setup().
The third patch adds a missing atomic conversion in can_rcv_filter().

Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
Changes in v3:
- Add a third patch that fixes a KCSAN issue that showed up while testing
  patch 2 8-)
- Link to v2: https://patch.msgid.link/20260219-bcm_spin_lock_init-v2-0-694352bfca62@hartkopp.net

Changes in v2:
- Add a second patch addressing the KCSAN report
- Link to v1: https://patch.msgid.link/20260218-bcm_spin_lock_init-v1-1-592634c8a5b5@hartkopp.net

---
Oliver Hartkopp (3):
      can: bcm: fix locking for bcm_op runtime updates
      can: bcm: add locking when updating filter and timer values
      can: statistics: add missing atomic access in hot path

 net/can/af_can.c |  4 ++--
 net/can/af_can.h |  2 +-
 net/can/bcm.c    | 40 +++++++++++++++++++++++++++++++++-------
 3 files changed, 36 insertions(+), 10 deletions(-)
---
base-commit: 2961f841b025fb234860bac26dfb7fa7cb0fb122
change-id: 20260218-bcm_spin_lock_init-2518eb8d4501

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

