From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH v6 0/5] net: can: isotp-fixes
Date: Fri, 10 Jul 2026 22:42:51 +0200
Message-Id: <20260710-isotp-fixes-v6-0-a13c2539093d@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEtZUWoC/33NwU7EIBAG4FfZcBbDUGC6e/I9jAfoDBZN2gaw0
 Wz67tL1Zpoe/8z//XMXhXPiIm6Xu8i8ppLmqQX3dBHD6Kd3lolaFlpppxCUTGWui4zpm4tkT2h
 6RQ5DFE0smR+HBl7f/nL5Ch881H1ib4yp1Dn/PN6tsPeOl1eQSqL1QACEFK8vo8/1c16W54mr2
 MdXfcJ142GwyNrZqwn6gHcnvGtc9RRczxpJhQNuTrhpXHvjo+kwOjji9oTbxsECGuo1uQj/+LZ
 tvw1AiFC3AQAA
X-Change-ID: 20260710-isotp-fixes-ead7480d67bf
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, 
 Nico Yip <zdi-disclosures@trendmicro.com>, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783716177; l=2437;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=F1wyvrvRF+nWvIfcUA4gqhfZFnraNE6gSWRt3hbKNWY=;
 b=2Zn+7bYRPJ6BWkuC7AeLM1igxSVrWD3Y+4UOWcDT+cKChrcMFkwRFuT5noTTW8sjKzwdsi74o
 fmfBmHbVmZaCmzFaYmMHNyMSTe/5rmaiqKQ7aRncL1tyeaUqqqRWeZF
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As sashiko-bot was not able to check the second patch this bundle is
re-posted with b4 preparation.

Fixed the remarks reported by sashiko-bot of V5 patchset.

Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
Changes in v6:
- patch 2: check for rx state and tx state to be IDLE in isotp_bind() (sashiko-bot)
- patch 3: double check rx/tx states after all hrtimer_cancel() calls (sashiko-bot)
           move ISOTP_IDLE in err_event_drop for the same reason
- patch 4: use READ_ONCE() to prevent compiler load tearing as remarked by sashiko-bot
- Link to v5: https://patch.msgid.link/20260710-isotp-fixes-v5-0-15174d82d6f1@hartkopp.net

Changes in v5:
- patch 3: new: state change re-check after hrtimer_cancel()
- patch 4: new: handle state transistion with cmpxchg()
- Link to v4: https://patch.msgid.link/20260710-isotp-fixes-v4-0-2a4af437f61b@hartkopp.net

Changes in v4:
- patch 2: use a simpler method to reject a re-binding that can be implemented
  inside the lock: No waitqueue waiting just exit.
- Link to v3: https://patch.msgid.link/20260710-isotp-fixes-v3-0-08db68e27d0b@hartkopp.net

Changes in v3:
- patch 2: go back to initial idea without hard resetting the state machine and
  timers but let these come to a graceful end. Even a new bind() at netdev
  shutdown now leads to this graceful statemachine shutdown via the wait queue.
- Link to v2: https://patch.msgid.link/20260710-isotp-fixes-v2-0-bc57e26594b2@hartkopp.net

Changes in v2:
- patch 2: shutdown state machine to fix sashiko-bot complains
  Link: https://lore.kernel.org/linux-can/20260710094807.A50DD1F000E9@smtp.kernel.org/
- Link to v1: https://patch.msgid.link/20260710-isotp-fixes-v1-0-75a1d11d7df9@hartkopp.net

---
Oliver Hartkopp (5):
      can: isotp: use unconditional synchronize_rcu() in isotp_release()
      can: isotp: fix use-after-free race with concurrent NETDEV_UNREGISTER
      can: isotp: fix race between RX/TX timers and frame reception
      can: isotp: fix lock-free state transition in tx timer handler
      can: isotp: fix state machine corruption on signal interruption

 net/can/isotp.c | 137 +++++++++++++++++++++++++++++++++++++++++---------------
 1 file changed, 102 insertions(+), 35 deletions(-)
---
base-commit: a635d6748234582ea287c5ffeae28b9b23f91c7e
change-id: 20260710-isotp-fixes-ead7480d67bf

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

