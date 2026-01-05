From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Subject: [PATCH 0/5] drm/panel: mantix-mlaf057we51: Power sequence
 improvements
Date: Mon, 05 Jan 2026 21:24:39 +0100
Message-Id: <20260105-mantix-halo-fixes-v1-0-1ebc9b195a34@puri.sm>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAceXGkC/x3M0QrCMAyF4VcZuTbYFuzAVxEv0i3awJZJM2Uw9
 u5GLz8O/9nBuAkbXLsdGn/EZFFHPHUwVNIno4xuSCHlEMMFZ9JVNqw0LfiQjQ37sc8hRc6pEHj
 3avwfPLvd3YWMsTTSof6eJtG3nWeylRscxxcSnyQ9ggAAAA==
X-Change-ID: 20260105-mantix-halo-fixes-7d76021e62ba
To: =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Purism Kernel Team <kernel@puri.sm>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1495;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=XY0pQefpCFKLKtWJ2mFa1wekuuL/rvFmS2uFIx/iDN4=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpXB4e6/Fa8ZmMg8ypQoB5dd1SNwK71wbRER7Vv
 qvmZjWLiXCJAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVweHgAKCRDo8jXPO9vD
 /1eOEACGsoW5vjNV0FgwDdW70thj6I4KwqU+nBqq8mlKaPerKO8VoG/G3GHs0dyd/hti1Ng43hI
 BoOUWJKm0IKUXkTgY5S/MLY/z+1lfF4Eo9Ye7XwAiAqGBTY5hlXiOwbtaIJT2xc6K6Jz4z/wTrG
 ZOTnenPwjKLJp5oYY/tu6CinWjDxUXtu/AjYNW1Qes3LJ24hNz+okncBOWS8DpEZ+iAbLm2XJfj
 6eiC7o/DVcBR/3POWsxGfs3lVoywT5x9cl/VC40uF13mIp7nuAKB72JaW97xQfjNyyfXshAOrqb
 uo+rGypcbPGOZVpW4HPN33sDR7atyHcRk04lnMLAgKXmJ3Tx2RGLeBhYSQectKCvwdwWz+JTMnU
 qav2IJQOsoE5sYr5/UtlFdlsaGPB7vPtN01NNQcDYDhzLW5j3EOKByv4132wX9Pw87FcqcNXD0e
 vv2VvNlhQq5GcS70V1NG7V9jCxBjtONqaz0RcRQn8BtPfxRYVWE5mldiqoOFJeBssYZYkEYtmUj
 Vy+vG4bW8brC92rx5UcHl19cnOv8YwJcW0byhmF6Z8xRZtEL70U+uvv0dHV7k9O8stljLigi0o6
 zpATR1/nwMfJbdnkpYDC0T+cINZJi9BBTpztPCgJeDkEr7EqU1ZF4DjPVmTR5JB72wT4YgdPzyo
 iDSAZ/40nxHWOQQ==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These are the patches that fix the issues with low contrast, "halo",
temporary burn-in and occasional black screen on the Librem 5 phones,
which use Mantix MLAF057WE51-X and Yashi Changhua YS57PSS36BH5GQ panels.

They're mostly about improving the power sequences to match the ones
described in FT8006P datasheet, so the driver does not end up disturbing
the internal initialization process performed by the controller.
Aside of that, using LP mode has been found to improve the reliability of
sending DSI commands to the panel to the point where long chains
of commands can be sent without erroring out - something that, at least
on i.MX8MQ, wasn't possible without LPM.

These have been used in Purism's downstream tree for months and tested
across the variety of hardware batches.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
Sebastian Krzyszkowiak (5):
      drm/panel: mantix: Enable DSI LPM
      drm/panel: mantix: Improve power on sequence timings
      drm/panel: mantix: Improve power off sequence
      drm/panel: mantix: Drop bank 9 initialization
      drm/panel: mantix: Don't turn on MIPI peripheral

 drivers/gpu/drm/panel/panel-mantix-mlaf057we51.c | 35 ++++++++++++------------
 1 file changed, 18 insertions(+), 17 deletions(-)
---
base-commit: 9ace4753a5202b02191d54e9fdf7f9e3d02b85eb
change-id: 20260105-mantix-halo-fixes-7d76021e62ba

Best regards,
-- 
Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>

