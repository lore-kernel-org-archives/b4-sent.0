From: Richard Leitner <richard.leitner@linux.dev>
Subject: [PATCH 0/3] Fix analogue gain maximum for ov9282
Date: Tue, 25 Feb 2025 14:08:39 +0100
Message-Id: <20250225-b4-ov9282-gain-v1-0-a24af2820dde@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANjAvWcC/x3MTQqAIBBA4avIrBvIIaG6SrTwZ6zZWChIIN09a
 fkt3mtQOAsXWFWDzFWKXKlDDwr8adPBKKEbaCQzEhl0E151oZnwsJKQo/bBOmtcDNCjO3OU5x9
 u+/t+x6CGd2AAAAA=
X-Change-ID: 20250225-b4-ov9282-gain-ef1cdaba5bfd
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740488957; l=1042;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=G7awnzToNUy7mW4PV6EH6k9+Z2pQLMHAQTl2CVo5Lvg=;
 b=5p2rAjjPKVLFr0+2xXN3lP9htymOr7PjqvnUo/2PMystoPS7YDi/E8HdlJQjbENmaIXwF3dnv
 +GMqHGrpdvzArP69tqyfa30E+hfby/vN2UsJBSG5U7KxncBk+pySX0R
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes/increases the analogue gain maximum value of the
ov9282 sensor driver to the limits specified in the datasheet.

It furthermore introduces a new register definition (including its
values) and uses available defined registers instead of addresses where
possible.

This is basically a first improvement/cleanup series for the ov9282
driver with likely more to follow.

All register addresses/values are based on the OV9281 datasheet v1.01
(09.18.2015).

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
Richard Leitner (3):
      media: i2c: ov9282: use register definitions
      media: i2c: ov9282: add AEC Manual register definition
      media: i2c: ov9282: fix analogue gain maximum

 drivers/media/i2c/ov9282.c | 40 ++++++++++++++++++++++++++--------------
 1 file changed, 26 insertions(+), 14 deletions(-)
---
base-commit: d082ecbc71e9e0bf49883ee4afd435a77a5101b6
change-id: 20250225-b4-ov9282-gain-ef1cdaba5bfd

Best regards,
-- 
Richard Leitner <richard.leitner@linux.dev>

