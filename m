From: Petri Karhula <petri.karhula@novatron.fi>
Date: Wed, 19 Nov 2025 08:25:47 +0000
Subject: [PATCH v2 2/2] mfd: cgbc: Add support for backlight
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-cgbc-backlight-v2-2-4d4edd7ca662@novatron.fi>
References: <20251119-cgbc-backlight-v2-0-4d4edd7ca662@novatron.fi>
In-Reply-To: <20251119-cgbc-backlight-v2-0-4d4edd7ca662@novatron.fi>
To: Thomas Richard <thomas.richard@bootlin.com>, Lee Jones <lee@kernel.org>, 
 Daniel Thompson <danielt@kernel.org>, Jingoo Han <jingoohan1@gmail.com>, 
 Helge Deller <deller@gmx.de>
Cc: linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-fbdev@vger.kernel.org, Petri Karhula <petri.karhula@novatron.fi>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763540778; l=730;
 i=petri.karhula@novatron.fi; s=20251118; h=from:subject:message-id;
 bh=KPNSZCbWidPbzGQwgMCbuFj/C6Dnnhi7zAXThQ+Pso8=;
 b=A7+u4KN5Q5OzUvkb74yRsfjSwPDVsYz3jVlv1sGdlQe1+mLVQgad1xROxS1PTS1iZ1WxiMgXK
 3nCRWzu6gzTCiIKkZwybI23Dy0+poEOu0GLUs3La79VILxRSokKxgXM
X-Developer-Key: i=petri.karhula@novatron.fi; a=ed25519;
 pk=LRYJ99jPPsHJwdJEPkqlmzAMqo6oyw7I421aHEfDp7o=
X-Endpoint-Received: by B4 Relay for petri.karhula@novatron.fi/20251118 with auth_id=567
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Board Controller has control for display backlight.
Add backlight cell for the cgbc-backlight driver which
adds support for backlight brightness control.

Signed-off-by: Petri Karhula <petri.karhula@novatron.fi>
---
 drivers/mfd/cgbc-core.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/mfd/cgbc-core.c b/drivers/mfd/cgbc-core.c
index 4782ff1114a9..10bb4b414c34 100644
--- a/drivers/mfd/cgbc-core.c
+++ b/drivers/mfd/cgbc-core.c
@@ -237,6 +237,7 @@ static struct mfd_cell cgbc_devs[] = {
 	{ .name = "cgbc-i2c", .id = 1 },
 	{ .name = "cgbc-i2c", .id = 2 },
 	{ .name = "cgbc-hwmon"	},
+	{ .name = "cgbc-backlight" },
 };
 
 static int cgbc_map(struct cgbc_device_data *cgbc)

-- 
2.34.1

