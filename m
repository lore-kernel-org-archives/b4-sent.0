From: Sam Day <me@samcday.com>
Date: Wed, 10 Jun 2026 11:27:43 +1000
Subject: [PATCH v3 05/10] .gitignore: ignore binman-generated blobs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260610-android-binman-v3-5-710298a38fcc@samcday.com>
References: <20260610-android-binman-v3-0-710298a38fcc@samcday.com>
In-Reply-To: <20260610-android-binman-v3-0-710298a38fcc@samcday.com>
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Bryan Brattlof <bb@ti.com>, 
 Yannic Moog <y.moog@phytec.de>, Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Yegor Yefremov <yegorslists@googlemail.com>, 
 Patrice Chotard <patrice.chotard@foss.st.com>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Rasmus Villemoes <ravi@prevas.dk>, Javier Tia <floss@jetm.me>, 
 Minkyu Kang <mk7.kang@samsung.com>, 
 Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Henrik Grimler <henrik@grimler.se>, yan wang <yan.wang@softathome.com>, 
 Marek Vasut <marex@nabladev.com>, Denis Mukhin <dmukhin@ford.com>, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781054859; l=719;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=cgBylfyhDbVtoVDWN8K78nuoTKnvpxWGKVN4Rf/rL74=;
 b=XUZW3Vw7rsJTYiwdkByQISOjiWV+hZ4YYQfnN8wQevJC/x+U3yJhmFq9CYkjRqgr4DKVk3HhH
 G7OjXumQcmUCsgrbPAm1Z1MR211dRlD/KKXn/wGgqzZFr1h8jbP/yTm
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The new android_boot etype is causing these /comp*u-boot-nodtb artifacts
to be generated, which aren't currently picked up by any ignore rules.
This issue only occurs when doing in-tree builds, but it's still worth
fixing regardless.

Reviewed-by: Simon Glass <sjg@chromium.org>
Signed-off-by: Sam Day <me@samcday.com>
---
 .gitignore | 1 +
 1 file changed, 1 insertion(+)

diff --git a/.gitignore b/.gitignore
index d57d3be0291..6e274de77ab 100644
--- a/.gitignore
+++ b/.gitignore
@@ -84,6 +84,7 @@ fit-dtb.blob*
 /test/fdt_overlay/test-fdt-overlay-stacked.dtbo.S
 /test/fdt_overlay/test-fdt-overlay.dtbo.S
 capsule_esl_file
+/comp.*.u-boot-nodtb
 
 #
 # Generated include files

-- 
2.54.0

