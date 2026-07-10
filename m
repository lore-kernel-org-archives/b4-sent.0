From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH v2 0/2] net: can: isotp-fixes
Date: Fri, 10 Jul 2026 13:31:20 +0200
Message-Id: <20260710-isotp-fixes-v2-0-bc57e26594b2@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAjYUGoC/22NwQ7CIBBEf6XZsxggWtST/2F6oGWxq0khLBJN0
 3+X1qvHl5k3MwNjImS4NDMkLMQUpgp618Aw2umOglxl0FK30igpiEOOwtMbWaB15nCSrjW9h2r
 EhFtQhVv3Y371DxzyOrE2RuIc0me7K2rt/V8uSkhhjlY5pZxx/nwdbcrPEON+wgzdsixf36KVk
 bsAAAA=
X-Change-ID: 20260710-isotp-fixes-ead7480d67bf
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, 
 Nico Yip <zdi-disclosures@trendmicro.com>, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783683095; l=973;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=VVXjTxY9WFpOeSEzngZ1FeJfF/9Bz9NDUcP2pB6hFYo=;
 b=IbhAriRn/pAYjiZljWZONmOO+7WAZnLXLOd25Qjzj/AVtu34noD1kfMSa+hIjq3FQwAnKqaKf
 oAbg2GZt5zCBnlzfrCyg45j8Zz+HjI0Aak5F+La6a0Jt39ZN+M3ivtr
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As sashiko-bot was not able to check the second patch this bundle is
re-posted with b4 preparation.

It covers two fixes reported by Nico Yip and sashiko-bot.

Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
Changes in v2:
- patch 2: shutdown state machine to fix sashiko-bot complains
  Link: https://lore.kernel.org/linux-can/20260710094807.A50DD1F000E9@smtp.kernel.org/
- Link to v1: https://patch.msgid.link/20260710-isotp-fixes-v1-0-75a1d11d7df9@hartkopp.net

---
Oliver Hartkopp (2):
      can: isotp: use unconditional synchronize_rcu() in isotp_release()
      can: isotp: fix use-after-free race with concurrent NETDEV_UNREGISTER

 net/can/isotp.c | 103 ++++++++++++++++++++++++++++++++++++++++----------------
 1 file changed, 74 insertions(+), 29 deletions(-)
---
base-commit: a635d6748234582ea287c5ffeae28b9b23f91c7e
change-id: 20260710-isotp-fixes-ead7480d67bf

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

