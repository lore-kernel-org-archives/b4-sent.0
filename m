From: Alberto Ruiz <aruiz@redhat.com>
Subject: [PATCH 0/4] drm/solomon: batch command sequences for
 SSD130x/132x/133x init
Date: Fri, 12 Jun 2026 18:17:15 +0100
Message-Id: <20260612-ssd-batchcmd-v1-0-c61e5f7c24bc@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDM0Mj3eLiFN2kxJLkjOTcFF1j0zTzpESLZMNUiyQloJaCotS0zAqwcdG
 xEH5xaVJWanIJyAyl2loAltat13AAAAA=
X-Change-ID: 20260612-ssd-batchcmd-35f7ba8c1e8b
To: Javier Martinez Canillas <javierm@redhat.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Alberto Ruiz <aruiz@redhat.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781284654; l=1263;
 i=aruiz@redhat.com; s=20260612; h=from:subject:message-id;
 bh=ASg6th/Ywmh/h86ebbxcUhuLfc87yXzCgfN5EC0OsO8=;
 b=f72LNDqZsghUxEI3JFC8MhurK58aFX+wDsNTgvTFeOgVPaJv/5lNTa6gbaLgCz/o31XMezW2L
 gNk9qIQ4jeQBsNOPDM3DSURKL0b5zycnjcGNdMdH6b7DuOrfp8qJ1e/
X-Developer-Key: i=aruiz@redhat.com; a=ed25519;
 pk=d1doFQwve1B/jU9nG5oPl1W5d+t+iFrjkkwk/hD97Ow=
X-Endpoint-Received: by B4 Relay for aruiz@redhat.com/20260612 with auth_id=818
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ssd130x_init(), ssd132x_init(), and ssd133x_init() functions each
issue long chains of individual ssd130x_write_cmd() calls, each
followed by its own error check.  This is verbose and makes the init
sequences harder to read and maintain.

This series introduces ssd130x_run_cmd_seq(), which interprets a flat
byte array of length-prefixed command entries terminated by a zero
byte, and converts the three init functions to use it.  The result is
a net reduction of ~110 lines, with the hardware programming sequences
now expressed as compact, declarative tables rather than imperative
call-and-check chains.

Signed-off-by: Alberto Ruiz <aruiz@redhat.com>
---
Alberto Ruiz (4):
      drm/solomon: add ssd130x_run_cmd_seq() for batch command execution
      drm/solomon: use ssd130x_run_cmd_seq() in ssd130x_init()
      drm/solomon: use ssd130x_run_cmd_seq() in ssd132x_init()
      drm/solomon: use ssd130x_run_cmd_seq() in ssd133x_init()

 drivers/gpu/drm/solomon/ssd130x.c | 367 +++++++++++++-------------------------
 1 file changed, 128 insertions(+), 239 deletions(-)
---
base-commit: 2b414a95b8f7307d42173ba9e580d6d3e2bcbfce
change-id: 20260612-ssd-batchcmd-35f7ba8c1e8b

Best regards,
--  
Alberto Ruiz <aruiz@redhat.com>

