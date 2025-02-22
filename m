From: Sven Peter <sven@svenpeter.dev>
Subject: [PATCH 0/4] Miscellaneous Apple RTKit fixes
Date: Sat, 22 Feb 2025 16:56:45 +0000
Message-Id: <20250222-apple-soc-misc-v1-0-1a3af494a48a@svenpeter.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM0BumcC/x3MQQqAIBBA0avErBvQISG6SrQInWqgVByIILx70
 vIt/n9BuQgrTN0LhW9RSbHB9h34Y407o4RmIEPOEBlccz4ZNXm8RD06x97SYMdhC9CiXHiT5x/
 OS60f+7ccWmAAAAA=
To: Alyssa Rosenzweig <alyssa@rosenzweig.io>, Janne Grunau <j@jannau.net>, 
 Sven Peter <sven@svenpeter.dev>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=899; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=Y+9vtj0/GJijf+70Pc6ic4DpWvcYid81kYksrctrbME=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/ouxpcfyrJiu7Wnyave+7iM7/iEZ3IVNsnmrcdmbraIm
 Kh3t2p5RykLgxgHg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAiWxYw/Hf+VXIqZPJS+9te
 Dvc8YoX2Vf2/ksZcw2yqn/OtJSpRTIyR4Z5v25H5Ul1H13ZYzfKcnHMpW/7otnOtcaJTlGos0+4
 mcgEA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series contains four unrelated minor fixes to our RTKit driver.
These are mainly required for drivers which aren't upstream yet but
have been part of our downstream tree for quite a while now.

Best,

Sven

Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
Hector Martin (1):
      soc: apple: rtkit: Implement OSLog buffers properly

Janne Grunau (3):
      soc: apple: rtkit: Add APPLE_RTKIT_PWR_STATE_INIT
      soc: apple: rtkit: Use high prio work queue
      soc: apple: rtkit: Cut syslog messages after the first '\0'

 drivers/soc/apple/rtkit-internal.h |  1 +
 drivers/soc/apple/rtkit.c          | 62 +++++++++++++++++++++++---------------
 2 files changed, 38 insertions(+), 25 deletions(-)
---
base-commit: 00834971f0d9e38beae37e92055b1432782827d0
change-id: 20250220-apple-soc-misc-55ec124184fd

Best regards,
-- 
Sven Peter <sven@svenpeter.dev>

