From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Mon, 08 Dec 2025 16:13:10 +0200
Subject: [PATCH RESEND v8 18/21] arm64: defconfig: disable deprecated
 MAX96712 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251208-gmsl2-3_serdes-v8-18-7b8d457e2e04@analog.com>
References: <20251208-gmsl2-3_serdes-v8-0-7b8d457e2e04@analog.com>
In-Reply-To: <20251208-gmsl2-3_serdes-v8-0-7b8d457e2e04@analog.com>
To: Tomi Valkeinen <tomi.valkeinen+renesas@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Julien Massot <julien.massot@collabora.com>, Rob Herring <robh@kernel.org>, 
 =?utf-8?q?Niklas_S=C3=B6derlund?= <niklas.soderlund@ragnatech.se>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Dumitru Ceclan <dumitru.ceclan@analog.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-staging@lists.linux.dev, linux-gpio@vger.kernel.org, 
 mitrutzceclan@gmail.com, Cosmin Tanislav <demonsingur@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1765203192; l=722;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=VF4KSVJI1GCWF1vEPraFbtaDI8K1Hqm1ue911q30Ry4=;
 b=1PI/X+8dtqcjrCDZiCpIp9D0uFO6nMnGCdvnnmKD7qx2fVhf+uUqKLfBFZi0DRseWNm2sDFlq
 Yq/Kg14C9dmBdKoUw/ecK2yrLDBerajHaMeSn8zvyUjSzsjfsENxedz
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Cosmin Tanislav <demonsingur@gmail.com>

The staging MAX96712 driver will be removed as its functionality has
been moved to the MAX96724 driver which makes use of the Maxim
GMSL2/3 deserializer framework.

Signed-off-by: Cosmin Tanislav <demonsingur@gmail.com>
---
 arch/arm64/configs/defconfig | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index e3a2d37bd104..298cc76fe7b6 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -1319,7 +1319,6 @@ CONFIG_GREYBUS=m
 CONFIG_GREYBUS_BEAGLEPLAY=m
 CONFIG_STAGING=y
 CONFIG_STAGING_MEDIA=y
-CONFIG_VIDEO_MAX96712=m
 CONFIG_VIDEO_MESON_VDEC=m
 CONFIG_SND_BCM2835=m
 CONFIG_CHROME_PLATFORMS=y

-- 
2.43.0

