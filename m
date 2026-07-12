From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH v9 0/4] net: can: isotp-fixes
Date: Sun, 12 Jul 2026 15:44:04 +0200
Message-Id: <20260712-isotp-fixes-v9-0-137840d7f0f4@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACSaU2oC/33QTWrEMAwF4KsMXtfFlv/iWfUepQs7lhu3MAlxG
 lqG3L3KdDNTTJYP6XsCXVnFuWBl59OVzbiWWsYLBf90Yv0QLu/IS6LMQIAVTgpe6rhMPJdvrBx
 DcroTybqYGYlpxtuAwOvbX65f8QP7Za/YN4ZSl3H+uZ1b5b7Xbl4lF9yZIJOUyaXsX4YwL5/jN
 D1fcGF7+QoHHIjH3jgEa7yO0ODqgCviokvRdgguidjg+oBr4hB0yFq5bGWLmwNuiEsjnU4dJJt
 lg9sDbokHqXowyguvUoO7ey4fuSOehQoZ6L7yrsG7ew6PvCPeKw8ggkat/39+27ZfSGedWnQCA
 AA=
X-Change-ID: 20260710-isotp-fixes-ead7480d67bf
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, 
 Nico Yip <zdi-disclosures@trendmicro.com>, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783863845; l=3097;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=FSrfVZrwwzE15HNSz1SU20TdCyh17KljLIlTF9UHTbE=;
 b=NO8cVjPYDJjJe5Qz+w19UqMbK9acC3YKyA0cbydraN5d/zpfKIBJS1mTfMTX8QU7Z2N8ommAN
 eAa46JuYYMfAPrhF07Q5GZ7TopsPNgUpIIw0vLGT49L+Y+e5gmxb0y4
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As sashiko-bot was not able to check the second patch this bundle is
re-posted with b4 preparation.

Fixed the remarks reported by sashiko-bot of V8 patchset.

Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
Changes in v9:
- patch 3: fix two reported issues and explain why issue 3&4 (-ECOMM sk_err
  handling) will not be changed
- Link to v8: https://patch.msgid.link/20260712-isotp-fixes-v8-0-c39220a4e442@hartkopp.net

Changes in v8:
- patch 3: properly terminate the former transmission before starting
- patch 4: formerly patch 5 as the former patch 4 is squashed into patch 3
- Link to v7: https://patch.msgid.link/20260711-isotp-fixes-v7-0-f03af24d8397@hartkopp.net

Changes in v7:
- patch 3: add helper so->tx_gen to monitor new ISOTP_SENDING attempts
- patch 4: prevent missasignment of sk_err report with new so->tx_gen
- Link to v6: https://patch.msgid.link/20260710-isotp-fixes-v6-0-a13c2539093d@hartkopp.net

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
Oliver Hartkopp (4):
      can: isotp: use unconditional synchronize_rcu() in isotp_release()
      can: isotp: fix use-after-free race with concurrent NETDEV_UNREGISTER
      can: isotp: fix race between RX/TX timers and frame reception
      can: isotp: fix state machine corruption on signal interruption

 net/can/isotp.c | 286 +++++++++++++++++++++++++++++++++++++++++++-------------
 1 file changed, 220 insertions(+), 66 deletions(-)
---
base-commit: dd3210c47e8d3ac6b4e9141fc68acc03b38c0ba3
change-id: 20260710-isotp-fixes-ead7480d67bf

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

