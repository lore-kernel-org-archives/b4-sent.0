From: Dang Huynh <dang.huynh@mainlining.org>
Date: Sat, 08 Nov 2025 12:38:05 +0700
Subject: [PATCH v6 09/12] configs: quartz64: Enable vidconsole
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251108-vop2-pt2-v6-9-d04c699262fb@mainlining.org>
References: <20251108-vop2-pt2-v6-0-d04c699262fb@mainlining.org>
In-Reply-To: <20251108-vop2-pt2-v6-0-d04c699262fb@mainlining.org>
To: u-boot@lists.denx.de
Cc: Anatolij Gustschin <ag.dev.uboot@gmail.com>, 
 Simon Glass <sjg@chromium.org>, Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, Tom Rini <trini@konsulko.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, Alexander Graf <agraf@csgraf.de>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, Ondrej Jirman <megi@xff.cz>, 
 Ion Agorria <ion@agorria.com>, 
 Dario Binacchi <dario.binacchi@amarulasolutions.com>, 
 Dragan Simic <dsimic@manjaro.org>, 
 Patrice Chotard <patrice.chotard@foss.st.com>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, Jonas Karlman <jonas@kwiboo.se>, 
 Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>, 
 Piotr Zalewski <pZ010001011111@proton.me>, 
 Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762580305; l=734;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=tt4UdpGYzFYKfoz0nxzvuPA8/EELm6sx+CANf9C7ERQ=;
 b=HsUuwN9V9HFdCzoAW13Z6KksBekVQx5YUNHkNOoFFze7NZk5gIyXQWuYVOoyiG+f3wA4U5A5q
 gTwIhVPe48WBDBYiWA4vrinHFoKFuq6PWQHBBaT02XcLeqRH1NZknw1
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that we have VOP2 support, we should enable vidconsole.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 include/configs/quartz64_rk3566.h | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/include/configs/quartz64_rk3566.h b/include/configs/quartz64_rk3566.h
index dfe0fee94cd..bf391458219 100644
--- a/include/configs/quartz64_rk3566.h
+++ b/include/configs/quartz64_rk3566.h
@@ -3,7 +3,10 @@
 #ifndef __QUARTZ64_RK3566_H
 #define __QUARTZ64_RK3566_H
 
-#define ROCKCHIP_DEVICE_SETTINGS
+#define ROCKCHIP_DEVICE_SETTINGS \
+		"stdin=serial,usbkbd\0" \
+		"stdout=serial,vidconsole\0" \
+		"stderr=serial,vidconsole\0"
 
 #include <configs/rk3568_common.h>
 

-- 
2.51.2

