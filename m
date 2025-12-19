From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 19 Dec 2025 16:11:05 +0000
Subject: [PATCH] hwmon: (ltc4282): Fix reset_history file permissions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251219-ltc4282-fix-reset-history-v1-1-8eab974c124b@analog.com>
X-B4-Tracking: v=1; b=H4sIABh5RWkC/x2MwQrCMBAFf6Xs2QWzNKD+SvFgkxe7IG3ZDaKE/
 rvB48DMNHKYwuk2NDK81XVbO4TTQGl5rE+w5s4kZ4lBwpVfNY1yES76YYOj8qJeN/tyjnMsOQm
 QQL3fDV36v6f7cfwAycCqYmsAAAA=
X-Change-ID: 20251219-ltc4282-fix-reset-history-d5b5fdc2eece
To: linux-hwmon@vger.kernel.org
Cc: Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766160668; l=1481;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=bBccOajjH8w1tZnRXp2xS8mA63Q2/GvTMzjF/7BuoN8=;
 b=zMabgTWThZvax76u5+L1rcldqLZbTw22eZA8G3stO3MVCb/3R4EgBkBOv5Wz9wkDvjhfCHWEr
 ZeZtlka/ZycA54fEkIhY2P+mslph5ALIsQo4n/3hUOuskecj9vhtEoR
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The reset_history attributes are write only. Hence don't report them as
readable just to return -EOPNOTSUPP later on.

Fixes: cbc29538dbf7 ("hwmon: Add driver for LTC4282")
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/hwmon/ltc4282.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/hwmon/ltc4282.c b/drivers/hwmon/ltc4282.c
index b9cad89f2cd9..db6534e67991 100644
--- a/drivers/hwmon/ltc4282.c
+++ b/drivers/hwmon/ltc4282.c
@@ -1000,8 +1000,9 @@ static umode_t ltc4282_in_is_visible(const struct ltc4282_state *st, u32 attr)
 	case hwmon_in_max:
 	case hwmon_in_min:
 	case hwmon_in_enable:
-	case hwmon_in_reset_history:
 		return 0644;
+	case hwmon_in_reset_history:
+		return 0200;
 	default:
 		return 0;
 	}
@@ -1020,8 +1021,9 @@ static umode_t ltc4282_curr_is_visible(u32 attr)
 		return 0444;
 	case hwmon_curr_max:
 	case hwmon_curr_min:
-	case hwmon_curr_reset_history:
 		return 0644;
+	case hwmon_curr_reset_history:
+		return 0200;
 	default:
 		return 0;
 	}
@@ -1039,8 +1041,9 @@ static umode_t ltc4282_power_is_visible(u32 attr)
 		return 0444;
 	case hwmon_power_max:
 	case hwmon_power_min:
-	case hwmon_power_reset_history:
 		return 0644;
+	case hwmon_power_reset_history:
+		return 0200;
 	default:
 		return 0;
 	}

---
base-commit: 1d9d442ab179b11c629ae8f87533c9ae381cc15f
change-id: 20251219-ltc4282-fix-reset-history-d5b5fdc2eece
--

Thanks!
- Nuno Sá

