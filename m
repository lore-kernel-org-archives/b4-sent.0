From: Richard Leitner <richard.leitner@linux.dev>
Subject: [PATCH 0/2] media: v4l2-cci/ov9282: support single-read I2C
 transactions
Date: Tue, 21 Jul 2026 15:25:27 +0200
Message-Id: <20260721-cci-single-v1-0-8485171e1393@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEdzX2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDc0Nz3eTkTN3izLz0nFRdI8ukpCQLS3Nz02QTJaCGgqLUtMwKsGHRsRB
 +cWlSVmpyCcgEpdpaABmCERFuAAAA
X-Change-ID: 20260717-cci-single-29bbb89775c4
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>
Cc: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Hans de Goede <hansg@kernel.org>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784640354; l=1245;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=svfrBm6qwvhos1KNM9Uxz3Q6w2/2dm0H31wva9nLA1w=;
 b=NRtTFiCF1wZG54Y77U3YMwEQO/1B2WKUYTRI06q8AtZ7FWIaYV2jD3bp3LkM5KuZDL13T6WEi
 oRQx9mq0My1AN0tobyFmMLiMFeW/VTApii9J4R2JfNfgKIBbetlci4L
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for configuring transport-specific CCI regmap
behavior for I2C sensors, which is then used in the OV9282 driver to
force single-register read transactions.

The motivation for this change is that some OV9282 camera modules require
single-read I2C transactions to operate correctly. In particular, OV9282
modules from Vision Components return invalid data on multi-byte reads,
while switching the regmap to single-read transactions fixes the problem.

This series does not change the default behavior of existing CCI users.
Only ov9282 opts into single-read transactions.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
Richard Leitner (2):
      media: v4l2-cci: Add support for custom regmap configuration
      media: ov9282: enable single-read I2C transactions

 drivers/media/i2c/ov9282.c         |  7 ++++++-
 drivers/media/v4l2-core/v4l2-cci.c | 23 +++++++++++++++++++----
 include/media/v4l2-cci.h           | 37 ++++++++++++++++++++++++++++++++++++-
 3 files changed, 61 insertions(+), 6 deletions(-)
---
base-commit: 1590cf0329716306e948a8fc29f1d3ee87d3989f
change-id: 20260717-cci-single-29bbb89775c4

Best regards,
--  
Richard Leitner <richard.leitner@linux.dev>

