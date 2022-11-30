Subject: [PATCH v2 0/6] drm/gud: Use the shadow plane helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAHiuh2MC/32NQQrCMBBFr1KydqRJFFtX3kNcTDtjEygTybQVKb
 m7wQO4+rwP7//dKOfIaq7NbjJvUWOSCu7QmDGgTAyRKhvXOmetczCtBBqQ0hteMwoDsr9gf6YTdW
 SqNqAyDBllDFWUdZ5rGaIuKX9+N5utcf+zuFlooSf2+ETvO8+3JScR1mPKk3mUUr5o3D6rtwAAAA ==
From: Noralf Trønnes <noralf@tronnes.org>
Date: Wed, 30 Nov 2022 20:26:48 +0100
Message-Id: <20221122-gud-shadow-plane-v2-0-435037990a83@tronnes.org>
To: Thomas Zimmermann <tzimmermann@suse.de>, Javier Martinez Canillas <javierm@redhat.com>,
 dri-devel@lists.freedesktop.org, Maxime Ripard <mripard@kernel.org>, stable@vger.kernel.org,
 Noralf Trønnes <noralf@tronnes.org>
X-Mailer: b4 0.11.0-dev-cc6f6
X-Developer-Signature: v=1; a=ed25519-sha256; t=1669836415; l=1893;
 i=noralf@tronnes.org; s=20221122; h=from:subject:message-id;
 bh=XGONUzrpJG3cabIJ/iio3JwrsnBPyUBQgL4MPUuLEjM=;
 b=FRbiv6TSsd500P09sjCmwqMbHCOsKrgz9/z4n4GqaYQE3AMTyQrRKQMDVtu9yrR5ui5TM31Y3xmo
 +ZVxG5AAA/1CnNUYmEeGBFbo8SZdJ3q2OxVAv0vG+j5Y2Ezshxh/
X-Developer-Key: i=noralf@tronnes.org; a=ed25519;
 pk=0o9is4iddvvlrY3yON5SVtAbgPnVs0LfQsjfqR2Hvz8=
X-Endpoint-Received: by B4 Submission Endpoint for noralf@tronnes.org/20221122 with auth_id=8
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Hi,

I have started to look at igt for testing and want to use CRC tests. To
implement support for this I need to move away from the simple kms
helper.

When looking around for examples I came across Thomas' nice shadow
helper and thought, yes this is perfect for drm/gud. So I'll switch to
that before I move away from the simple kms helper.

The async framebuffer flushing code path now uses a shadow buffer and
doesn't touch the framebuffer when it shouldn't. I have also taken the
opportunity to inline the synchronous flush code path and make this the
default flushing stategy.

Noralf.

Cc: Maxime Ripard <mripard@kernel.org>
Cc: Thomas Zimmermann <tzimmermann@suse.de>
Cc: dri-devel@lists.freedesktop.org
Signed-off-by: Noralf Trønnes <noralf@tronnes.org>

---
Changes in v2:
- Drop patch (Thomas):
  drm/gem: shadow_fb_access: Prepare imported buffers for CPU access
- Use src as variable name for iosys_map (Thomas)
- Prepare imported buffer for CPU access in the driver (Thomas)
- New patch: make sync flushing the default (Thomas)
- Link to v1: https://lore.kernel.org/r/20221122-gud-shadow-plane-v1-0-9de3afa3383e@tronnes.org

---
Noralf Trønnes (6):
      drm/gud: Fix UBSAN warning
      drm/gud: Don't retry a failed framebuffer flush
      drm/gud: Split up gud_flush_work()
      drm/gud: Prepare buffer for CPU access in gud_flush_work()
      drm/gud: Use the shadow plane helper
      drm/gud: Enable synchronous flushing by default

 drivers/gpu/drm/gud/gud_drv.c      |   1 +
 drivers/gpu/drm/gud/gud_internal.h |   1 +
 drivers/gpu/drm/gud/gud_pipe.c     | 222 ++++++++++++++++++-------------------
 3 files changed, 112 insertions(+), 112 deletions(-)
---
base-commit: 7257702951305b1f0259c3468c39fc59d1ad4d8b
change-id: 20221122-gud-shadow-plane-ae37a95d4d8d

Best regards,
-- 
Noralf Trønnes <noralf@tronnes.org>
