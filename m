From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH 0/2] Add support for ASUS RT-AC3200 and ASUS RT-AC5300
Date: Sun, 28 Apr 2024 19:12:00 +0300
Message-Id: <20240428-asus-rt-ac3200-ac5300-v1-0-36cda9d6dcb6@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAFB1LmYC/x2MywqDQAwAf0Vy7kLMrvj4ldJD2EbNRWWjpSD77
 w09DXOYucGkqBhMzQ1FPmq6by7to4G88rZI0Lc7EFLCRENguyyUM3COhOjoomPEceY2J+LYg7d
 HkVm//+/zVesPcUy1MmcAAAA=
To: =?utf-8?q?Rafa=C5=82_Mi=C5=82ecki?= <zajec5@gmail.com>
Cc: Tom Brautaset <tbrautaset@gmail.com>, openwrt-devel@lists.openwrt.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1714320729; l=840;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=UcLK82zTxleNeiguVVD1QHX3VAIK/OXvemhHUUMUO/U=;
 b=O8SAToMskyJfNw21f5FXPTII3+XTaRJeiR67ICMIO/ZBNSra1KR0GvATjenz/g0vjpv76z91p
 eUQdy95Uh1qA9ACgsGlL5ENdm1r3xWgjzb24z+tEeSdrOK6SaXjkeAm
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello.

This patch series brings support for ASUS RT-AC3200 and ASUS RT-AC5300 on
OpenWrt.

Note to Rafał, please apply this after backporting the device tree patches
for these devices.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Arınç ÜNAL (2):
      bcm53xx: add support for ASUS RT-AC3200 and ASUS RT-AC5300
      packages: nvram: add asus,rt-ac{3200,5300} to set_wireless_led_behaviour

 package/utils/nvram/Makefile                 |  2 +-
 package/utils/nvram/files/nvram-bcm53xx.init | 11 +++++++++--
 target/linux/bcm53xx/image/Makefile          | 16 ++++++++++++++++
 3 files changed, 26 insertions(+), 3 deletions(-)
---
base-commit: 1b190dfd3ae2f9317c0dbca3123ed6c92701489c
change-id: 20240428-asus-rt-ac3200-ac5300-909fa1c42a37

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

