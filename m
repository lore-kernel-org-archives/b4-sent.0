From: Jim Cromie <jim.cromie@gmail.com>
Subject: [PATCH 0/2] drm: 2 quick fixes
Date: Sat, 26 Sep 2026 16:33:31 -0600
Message-Id: <20260926-rd-mostly-v1-0-28b7d714ed2c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSyNT3aIU3dz84pKcSl2zRKO0ZIPkFLO0FDMloPqCotS0zAqwWdGxtbU
 AYiYBmlsAAAA=
X-Change-ID: 20260925-rd-mostly-6a2fc0cd6fd6
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790462033; l=709;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=fxP3TXfyWT+sUcAC6cZncp/t39Htd3ktm9W/nEZb5KI=;
 b=xI/zic2+jXuvDHLxNq3q1EcjouHL9BjNcN17ZvWX1RuNF1A2eXefwQR4deGxsM57UhhK+Bzhh
 hVVzbpo9zd2AZ6JVNT66RtiRSsJNKPNwsyoMFAzwlBAfvfgC0WXKzmE
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

1. make __drm_debug __read_mostly
   it is rarely written, and read at up to 80khz
   
2. fix CFLAGS -> ccflags mis-spelling
   this fails to add -DDYNAMIC_DEBUG_MODULE to ccflags
   currently masked by DRM_USE_DYNAMIC_DEBUG=n

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
Jim Cromie (2):
      drm/print: Mark __drm_debug as __read_mostly
      drm: Fix incorrect ccflags-y spelling inside Makefile

 drivers/gpu/drm/Makefile    | 3 ++-
 drivers/gpu/drm/drm_print.c | 2 +-
 2 files changed, 3 insertions(+), 2 deletions(-)
---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260925-rd-mostly-6a2fc0cd6fd6

Best regards,
-- 
Jim Cromie <jim.cromie@gmail.com>

