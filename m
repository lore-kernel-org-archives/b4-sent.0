From: Sam Day <me@samcday.com>
Date: Mon, 08 Jun 2026 09:37:11 +1000
Subject: [PATCH v2 2/8] .gitignore: ignore binman-generated blobs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-android-binman-v2-2-b8203682507f@samcday.com>
References: <20260608-android-binman-v2-0-b8203682507f@samcday.com>
In-Reply-To: <20260608-android-binman-v2-0-b8203682507f@samcday.com>
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
 Henrik Grimler <henrik@grimler.se>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780875433; l=582;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=IFAh0D17FHXmpT6fv1JXFTXI5i5r9qd6SAH9ZAkhrM8=;
 b=TG50B4iHDOib0uimkE4BR/x7GVy5kvIDF6gTBtYrmEHyQSKwL4N/ZTmVyqKrokDk5Tdl1eQpw
 CD3Wx3UxFolB/PxyeAxp7k1Sb8rZfwfWsyzjOj28MbynEmBCEOvwnLw
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The new android_boot etype is causing these /comp*u-boot-nodtb artifacts
to be generated, which aren't currently picked up by any ignore rules.

Signed-off-by: Sam Day <me@samcday.com>
---
 .gitignore | 1 +
 1 file changed, 1 insertion(+)

diff --git a/.gitignore b/.gitignore
index e5d22dbe8e9..6ecac327ec2 100644
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

