From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH v7 0/5] net: can: isotp-fixes
Date: Sat, 11 Jul 2026 14:07:11 +0200
Message-Id: <20260711-isotp-fixes-v7-0-f03af24d8397@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO8xUmoC/33NTWrDMBAF4KsEraui0a+dVe8RupA8o1ot2MZyT
 Urw3SunuyK0fMz73jxYpjVRZtfLg620p5zmqQT3cmHD6KcP4glLZlJIKxwInvK8LTymO2VOHp3
 uBFoXIitiWel5KOD2/pfzd/ikYTsnzsaY8javP893O5y9+vIOXHBnPCAAOoz92+jX7WtelteJN
 naO77LBZeFhMI6kNb0OssJVg6vCRYfBdiQdilDhusF14dJrH7Vy0UKNmwY3hYMBp7GTaCNUuG1
 wW7gHNUijetEr/MeP4/gFvgg5ifYBAAA=
X-Change-ID: 20260710-isotp-fixes-ead7480d67bf
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, 
 Nico Yip <zdi-disclosures@trendmicro.com>, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783771634; l=2690;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=cifrS8XB2M5Sb7Mga4Ht3Xqhy5uFkAiqFJeObjOwE/8=;
 b=UT4NjMaFQBDQ49o54nSwMvUrf98o2pyFhcyyYMwXrpMmIXyEgUSG9nNU1K2oxExKtYFj0/m4V
 dz+gDyMNSrJCxRrhH/YiOdHAu/fc5ppd9DwcAuwUBeT8FNrnybr8dnI
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As sashiko-bot was not able to check the second patch this bundle is
re-posted with b4 preparation.

Fixed the remarks reported by sashiko-bot of V6 patchset.

Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
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
Oliver Hartkopp (5):
      can: isotp: use unconditional synchronize_rcu() in isotp_release()
      can: isotp: fix use-after-free race with concurrent NETDEV_UNREGISTER
      can: isotp: fix race between RX/TX timers and frame reception
      can: isotp: fix lock-free state transition in tx timer handler
      can: isotp: fix state machine corruption on signal interruption

 net/can/isotp.c | 176 +++++++++++++++++++++++++++++++++++++++++++-------------
 1 file changed, 135 insertions(+), 41 deletions(-)
---
base-commit: a635d6748234582ea287c5ffeae28b9b23f91c7e
change-id: 20260710-isotp-fixes-ead7480d67bf

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

