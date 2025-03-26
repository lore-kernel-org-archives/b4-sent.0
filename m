From: Hermes Wu <Hermes.wu@ite.com.tw>
Subject: [PATCH v2 0/5] drm/bridge: it6505: fix DP link traning and improve
 compatibility
Date: Wed, 26 Mar 2025 13:34:12 +0800
Message-Id: <20250326-fix-link-training-v2-0-756c8306f500@ite.com.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANSR42cC/x2MQQqAIBAAvxJ7bkFFBftKdIjabCm20IhA+nvSc
 WBmCmRKTBm6pkCimzMfUsG0DUzrKJGQ58pglHFKG40LP7izbHilkYUlovXaBmeD9c5B7c5EVfq
 f/fC+Hwia3E9jAAAA
X-Change-ID: 20250121-fix-link-training-461495494655
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: Pet.Weng@ite.com.tw, Kenneth.Hung@ite.com.tw, treapking@chromium.org, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742967277; l=1323;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=oKGOdDgxhAqNZ5oSM5iv/OnF2CxCH6tBHGl2VSB8qc8=;
 b=82T34WmCkdjj6qSV8M4kPQjRl4ckK8npAAKkeembaXRcV/OIg3QCR0QAJk84CiH5zcAZGx/sb
 J4byaM9Mb6DBdb5KWK618gl/kTW7KBxDq/QAvZeg0xYHlDbedTFttC7
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IT6505 supports HW auto link training which will write DPCD and check
training status automatically. Some DP device can not pass
HW auto link training and must set link training step by step.

when HW auto link training fail, it may trigger video FIFO error,
and link training process will reset to beginning, and never try
step training method.

Modify training method improve compatibility to these DP devices.

v1 -> v2:
	1. Split [PATCH 1/3] into 3 commits
	2. Drop non necessary variable auto_ttrain_retry
	v1 link: https://lore.kernel.org/all/20250318-fix-link-training-v1-0-19266711142c@ite.com.tw/

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Hermes Wu (5):
      drm/bridge: it6505: fix link training state HW register reset
      drm/bridge: it6505: check INT_LINK_TRAIN_FAIL while link auto training
      drm/bridge: it6505: modify DP link auto training
      drm/bridge: it6505: modify DP link training work
      drm/bridge: it6505: skip auto training when previous try fail

 drivers/gpu/drm/bridge/ite-it6505.c | 112 +++++++++++++++++++++---------------
 1 file changed, 65 insertions(+), 47 deletions(-)
---
base-commit: 938fbb16aba8f7b88e0fdcf56f315a5bbad41aad
change-id: 20250121-fix-link-training-461495494655

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

