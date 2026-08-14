From: Roland Dreier <rolanddreier@rivian.com>
Subject: [PATCH 0/2] Couple of SCMI race fixes
Date: Fri, 14 Aug 2026 20:15:32 +0000
Message-Id: <20260814-scmi-async-done-race-v1-0-335b163d77ee@rivian.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGV3f2oC/yXMSw7CMAxF0a1UHmOpjsqnbAUxCM4rGIkUxYCKq
 u6dAMMzuHcmRzE47ZuZCl7mNuYKWTWkl5jPYEvVFNqwaXfSsevNOPo7K6cxg0tUcOhFtkMS9HF
 NNb0XDDb9tofj3/48XaGP74uW5QPeOiOYeAAAAA==
X-Change-ID: 20260814-scmi-async-done-race-29117fd1e9a5
To: Sudeep Holla <sudeep.holla@kernel.org>, 
 Cristian Marussi <cristian.marussi@arm.com>
Cc: arm-scmi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786738610; l=965;
 i=rolanddreier@rivian.com; s=20260814; h=from:subject:message-id;
 bh=kyXZxlfFjxRc8A1yzHEvXAwoUlJDSZwiNaHsfRS0PTc=;
 b=fklnXBet195Xl7+9WUzlKKApBOJT/7ophRWBEu3jZJc8RCaHZJiU3N8XIGeV9zKyUoUWqu5zt
 o+iT2qg8zcMC8dp/gPXNdObtdLNh1NnL1yd21kGJdBVoC8JO/IhqaLP
X-Developer-Key: i=rolanddreier@rivian.com; a=ed25519;
 pk=C7SBXsDIlarq7BpINqyDL67XV/AGNqNt09NCCpFcExk=
X-Endpoint-Received: by B4 Relay for rolanddreier@rivian.com/20260814 with auth_id=952
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Noticed a couple of races in SCMI code around delayed responses that
time out. These are probably nearly impossible to hit in practice but
the fixes are pretty straightforward and it seems worth having the
code be sound.

Signed-off-by: Roland Dreier <rolanddreier@rivian.com>
---
Roland Dreier (2):
      firmware: arm_scmi: Protect xfer->async_done with xfer->lock
      firmware: arm_scmi: Don't reuse raw xfers with async_done still armed

 drivers/firmware/arm_scmi/common.h    | 23 ++++++++++++++++++++++
 drivers/firmware/arm_scmi/driver.c    | 36 ++++++++++++++++++++++++++++++-----
 drivers/firmware/arm_scmi/protocols.h |  9 ++++++---
 drivers/firmware/arm_scmi/raw_mode.c  | 29 ++++++++++++++++++++++------
 4 files changed, 83 insertions(+), 14 deletions(-)
---
base-commit: a5161661ae99f497affa83a5b8654e457cda6267
change-id: 20260814-scmi-async-done-race-29117fd1e9a5

Best regards,
--  
Roland Dreier <rolanddreier@rivian.com>

