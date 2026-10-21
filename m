From: Hermes Wu <Hermes.wu@ite.com.tw>
Subject: [PATCH 0/5] media: i2c: it6625: fix DV timings handling
Date: Wed, 21 Oct 2026 14:03:24 +0800
Message-Id: <20261021-upstream-it6625-dv-timings-fix-v1-0-5881babdc4c2@ite.com.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKxV2GoC/x2NMQ6AIAwAv2I62wRQGfyKcVCo2kE0FI0J8e8Sx
 7vhLoNQZBLoqwyRbhY+QgFdV+C2KayE7AuDUcZqZTRep6RI046crDUd+hsT7xxWwYUf9As5Zd2
 s5qaFEjkjFf0PhvF9Pz1icrxwAAAA
X-Change-ID: 20261021-upstream-it6625-dv-timings-fix-dfec06cb0b34
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792562607; l=2245;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=6szBEJ3MNX6NVlImTnsjsidGTgcwJHtOC3ALX2KDrvg=;
 b=oBjuweC38apxOJ8YY6nQ+1ouYccnRATufFcidtVKxzk53AGTvYkW8j6XwuIUl89ci8A3Mn+Ma
 5ud9flEFltcC9RlgqOSC36xmoBboWLBNQd5FHu1dlSW427zG2znzTjL
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes five issues in how the IT6625 driver detects, reports
and configures DV timings.

Patch 1 keeps the configured DV timings and the ACTIVE pad format when
the HDMI 5V state changes, instead of clearing them.
Patch 2 makes S_DV_TIMINGS return -EBUSY for a timings change while the
subdev is streaming.
Patch 3 reports the detected horizontal and vertical sync polarities.
Patch 4 fixes the vertical timings of the second field of interlaced
input, so that a 1080i frame totals 1125 lines.
Patch 5 lowers the minimum pixel clock to 25 MHz, so that the 640x480
formats are accepted.

The series is based on media next and applies on its own. It does not
depend on the pending IT6625 reset timing series [1]; the two apply in
either order.

The changes were tested on hardware with HDMI sources, with the patches
applied to the driver on an older kernel. The configured timings were
kept across an HDMI unplug and replug. While the subdev was streaming, a
timings change was refused and identical timings were still accepted;
the change was accepted once streaming had stopped. Negative, positive
and mixed (negative horizontal, positive vertical) sync polarities were
reported correctly. 1080i50, 1080i59.94 and 1080i60 input was reported
with 1125 lines per frame and the expected field rates, and 640x480p60
and 720x576p50 input was detected. No video frames were captured in
these tests.

[1] https://lore.kernel.org/r/20261007-upstream-it6625-reset-delay-v2-0-c5d6b2522bbe@ite.com.tw

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Hermes Wu (5):
      media: i2c: it6625: keep the configured DV timings on 5V changes
      media: i2c: it6625: reject DV timings changes while streaming
      media: i2c: it6625: report the detected sync polarities
      media: i2c: it6625: fix the second-field vertical timings
      media: i2c: it6625: lower the minimum pixel clock to 25 MHz

 drivers/media/i2c/it6625.c | 37 +++++++++++++++++--------------------
 1 file changed, 17 insertions(+), 20 deletions(-)
---
base-commit: d7e7bca7169873b46e857c025c10f3336c1258d8
change-id: 20261021-upstream-it6625-dv-timings-fix-dfec06cb0b34

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

