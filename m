From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Subject: [PATCH 0/2] drm/panel: st7703: add AYANEO Pocket DS lower panel
Date: Thu, 23 Jul 2026 18:26:27 +0700
Message-Id: <20260723-b4-st7703-pocketds-lower-v1-0-e3db246589f4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw7CIBBG4VdpZu0kSFFSX8W4EPjVUVMaBi9J0
 3cXdfktzplJUQRKu26mgqeo5LFhveooXo7jGSypmayxW+Ntz8GxVu9Nz1OON9SkfM8vFLYpOPi
 NG2IYqOVTwUnev/X+8Lc+whWxfn+0LB+oEoAzfAAAAA==
X-Change-ID: 20260723-b4-st7703-pocketds-lower-2db4e7549cb9
To: =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Purism Kernel Team <kernel@puri.sm>, Ondrej Jirman <megi@xff.cz>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784805987; l=1180;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=0YihQE3yREOQU/G6DN7iPIXNkMJ2/jzY9GD/PjwLqj4=;
 b=cQWbm4igXYqt20625hB3hQDnDAefEE+ACUtQUF4iJQQd2chCAI9Nmlg1a/CsVD0Irx5Y6rTFy
 DvL11Q8ZdZwCQGuQaTejd91EdssAya14OiqrZ4ga49iMhkkEGOGNIJp
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AYANEO Pocket DS is a dual-screen Qualcomm QCS8550 handheld. Its
lower (secondary) 5.0" 1024x768 4:3 IPS panel is driven by a Sitronix
ST7703 DDIC: every opcode in the vendor init sequence maps 1:1 to the
ST7703_CMD_* command set (SETEXTC 0xB9 with the canonical F1 12 key,
and SETMIPI/SETRGBIF/SETPOWER/SETGIP payloads near-identical to the
already-supported Powkiddy RGB10MAX3), so add it to the existing
sitronix-st7703 driver and its binding rather than a standalone driver.

Tested on a Pocket DS: the panel initialises at 768x1024@60 and both
screens are active.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
Alexandre Hamamdjian (2):
      dt-bindings: display: Add AYANEO Pocket DS lower panel
      drm/panel: st7703: Add AYANEO Pocket DS Lower Panel Support

 .../display/panel/rocktech,jh057n00900.yaml        |  2 +
 drivers/gpu/drm/panel/panel-sitronix-st7703.c      | 96 ++++++++++++++++++++++
 2 files changed, 98 insertions(+)
---
base-commit: e98d21c170b01ddef366f023bbfcf6b31509fa83
change-id: 20260723-b4-st7703-pocketds-lower-2db4e7549cb9

Best regards,
--  
Alexandre Hamamdjian <azkali.limited@gmail.com>

