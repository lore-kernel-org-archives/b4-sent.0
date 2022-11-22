Subject: [PATCH 0/6] drm/gud: Use the shadow plane helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-b4-tracking: H4sIAP43fWMC/w3LQQqEMAwAwK9IzgZsVHT3N6kJtlDi0uB6EP9uj3OYG1xrVodvd0PVf/Z8WEPoO9
 gS266YpRloIAqBCPdT0BPLceGvsCmyjgt/ZplkFWgtsivGyralFu0s5Xle8Sy6k2cAAAA=
From: Noralf Trønnes <noralf@tronnes.org>
Date: Tue, 22 Nov 2022 21:58:38 +0100
Message-Id: <20221122-gud-shadow-plane-v1-0-9de3afa3383e@tronnes.org>
To: Thomas Zimmermann <tzimmermann@suse.de>, stable@vger.kernel.org, Dave Airlie <airlied@redhat.com>,
 dri-devel@lists.freedesktop.org, Hans de Goede <hdegoede@redhat.com>, Noralf Trønnes <noralf@tronnes.org>,
 Maxime Ripard <mripard@kernel.org>, Javier Martinez Canillas <javierm@redhat.com>
X-Mailer: b4 0.10.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1669150743; l=2009;
 i=noralf@tronnes.org; s=20221122; h=from:subject:message-id;
 bh=fCEYnc7B5DuEdhoxMG3nvbfjTrsi43MKH/fHuTVo2Cg=;
 b=S4MQUVlCFozcBiYzqLeEtQxpd6QgwEOFhm01orUEdoenvVcAGTmPyIvQzVqC5n/r47YX34kA1iYi
 NWCxXEdJBiY6TOH8DvU+6fhLDE83ap6xus2F8gokHh05wWhtKFrs
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
opportunity to inline the synchronous flush code path since this will be
the future default when userspace predominently don't run all displays
in the same rendering loop. A shared rendering loop slows down all
displays to run at the speed of the slowest one.

Noralf.

Cc: Maxime Ripard <mripard@kernel.org>
Cc: Thomas Zimmermann <tzimmermann@suse.de>
Cc: dri-devel@lists.freedesktop.org
Signed-off-by: Noralf Trønnes <noralf@tronnes.org>

---
Noralf Trønnes (6):
      drm/gem: shadow_fb_access: Prepare imported buffers for CPU access
      drm/gud: Fix UBSAN warning
      drm/gud: Don't retry a failed framebuffer flush
      drm/gud: Split up gud_flush_work()
      drm/gud: Prepare buffer for CPU access in gud_flush_work()
      drm/gud: Use the shadow plane helper

 drivers/gpu/drm/drm_gem_atomic_helper.c |  13 ++-
 drivers/gpu/drm/gud/gud_drv.c           |   1 +
 drivers/gpu/drm/gud/gud_internal.h      |   1 +
 drivers/gpu/drm/gud/gud_pipe.c          | 198 +++++++++++++++-----------------
 drivers/gpu/drm/solomon/ssd130x.c       |  10 +-
 drivers/gpu/drm/tiny/gm12u320.c         |  10 +-
 drivers/gpu/drm/tiny/ofdrm.c            |  10 +-
 drivers/gpu/drm/tiny/simpledrm.c        |  10 +-
 drivers/gpu/drm/udl/udl_modeset.c       |  11 +-
 9 files changed, 117 insertions(+), 147 deletions(-)
---
base-commit: 7257702951305b1f0259c3468c39fc59d1ad4d8b
change-id: 20221122-gud-shadow-plane-ae37a95d4d8d

Best regards,
-- 
Noralf Trønnes <noralf@tronnes.org>
