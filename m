From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH v5 0/4] net: can: isotp-fixes
Date: Fri, 10 Jul 2026 18:47:41 +0200
Message-Id: <20260710-isotp-fixes-v5-0-15174d82d6f1@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAC0iUWoC/33NQQ7CIBAF0Ks0rMUApVBdeQ/jAspg0aRtAImm6
 d2FujNNlz/z358ZBfAOAjpXM/KQXHDjkENzqFDXq+EO2JmcESNMEEkJdmGME7buDQGDMpK3xAi
 pLcpi8rAeMrjefjm89AO6WCZKo3chjv6zvku09LaXE8UEy0ZRQ6mRxp4uvfLxOU7TcYCIynhiO
 5xlrrtGAhPNiWu2wesdXmdOWqNFC0waojc43+E8c6a4sryWVtB/vizLF5OcUSR4AQAA
X-Change-ID: 20260710-isotp-fixes-ead7480d67bf
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, 
 Nico Yip <zdi-disclosures@trendmicro.com>, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783702070; l=1941;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=fbxpnqfv2gG/Jdn5a5VbX4NTrrS0xeNjf5CXffBbNDE=;
 b=8JrhUMxKG9HhMxpugwadJCykOBkRxd2onARoZLDGiUn4oRTVWhHkqhvlZLRaZF8gAg4/2QKSB
 Q4ng7YXbdHqDkQDJoJQ4IPrhevpNgebi/Bj9Pd6cOQwkMglOSdDcpaQ
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As sashiko-bot was not able to check the second patch this bundle is
re-posted with b4 preparation.

Add another two patches with fixes reported by sashiko-bot.

Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
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
      can: isotp: fix race between RX timer and consecutive frame reception
      can: isotp: fix lock-free state transition in tx timer handler

 net/can/isotp.c | 115 ++++++++++++++++++++++++++++++++++++++++----------------
 1 file changed, 83 insertions(+), 32 deletions(-)
---
base-commit: a635d6748234582ea287c5ffeae28b9b23f91c7e
change-id: 20260710-isotp-fixes-ead7480d67bf

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

