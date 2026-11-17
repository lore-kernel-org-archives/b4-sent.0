From: Sidharth Saha <ssaha2000@gmail.com>
Subject: [PATCH 0/5] drm/vkms: Add KUnit tests for packed RGB format
 conversions
Date: Mon, 16 Nov 2026 18:21:31 -0700
Message-Id: <20261116-rgb565-test-v1-0-27f49c1aa694@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBCF4avIrJuQGIxGSuk9iouoEw1UbTOxF
 MS7N9Xl/+B9GxAGjwR1tkHAjye/zCnkJYNutPOAzPepIRe5llJqFoa20AWLSJGpvnKmU51pFUJ
 6vAI6/z20R3N2wPea0HiOMCGRPdA6u/5NYfJKiEIJyZUuTVkyySYbR1yJW/uc0Pf27mfHVxcG4
 m24QbPvP3gk8zC3AAAA
X-Change-ID: 20261116-rgb565-test-3d8f9c3c9b3e
To: Louis Chauvet <louis.chauvet@bootlin.com>, 
 Haneen Mohammed <hamohammed.sa@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Melissa Wen <melissa.srw@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Sidharth Saha <40047656+Sidharth-Saha@users.noreply.github.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794878495; l=2121;
 i=ssaha2000@gmail.com; s=20261116; h=from:subject:message-id;
 bh=4R4U0RGMTz3P5bOW6oCa+DKZ3/UIMcCejyTU2U2foww=;
 b=LO61FrvPo0vRuzmFSmVKabjZJxKkkU+DVF8WiR5UIvSO1/KF8brdQcBDPG4My8/LGs9VNR5Uw
 w1x1GBdIaHPDkFdlmKJH/vGtwIZNWfA+Yz/JTFc69uuhJ7Q7xd8FBuG
X-Developer-Key: i=ssaha2000@gmail.com; a=ed25519;
 pk=wMWW9xOklVZkO7Yh4yIXvhVVRs/3ROsqgjTt8XBGybI=
X-Endpoint-Received: by B4 Relay for ssaha2000@gmail.com/20261116 with auth_id=1541
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds KUnit tests for the pixel format conversions touched
by Matheus's series "drm/vkms: support more formats and fix RGB565
regression" [1], which it depends on.

The RGB565 writeback rounding fix in [1] restores a fix that was lost
once before in a refactor. These tests are meant to keep it, and the new
RGB332, BGR233 and BGR565 conversions, from regressing.

Each test is table-driven, with expected values computed by hand. With
[1] applied, all cases pass. Without it, the tests for the new formats
don't build, the RGB565 writeback rounding cases fail, and the
RGB565/BGR565 read cases pass unchanged.

Matheus offered to include these in a v2 of [1] if one is needed;
otherwise they can be applied on top of it.

[1] https://lore.kernel.org/dri-devel/20260928005301.367977-1-matheus.aalmeida@inf.ufrgs.br/

Signed-off-by: Sidharth Saha <40047656+Sidharth-Saha@users.noreply.github.com>
---
Sidharth Saha (5):
      drm/vkms: Add KUnit test for RGB565 writeback conversion
      drm/vkms: Add KUnit test for BGR565 writeback conversion
      drm/vkms: Add KUnit tests for RGB332 and BGR233 read conversion
      drm/vkms: Add KUnit tests for RGB332 and BGR233 writeback conversion
      drm/vkms: Add KUnit tests for RGB565 and BGR565 read conversion

 drivers/gpu/drm/vkms/tests/vkms_format_test.c | 202 ++++++++++++++++++++++++++
 drivers/gpu/drm/vkms/vkms_formats.c           |  24 ++-
 drivers/gpu/drm/vkms/vkms_formats.h           |  10 ++
 3 files changed, 228 insertions(+), 8 deletions(-)
---
base-commit: 66c571876c4634dc3258a75a6d49bd7e88ffcb35
change-id: 20261116-rgb565-test-3d8f9c3c9b3e
prerequisite-message-id: <20260928005301.367977-1-matheus.aalmeida@inf.ufrgs.br>
prerequisite-patch-id: 62056d93696db239d59a0ca486a7fba3f5ee204d
prerequisite-patch-id: a909d90a401095b0ad014f44f08b8c76563262b8
prerequisite-patch-id: 713b5a5532b2ec31d360132496e6f9980b91a16a
prerequisite-patch-id: fa0fda9d178c4b5a65d984a672f47ec90b86ea2a
prerequisite-patch-id: 8e173c420969c0943d31eec819288d9df4d39b5f

Best regards,
--  
Sidharth Saha <ssaha2000@gmail.com>

