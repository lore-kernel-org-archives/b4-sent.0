From: Hermes Wu <Hermes.wu@ite.com.tw>
Subject: [PATCH 0/3] drm/bridge: it6505: fix DP link traning and improve
 compatibility
Date: Fri, 24 Jan 2025 10:29:49 +0800
Message-Id: <20250124-fix-link-training-v1-0-09511050bb2c@ite.com.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAB37kmcC/x2MQQqAIBAAvxJ7biFFBftKdJDabCm20Igg/HvSc
 WBmXsiUmDL0zQuJbs58SAXVNjCtQSIhz5VBd9p2Sitc+MGdZcMrBRaWiMYp463xxlkLtTsTVel
 /DmMpH+7UTpBjAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737685792; l=981;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=lkxo+9LVgxm6dhaHGk+NaX5zVVLdjBJs7FFXNg4RePk=;
 b=YhoywIYTs+NTolC/YyX01oo5IBV1HCVbm3ocMOHfnBlL5EoJ19rtp1w93+OXX6gkem6mrJEv+
 4bAYFEByIdjDLtB0DDeE/Hs3YES+mEqWMhmq9G+FYtHrmQbftX//uWc
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

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Hermes Wu (3):
      drm/bridge: it6505: modify DP link auto training
      drm/bridge: it6505: modify DP link training work
      drm/bridge: it6505: skip auto training when previous try fail

 drivers/gpu/drm/bridge/ite-it6505.c | 106 ++++++++++++++++++++++--------------
 1 file changed, 66 insertions(+), 40 deletions(-)
---
base-commit: 938fbb16aba8f7b88e0fdcf56f315a5bbad41aad
change-id: 20250121-fix-link-training-461495494655

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

