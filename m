From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH 0/2] hwmon: ltc4282: small fixes
Date: Wed, 11 Jun 2025 17:26:11 +0100
Message-Id: <20250611-fix-ltc4282-repetead-write-v1-0-fe46edd08cf1@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACOuSWgC/x3MQQrCMBBG4auUWTswnaoEr1JchPSPDkgtk9AWS
 u9ucPnB4x1U4IZCj+4gx2rFvnNDf+koveP8AtvUTCp6k7soZ9v5U9NVg7JjQUWceHOr4CBJVGL
 ucxioDRZHq//z8XmeP98dWsZsAAAA
X-Change-ID: 20250602-fix-ltc4282-repetead-write-80c020af1f83
To: linux-hwmon@vger.kernel.org
Cc: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749659172; l=443;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=4qoIdVZqskHdh9gXoHDe3uhAq3b9ORl/KtK3XxjIt68=;
 b=73msCQlKQtx9+rG7Ftg6n3wZIVtb0TxjARxVIqZsFEe2RW9vlPmnHdyMLQiB20Xlu94CqkFmT
 7Vi+/FNXUrLBpe3EVFfqcS2iyy8S+vvSGZht/qL8RGASsu9HawM/hiK
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Simple series fixing a repeated register write and bad variable name.

---
Nuno Sá (2):
      hwmon: ltc4282: avoid repeated register write
      hwmon: ltc4282: fix copy past on variable name

 drivers/hwmon/ltc4282.c | 11 ++---------
 1 file changed, 2 insertions(+), 9 deletions(-)
---
base-commit: 4f89db249aab8c9887821b54e1571408e65246f2
change-id: 20250602-fix-ltc4282-repetead-write-80c020af1f83
--

Thanks!
- Nuno Sá

