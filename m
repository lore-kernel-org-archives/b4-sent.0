From: Oliver Hartkopp <socketcan@hartkopp.net>
Subject: [PATCH 0/2] net: can: isotp-fixes
Date: Fri, 10 Jul 2026 11:32:43 +0200
Message-Id: <20260710-isotp-fixes-v1-0-75a1d11d7df9@hartkopp.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADu8UGoC/yXMQQqAIBCF4avIrBMsQqOrRIvKqaaFhmMRSHfPa
 vnx+F8CxkDI0IoEAU9i8i6jLARM6+AWlGSzoVKVVqZUktjHXc50IUscrKkbZbUZZ8jFHvAbctD
 1v/kYN5ziewH3/QAW92AvbwAAAA==
X-Change-ID: 20260710-isotp-fixes-ead7480d67bf
To: linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, 
 Nico Yip <zdi-disclosures@trendmicro.com>, sashiko-bot@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783675969; l=706;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=++/bfR+pKzCQEjfPDXoWjC/JtL4+USopQUJI5PGVIN0=;
 b=Dj2f4pFfZxOZVb5Djy6avpd7IqBhx3LF0f8mpvFa21tCmQX9mOFGfIsTtEtyo9TSkDBMExMg6
 hNx+xGnx8rtA2VKSLzkpzvnwhGbQKMqj210MD3uX00NeVNOAfDStWcO
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As sashiko-bot was not able to check the second patch this bundle is
re-posted with b4 preparation.

It covers two fixes reported by Nico Yip and sashiko-bot.

Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
Oliver Hartkopp (2):
      can: isotp: use unconditional synchronize_rcu() in isotp_release()
      can: isotp: fix use-after-free race with concurrent NETDEV_UNREGISTER

 net/can/isotp.c | 77 +++++++++++++++++++++++++++++++++++----------------------
 1 file changed, 48 insertions(+), 29 deletions(-)
---
base-commit: a635d6748234582ea287c5ffeae28b9b23f91c7e
change-id: 20260710-isotp-fixes-ead7480d67bf

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

