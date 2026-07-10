From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH v3 0/2] net: can: isotp-fixes
Date: Fri, 10 Jul 2026 14:56:08 +0200
Message-Id: <20260710-isotp-fixes-v3-0-08db68e27d0b@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOjrUGoC/32NQQ7CIBBFr9LMWgxgW2xX3sO4gDK1aFIIINE0v
 btQd8a4fJn/3iwQ0BsM0FcLeEwmGDtnOOwqGCY5X5EYnRk45S0VjBITbHRkNE8MBKUW9ZHqVqg
 RsuE8bocsnC8fDg91wyGWRFlMJkTrX9u7xMrudzkxQoloJNOMaaHH7jRJH+/Wuf2MEUo88T86z
 7oaGoG8bbpa8S99Xdc3YcVhe/oAAAA=
X-Change-ID: 20260710-isotp-fixes-ead7480d67bf
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, 
 Nico Yip <zdi-disclosures@trendmicro.com>, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783688170; l=1321;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=NS3KrhXR+AT+krE9/hJaYqMZJwCyWS2T+FlG0a2iPJc=;
 b=1xtEEa1oOQ1lEXaobnia4Mu1Sx7rRrwF+NNuC24TMmPOgK0s8uJ6h+rMB+fsT6bLylHyNmbje
 sfFiaE0zz66Bw0N1GXuIonFCNhQHQlbRFD/QJitS9T+wz7Ux5gxybbg
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As sashiko-bot was not able to check the second patch this bundle is
re-posted with b4 preparation.

It covers two fixes reported by Nico Yip and sashiko-bot.

Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
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
Oliver Hartkopp (2):
      can: isotp: use unconditional synchronize_rcu() in isotp_release()
      can: isotp: fix use-after-free race with concurrent NETDEV_UNREGISTER

 net/can/isotp.c | 96 ++++++++++++++++++++++++++++++++++++++++-----------------
 1 file changed, 67 insertions(+), 29 deletions(-)
---
base-commit: a635d6748234582ea287c5ffeae28b9b23f91c7e
change-id: 20260710-isotp-fixes-ead7480d67bf

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

