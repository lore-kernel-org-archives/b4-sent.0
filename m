From: Hermes Wu <Hermes.wu@ite.com.tw>
Subject: [PATCH v6 00/10] drm/bridge: it6505: fix HDCP CTS fail items and
 add MCCS support
Date: Wed, 16 Oct 2024 15:54:12 +0800
Message-Id: <20241016-upstream-v6-v6-0-4d93a0c46de1@ite.com.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACRxD2cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyzHQUlJIzE
 vPSU3UzU4B8JSMDIxNDA0NT3dKC4pKi1MRc3TIzXcs0kySgWFpqcpq5ElBHQVFqWmYF2LTo2Np
 aAF1IP8FdAAAA
X-Change-ID: 20241015-upstream-v6-9f4b015fecf7
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Pin-yen Lin <treapking@chromium.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Kenneth Hung <Kenneth.hung@ite.com.tw>, Pet Weng <Pet.Weng@ite.com.tw>, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729065263; l=2652;
 i=Hermes.wu@ite.com.tw; s=20241016; h=from:subject:message-id;
 bh=0mS2QsnFjEWDx86A7WNGJteaAIrzem/xgIboic3tva4=;
 b=gzqV8xnlDztsLFNNGm32Jggeb0RcJidEYBbwujDBbugy7ttmgHRkDYSobIzp2vyKZf7WPLgFj
 jwpa2e2PbmuDqXO/WBhy/24hhQjkjPfb26fnlTGKsgnvtXvy77nigUl
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=kV18uQEXox+1WccdQceCbMlJKN+BBNUk3N8VsoULcQ0=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241016 with auth_id=250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a v6 patch-set.

There are lots of failure items while running HDCP CTS using UNIGRAF DPR-100.
In Order to fix those failures, HDCP flow needs to be changed.

The DisplayPort AUX protocol supports I2C transport.
In Order to support MCCS via the aux channel, the aux-i2c operation is added.

v5->v6:
	-keep the commit message wrapped at 72-75 chars.
	-[10/10] fix return variable being used without being initialized

v4->v5:
	-add more messages for changes.
	-[2/10] modified AUX transfer data size judgment.
		change for-loop to do-while.
	-[7/10] change for-loop to do-while.
	-[9/10] change wait timer with timer_after()

	links:
	https://lore.kernel.org/all/20240926074755.22176-4-Hermes.Wu@ite.com.tw/
	https://lore.kernel.org/all/20240926075134.22394-1-Hermes.Wu@ite.com.tw/

v3->v4:
	-split changes  into patches.

v2->v3:
	-split aux read  KSV function to a patch.
	-[1/3] new in v3
	-[2/3] add description of patch

v1->v2:
	- ignored.

Hermes Wu (10):
  drm/bridge: it6505: Change definition of AUX_FIFO_MAX_SIZE
  drm/bridge: it6505: improve AUX operation for edid read
  drm/bridge: it6505: add AUX operation for HDCP KSV list read
  drm/bridge: it6505: Change definition MAX_HDCP_DOWN_STREAM_COUNT
  drm/bridge: it6505: fix HDCP Bstatus check
  drm/bridge: it6505: fix HDCP encryption when R0 ready
  drm/bridge: it6505: fix HDCP CTS KSV list read with UNIGRAF DPR-100.
  drm/bridge: it6505: fix HDCP CTS compare V matching
  drm/bridge: it6505: fix HDCP CTS KSV list wait timer
  drm/bridge: it6505: add I2C functionality on AUX

Change-Id: Iad0c056d72abf2655081357cf40c3b0d3df916b5
Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Hermes Wu (10):
      drm/bridge: it6505: Change definition of AUX_FIFO_MAX_SIZE
      drm/bridge: it6505: improve AUX operation for edid read
      drm/bridge: it6505: add AUX operation for HDCP KSV list read
      drm/bridge: it6505: Change definition MAX_HDCP_DOWN_STREAM_COUNT
      drm/bridge: it6505: fix HDCP Bstatus check
      drm/bridge: it6505: fix HDCP encryption when R0 ready
      drm/bridge: it6505: fix HDCP CTS KSV list read with UNIGRAF DPR-100.
      drm/bridge: it6505: fix HDCP CTS compare V matching
      drm/bridge: it6505: fix HDCP CTS KSV list wait timer
      drm/bridge: it6505: add I2C functionality on AUX

 drivers/gpu/drm/bridge/ite-it6505.c | 334 ++++++++++++++++++++++++++++++------
 1 file changed, 277 insertions(+), 57 deletions(-)
---
base-commit: b8128f7815ff135f0333c1b46dcdf1543c41b860
change-id: 20241015-upstream-v6-9f4b015fecf7

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

