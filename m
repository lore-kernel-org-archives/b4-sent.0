From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 20:02:38 +0000
Subject: [PATCH BlueZ v2 02/10] adapter: Remove experimental flag for
 PowerState
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-disto-patches-v2-2-8bab1bd08f4d@gmail.com>
References: <20240212-disto-patches-v2-0-8bab1bd08f4d@gmail.com>
In-Reply-To: <20240212-disto-patches-v2-0-8bab1bd08f4d@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Bastien Nocera <hadess@hadess.net>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707768157; l=1246;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=kBWJv6IuMJzmAjsIKoWIKgJU/uFwFAGgPEAJK3EPyjo=;
 b=LSHYBrMDViFmJ9LE74zZVT+TFh/TVVCv3IfWPUs/pVGdSerKyT8KDIekdk5AkN2qnf/SMst4S
 tGIHN5/O+yDCpNkEjeK2KSFdcqA/m5b+pwsSGcZCJD6AHSazBQ4x4/G
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Bastien Nocera <hadess@hadess.net>

Now that the feature has been tested, that the API is deemed adequate
and the reliability sufficient.

[Emil Velikov]
The feature has landed in Sept 2022, with inclinations that "we might
switch it to stable in the next release", back in Nov 2022.

Today - a bit over 1 year later -  various distributions (Fedora, Gentoo
and by extension their derivatives) are carrying this patch. I think we
can say we're reasonably stable and can merge it upstream.
---
 src/adapter.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/src/adapter.c b/src/adapter.c
index 022390f0d..ef1e66e4b 100644
--- a/src/adapter.c
+++ b/src/adapter.c
@@ -3914,8 +3914,7 @@ static const GDBusPropertyTable adapter_properties[] = {
 	{ "Alias", "s", property_get_alias, property_set_alias },
 	{ "Class", "u", property_get_class },
 	{ "Powered", "b", property_get_powered, property_set_powered },
-	{ "PowerState", "s", property_get_power_state, NULL, NULL,
-			     G_DBUS_PROPERTY_FLAG_EXPERIMENTAL },
+	{ "PowerState", "s", property_get_power_state },
 	{ "Discoverable", "b", property_get_discoverable,
 					property_set_discoverable },
 	{ "DiscoverableTimeout", "u", property_get_discoverable_timeout,

-- 
2.43.0

