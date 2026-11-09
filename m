From: Lukas Hahn <lukas.hahn@codewrights.de>
Date: Mon, 09 Nov 2026 17:43:37 +0100
Subject: [PATCH wireless-next] wifi: wilc1000: skip RSSI query in
 dump_station() before firmware load
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-wilc1000-dump-station-v1-1-501094b8e786@codewrights.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMywrCMBAAf6Xs2YVNCy3xV8RDm111pcaSTR9Q+
 u9GPQ7DzA4mScXgXO2QZFHTdyzgThWERx/vgsqFoaa6dY48rjoGR0TI82tCy30uBXLXeN813Ia
 BobRTkptuv+8FVk0yihlG2TJc/9rm4Skhf99wHB+LGxSniAAAAA==
X-Change-ID: 20261109-wilc1000-dump-station-d739973d6cbd
To: Ajay Singh <ajay.kathat@microchip.com>, 
 Claudiu Beznea <claudiu.beznea@tuxon.dev>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Lukas Hahn <lukas.hahn@codewrights.de>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794242618; l=2855;
 i=lukas.hahn@codewrights.de; s=20261109; h=from:subject:message-id;
 bh=w74s3Tm5Fitkvt7/EPKLuvfTmHfa4AYDV30NGcrNsQg=;
 b=gTuaQjBKrkzC6ldqTIGCi0Z1yIy3wJ5LPWrwqEai6jiyBSXAQFYTQp4IlCKm7jwJZc016MHR4
 Ow3XgSNbL7ED9gFXFVlT8WpWZWfnkdHUndj6Z9tFthxkjjgham2V2Ee
X-Developer-Key: i=lukas.hahn@codewrights.de; a=ed25519;
 pk=Mg1ixrNH7vyHiaMBzg5Dc0STeZSinfuImTLfUFEjR5s=
X-Endpoint-Received: by B4 Relay for lukas.hahn@codewrights.de/20261109 with auth_id=1462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The firmware is only downloaded and started when the first interface is
brought up (wilc_wlan_initialize()), which then sets wilc->initialized.
dump_station() does not check this and always sends a WID_RSSI query to
the chip. Before the interface has been opened for the first time,
nothing processes the queued config packet, so wilc_get_rssi() only
returns after WILC_CFG_PKTS_TIMEOUT (3 s), logs "Failed to get RSSI
value" and the station dump fails with -ETIMEDOUT.

systemd-networkd hits exactly this window: while enumerating links at
start-up it sends an NL80211_CMD_GET_STATION dump request for every
interface in station mode, typically before wpa_supplicant has opened
the interface. This was observed on an STM32MP157 board with a WILC1000
on SDIO, running Microchip's vendor driver, which has the same
dump_station() implementation: systemd-networkd, and every unit ordered
after it, was delayed by about 3 s on each boot.

get_station() already returns early in station mode while the firmware
is not initialized. Do the same in dump_station(): without running
firmware there can't be an association, so end the dump with -ENOENT,
which nl80211 reports to user space as an empty station list.

The problem was analysed and this patch was prepared with the help of
an AI coding assistant (Claude, Anthropic).

Fixes: 5625f965d764 ("wilc1000: move wilc driver out of staging")
Signed-off-by: Lukas Hahn <lukas.hahn@codewrights.de>
---
Build-tested on wireless-next: ARCH=arm multi_v7_defconfig (gcc 15.3)
and x86_64_defconfig (gcc 12.2) with WILC1000_SDIO=m and
WILC1000_SPI=m, both with W=1, no new warnings.

Runtime-tested with the equivalent change on Microchip's linux-6.6-mchp
vendor driver on an STM32MP157 board (WILC1000 on SDIO): "Failed to get
RSSI value" no longer appears at boot and the boot is about 3 s faster.
The mainline driver itself has not been runtime-tested, as the board
runs the vendor driver.
---
 drivers/net/wireless/microchip/wilc1000/cfg80211.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/net/wireless/microchip/wilc1000/cfg80211.c b/drivers/net/wireless/microchip/wilc1000/cfg80211.c
index 3db290875..7fd165241 100644
--- a/drivers/net/wireless/microchip/wilc1000/cfg80211.c
+++ b/drivers/net/wireless/microchip/wilc1000/cfg80211.c
@@ -1335,6 +1335,10 @@ static int dump_station(struct wiphy *wiphy, struct wireless_dev *wdev,
 	if (idx != 0)
 		return -ENOENT;
 
+	/* Firmware is not running yet, so there can't be an association */
+	if (!vif->wilc->initialized)
+		return -ENOENT;
+
 	ret = wilc_get_rssi(vif, &sinfo->signal);
 	if (ret)
 		return ret;

---
base-commit: b8e5b0ae8ff47240366d38e5d12c65f878724316
change-id: 20261109-wilc1000-dump-station-d739973d6cbd

Best regards,
--  
Lukas Hahn <lukas.hahn@codewrights.de>

