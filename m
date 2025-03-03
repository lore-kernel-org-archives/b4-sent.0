From: Richard Leitner <richard.leitner@linux.dev>
Subject: [PATCH 0/3] Add flash/strobe support for ov9282
Date: Mon, 03 Mar 2025 23:58:56 +0100
Message-Id: <20250303-ov9282-flash-strobe-v1-0-0fd57a1564ba@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADA0xmcC/0XMywrDIBCF4VcJs+6AmhoaX6Vk4WVMhKKtplIIe
 fdKQunyP3C+DQrlQAVUt0GmGkpIsQW/dGAXHWfC4FqDYEKynvWY6ihuAv1DlwXLmpMh1HYwjjE
 7OhqgPZ+ZfPgc6n06O9Pr3fD1HP+26g5ZCInm+sNnHSKS59Zpo6XxTlUO075/AURFWfKuAAAA
X-Change-ID: 20250303-ov9282-flash-strobe-ac6bd00c9de6
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741042742; l=1479;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=XbOH1fC1/MqVpPPDTqHt/Rol16iCZE4/cwigRDqrXss=;
 b=tPsXSgcYuvu4Sx6vaJjj2l/fOFaX2Ujdxbk35Mtejtr68dD/w/VDfKMwsAOA2P9f9fUKvMzn9
 9hkSLXJOWU8DAZFP8SNmuPzXo4EUbzMSV+95eKEnfqIia+VIrINvDTk
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds basic flash/strobe support for ov9282 sensors using
their "hardware strobe output".

Apart from en-/disabling the flash/strobe output, setting a timeout
(duration of activated strobe per frame) is implemented. The calculation
of this timeout is only interpolated from various measurements, as no
documentation was found.

Further flash/strobe-related controls as well as a migration to v4l2-cci
helpers will likely be implemented in future series.

All register addresses/values are based on the OV9281 datasheet v1.53
(january 2019). This series was tested using an ov9281 VisionComponents
camera module.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
Richard Leitner (3):
      media: i2c: ov9282: add output enable register definitions
      media: i2c: ov9282: add led_mode v4l2 control
      media: i2c: ov9282: add strobe_timeout v4l2 control

 drivers/media/i2c/ov9282.c | 89 ++++++++++++++++++++++++++++++++++++++++++++--
 1 file changed, 86 insertions(+), 3 deletions(-)
---
base-commit: f41427b3bdee7d9845b13a80c0d03882212f4b20
change-id: 20250303-ov9282-flash-strobe-ac6bd00c9de6
prerequisite-change-id: 20250225-b4-ov9282-gain-ef1cdaba5bfd:v1
prerequisite-patch-id: 86f2582378ff7095ab65ce4bb25a143eb639e840
prerequisite-patch-id: b06eb6ec697aaf0b3155b4b2370f171d0d304ae2
prerequisite-patch-id: b123047d71bfb9b93f743bbdd6893d5a98495801

Best regards,
-- 
Richard Leitner <richard.leitner@linux.dev>

