From: Petr Hodina <petr.hodina@protonmail.com>
Date: Tue, 13 Oct 2026 18:33:31 +0200
Subject: [PATCH v3 1/4] cmd: button: factor out state printing from 'button
 list'
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-button-live-monitor-v3-1-3563b4d3ccdf@protonmail.com>
References: <20261013-b4-button-live-monitor-v3-0-3563b4d3ccdf@protonmail.com>
In-Reply-To: <20261013-b4-button-live-monitor-v3-0-3563b4d3ccdf@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, David Heidelberg <david@ixit.cz>, 
 Simon Glass <sjg@chromium.org>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791909215; l=1444;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=bn9LONCDG40YvlhDcsIDL12VyNjvg9ahKbXwl1FeHbY=;
 b=DjJYMdskvgUeuDEh9wsHrhBsk0JAdh8A1mdhPxRsFoYn3556q+qCdKHzLGdTvTTBi7InQafmH
 EvXXtoKkoPmAl1TSf+THBtLIkzQ48P3P8uJ4a2jypy9fQ33edwH5g9r
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the per-button state printing out of list_buttons() into
show_button_status(). This prints on/off, <inactive> or Error N
without a trailing newline. 'button list' output is unchanged.

This is a preparation for a new subcommand.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 cmd/button.c | 28 ++++++++++++++++++++--------
 1 file changed, 20 insertions(+), 8 deletions(-)

diff --git a/cmd/button.c b/cmd/button.c
index 3e6db3f5b8e..da1bf1f6e3b 100644
--- a/cmd/button.c
+++ b/cmd/button.c
@@ -28,10 +28,27 @@ static int show_button_state(struct udevice *dev)
 	return ret;
 }
 
+static void show_button_status(struct udevice *dev)
+{
+	int ret;
+
+	if (!device_active(dev)) {
+		puts("<inactive>");
+		return;
+	}
+
+	ret = button_get_state(dev);
+	if (ret >= BUTTON_COUNT)
+		ret = -EINVAL;
+	if (ret >= 0)
+		puts(state_label[ret]);
+	else
+		printf("Error %d", ret);
+}
+
 static int list_buttons(void)
 {
 	struct udevice *dev;
-	int ret;
 
 	for (uclass_find_first_device(UCLASS_BUTTON, &dev);
 	     dev;
@@ -41,13 +58,8 @@ static int list_buttons(void)
 		if (!plat->label)
 			continue;
 		printf("%-15s ", plat->label);
-		if (device_active(dev)) {
-			ret = show_button_state(dev);
-			if (ret < 0)
-				printf("Error %d\n", ret);
-		} else {
-			printf("<inactive>\n");
-		}
+		show_button_status(dev);
+		puts("\n");
 	}
 
 	return 0;

-- 
2.55.0

