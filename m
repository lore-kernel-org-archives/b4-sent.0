From: Hermes Wu <Hermes.wu@ite.com.tw>
Subject: [PATCH v7 00/10] drm/bridge: it6505: fix HDCP CTS fail items and
 add MCCS support
Date: Mon, 04 Nov 2024 14:43:30 +0800
Message-Id: <20241104-v7-upstream-v7-0-8b71fd0f1d2d@ite.com.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABJtKGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyzHUUlJIzE
 vPSU3UzU4B8JSMDIxNDQwND3TJz3dKC4pKi1MRcXXPT1MQUozSjNFMzcyWgjoKi1LTMCrBp0bG
 1tQBAzplEXQAAAA==
X-Change-ID: 20241101-v7-upstream-75ead2f2f567
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Hermes Wu <hermes.wu@ite.com.tw>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Pin-yen Lin <treapking@chromium.org>, 
 Kenneth Hung <Kenneth.Hung@ite.com.tw>, Pet Weng <Pet.Weng@ite.com.tw>, 
 Hermes Wu <Hermes.wu@ite.com.tw>, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730702658; l=2910;
 i=Hermes.wu@ite.com.tw; s=20241101; h=from:subject:message-id;
 bh=N2BEphD6E+ts757yq9dfmmqSySIs2TwDaeNZtjT8DQ8=;
 b=SnEN66Llgw53Ax04tEB9EPogFfgJEnebxA2xp/6yJ0r/3ojcYg2jVR1CrBzaKZ/7O0Gzl+QKt
 IDXftIsWc6pCifgJ3F51AP/xEG0oehgeu4c1MWR8K3g1EszvJUWRpfD
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=FOYYbsP2Nlw6mjB3rLFYSLmAiENzj4AWQly5XTcDuMM=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241101 with auth_id=268
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are lots of failure items while running HDCP CTS using UNIGRAF DPR-100.
In Order to fix those failures, HDCP flow needs to be changed.

The DisplayPort AUX protocol supports I2C transport.
In Order to support MCCS via the aux channel, the aux-i2c operation is added.

v6->v7
	-[3/10] add header <linux/bitfield.h> included

	links:
	https://lore.kernel.org/all/20241016-upstream-v6-v6-0-4d93a0c46de1@ite.com.tw/

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

To: Andrzej Hajda <andrzej.hajda@intel.com>
To: Neil Armstrong <neil.armstrong@linaro.org>
To: Robert Foss <rfoss@kernel.org>
To: Laurent Pinchart <Laurent.pinchart@ideasonboard.com>
To: Jonas Karlman <jonas@kwiboo.se>
To: Jernej Skrabec <jernej.skrabec@gmail.com>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>
To: Maxime Ripard <mripard@kernel.org>
To: Thomas Zimmermann <tzimmermann@suse.de>
To: David Airlie <airlied@gmail.com>
To: Simona Vetter <simona@ffwll.ch>
To: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
To: Hermes Wu <hermes.wu@ite.com.tw>
Cc: dri-devel@lists.freedesktop.org
Cc: linux-kernel@vger.kernel.org
Cc: Pin-yen Lin <treapking@chromium.org>
Cc: Kenneth Hung <Kenneth.Hung@ite.com.tw>
Cc: Pet Weng <Pet.Weng@ite.com.tw> 

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

 drivers/gpu/drm/bridge/ite-it6505.c | 335 ++++++++++++++++++++++++++++++------
 1 file changed, 278 insertions(+), 57 deletions(-)
---
base-commit: 4d1c251e8889b4629789425fe85adfc6d39666ac
change-id: 20241101-v7-upstream-75ead2f2f567

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

