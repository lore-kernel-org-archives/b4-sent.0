From: Ye He <ye.he@amlogic.com>
Date: Fri, 21 Nov 2025 17:16:25 +0800
Subject: [PATCH bluez] client: Fix issue of bearer info not printing
 correctly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251121-bearer-info-v1-1-f38dc0cbbbd0@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAOgtIGkC/x3MMQqAMAxA0atIZgtNQEGvIg5VUw1IKymKWLy7x
 fEN/2dIrMIJ+iqD8iVJYijAuoJ5c2FlI0sxkKUGkdBM7JTVSPDRdLZD74hma1soxaHs5f5vA0z
 7yQ+M7/sBIxx282QAAAA=
X-Change-ID: 20251121-bearer-info-9091fa22c006
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763716585; l=1718;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=9ong/20pvfFl6Qwp1TJerRk2TanoS/FERDslnNWs9xM=;
 b=gZQByx5XNCEufcS5iKTZRA289I9hfwG9//zUwNbohuEZofXtyXsQ5TF+wb7zGdapo9knRgyRj
 YOlMcxJRhvHDA6JuW23mEAR41X4bPczpzSJ3o5DdCKMaBCgr+G6fNeQ
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The device proxy was incorrectly used when printing
bearer properties.

Signed-off-by: Ye He <ye.he@amlogic.com>
---
 client/main.c | 12 ++++++------
 1 file changed, 6 insertions(+), 6 deletions(-)

diff --git a/client/main.c b/client/main.c
index 0a928efaa9bb0d2a806895ff8f8c0c7c0d2493bd..a3a46ca267b09fe54c2f3cfb723f3e72d03f699e 100644
--- a/client/main.c
+++ b/client/main.c
@@ -1894,9 +1894,9 @@ static void cmd_info(int argc, char *argv[])
 				      g_dbus_proxy_get_path(proxy),
 				      "org.bluez.Bearer.BREDR1");
 	if (bearer) {
-		print_property_with_label(proxy, "Paired", "BREDR.Paired");
-		print_property_with_label(proxy, "Bonded", "BREDR.Bonded");
-		print_property_with_label(proxy, "Connected",
+		print_property_with_label(bearer, "Paired", "BREDR.Paired");
+		print_property_with_label(bearer, "Bonded", "BREDR.Bonded");
+		print_property_with_label(bearer, "Connected",
 							"BREDR.Connected");
 	}
 
@@ -1904,9 +1904,9 @@ static void cmd_info(int argc, char *argv[])
 				      g_dbus_proxy_get_path(proxy),
 				      "org.bluez.Bearer.LE1");
 	if (bearer) {
-		print_property_with_label(proxy, "Paired", "LE.Paired");
-		print_property_with_label(proxy, "Bonded", "LE.Bonded");
-		print_property_with_label(proxy, "Connected", "LE.Connected");
+		print_property_with_label(bearer, "Paired", "LE.Paired");
+		print_property_with_label(bearer, "Bonded", "LE.Bonded");
+		print_property_with_label(bearer, "Connected", "LE.Connected");
 	}
 
 	return bt_shell_noninteractive_quit(EXIT_SUCCESS);

---
base-commit: 8a41ac3fde997137d374791a93a49d9a3abac0e0
change-id: 20251121-bearer-info-9091fa22c006

Best regards,
-- 
Ye He <ye.he@amlogic.com>

