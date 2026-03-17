From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/2] drm/panel: Add panel driver for ChipWealth CH13726A
 based panels
Date: Tue, 17 Mar 2026 00:23:06 -0500
Message-Id: <20260317-ch13726a-v2-0-28aa46bcd6d0@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/02PzU7DMBCEXyXyGaNdp/5JTrwH6mFtbxpLJAE7j
 VpVeXfcFgTHGe3OfHMThXPiIvrmJjJvqaRlrkK9NCKMNJ9Ypli1UKAMKAUyjNhaZUjqLhhjXdR
 tdKKef2Ye0uUR9X586sxf55q4Pk3hqbAMyzSltW86HfQBYxw8ONQETO5gLQ3WOu+x9R6sBtuR+
 E9SwX456DrLjee4ZEmoWzQuqM6rfkNxbx9TWZd8feyq1r3+51X9TdhQgmQNGK1jBE1vp4nSx2t
 lFMd9378Blcf2nR4BAAA=
X-Change-ID: 20260220-ch13726a-59c6678d53d8
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Teguh Sobirin <teguh@sobir.in>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773725020; l=1279;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=sHBOXa5iAdCKVMBMgSvMM6uqXWupWn60SVKYB9JnKgY=;
 b=DzjhYFE5zY5In+vRpMU9r4oJg+dntBbzxTebe3W3BE1mGvjExZ86o6IckAdH0FYKHDmZJJFOH
 JMwVyjJLiegAxS3PbkmSiAtO+k2VsdSek+G8WHb7/YX3qxDIiQnF0Aw
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This driver is based on the one by Teguh Sobirin [0], cut down to only
support the AYN Thor bottom panel.

[0] https://github.com/AYNTechnologies/linux/commit/d0ff75b09e66023c5f88992706dee4601aa7a437

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Add Neil Armstrong to binding maintainer list
- Add 120hz mode, which required a minor restructure of the driver
- Link to v1: https://lore.kernel.org/r/20260222-ch13726a-v1-0-e501d78e105a@gmail.com

---
Aaron Kling (1):
      dt-bindings: display: panel: Add ChipWealth CH13726A AMOLED driver bindings

Teguh Sobirin (1):
      drm/panel: Add panel driver for ChipWealth CH13726A based panels

 .../display/panel/chipwealth,ch13726a.yaml         |  66 ++++
 drivers/gpu/drm/panel/Kconfig                      |  11 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-chipwealth-ch13726a.c  | 339 +++++++++++++++++++++
 4 files changed, 417 insertions(+)
---
base-commit: 95c541ddfb0815a0ea8477af778bb13bb075079a
change-id: 20260220-ch13726a-59c6678d53d8
prerequisite-change-id: 20260220-ayn-vendor-a153168c29b2:v1
prerequisite-patch-id: 042cab8f04748207ba5395dd0f23c445955aaa2b

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

