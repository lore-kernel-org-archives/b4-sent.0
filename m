From: Sven Peter <sven@svenpeter.dev>
Subject: [PATCH v2 0/4] Miscellaneous Apple RTKit fixes
Date: Wed, 26 Feb 2025 19:00:02 +0000
Message-Id: <20250226-apple-soc-misc-v2-0-c3ec37f9021b@svenpeter.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALJkv2cC/13MQQrCMBCF4auUWTuSjClUV95Dugjp1A5oGzIlK
 CV3NxbcuPwfvG8D5SSscGk2SJxFZZlr0KGBMPn5zihDbSBDrSEy6GN8MOoS8CkasG05WHK2c+M
 A9RQTj/LawVtfexJdl/Te/Wy/64+ifypbNGj9yY/u7Lzr/FUzz5FXTseBM/SllA9SysEtsAAAA
 A==
To: Alyssa Rosenzweig <alyssa@rosenzweig.io>, Janne Grunau <j@jannau.net>, 
 Sven Peter <sven@svenpeter.dev>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1200; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=wRpTgVNyj3uFgb5wwu79FFUhOzFVyOzLcCfMgdRPLUM=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/r+lF0rtmXPCKrcHZwkdkdrq9kvHjMe3mcezRsknjxdt
 ERMTVyqo5SFQYyDQVZMkWX7fnvTJw/fCC7ddOk9zBxWJpAhDFycAjARrQaG/zHO/8T+hOSnBcwU
 Yw9u38vbtfb/l+/zvW9eiuPY+cD2GhfDf3fjQ68NFCcdn3JxEtuRx7IqsixdG2dIrJ8xgfHQ1oV
 cAvwA
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

---
Changes in v2:
- Changed commit message for APPLE_RTKIT_PWR_STATE_INIT to make it clear
  this is a behavioral change
- Added a comment for the new oslog logic that the asymetric shifts are
  indeed correct
- Collected r-b tags
- Link to v1: https://lore.kernel.org/r/20250222-apple-soc-misc-v1-0-1a3af494a48a@svenpeter.dev

---
Hector Martin (1):
      soc: apple: rtkit: Implement OSLog buffers properly

Janne Grunau (3):
      soc: apple: rtkit: Add and use PWR_STATE_INIT instead of _ON
      soc: apple: rtkit: Use high prio work queue
      soc: apple: rtkit: Cut syslog messages after the first '\0'

 drivers/soc/apple/rtkit-internal.h |  1 +
 drivers/soc/apple/rtkit.c          | 63 +++++++++++++++++++++++---------------
 2 files changed, 39 insertions(+), 25 deletions(-)
---
base-commit: 00834971f0d9e38beae37e92055b1432782827d0
change-id: 20250220-apple-soc-misc-55ec124184fd

Best regards,
-- 
Sven Peter <sven@svenpeter.dev>

