From: Nuno Sa <nuno.sa@analog.com>
Date: Mon, 05 Feb 2024 13:09:33 +0100
Subject: [PATCH v2 2/2] of: dynamic: flush devlinks workqueue before
 destroying the changeset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240205-fix-device-links-overlays-v2-2-5344f8c79d57@analog.com>
References: <20240205-fix-device-links-overlays-v2-0-5344f8c79d57@analog.com>
In-Reply-To: <20240205-fix-device-links-overlays-v2-0-5344f8c79d57@analog.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, Rob Herring <robh+dt@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Daniel Scally <djrscally@gmail.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, Len Brown <lenb@kernel.org>
Cc: linux-acpi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707134972; l=1506;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=YDuksPxVzpgUXsXtMiptrKAHNtqa9E4wT61h67KKExU=;
 b=+pR9xIxPkbxkT8MxATu4NfCBUJ+zzK6rP+cyMoqKYeDDvSxTJi8Gd3uvMlCO1CEC8rqyBMLCI
 WWMLTeb8A1LDHRH9Rh6EZ0RqMEszqHesQn9jA8kbQP8zEix/vgTjyD3
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Device links will drop their supplier + consumer refcounts
asynchronously. That means that the refcount of the of_node attached to
these devices will also be dropped asynchronously and so we cannot
guarantee the DT overlay assumption that the of_node refcount must be 1 in
__of_changeset_entry_destroy().

Given the above, call the new fwnode_links_flush_queue() helper to flush
the devlink workqueue so we can be sure that all links are dropped before
doing the proper checks.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/of/dynamic.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/of/dynamic.c b/drivers/of/dynamic.c
index 3bf27052832f..b7153c72c9c9 100644
--- a/drivers/of/dynamic.c
+++ b/drivers/of/dynamic.c
@@ -14,6 +14,7 @@
 #include <linux/slab.h>
 #include <linux/string.h>
 #include <linux/proc_fs.h>
+#include <linux/fwnode.h>
 
 #include "of_private.h"
 
@@ -518,6 +519,13 @@ EXPORT_SYMBOL(of_changeset_create_node);
 
 static void __of_changeset_entry_destroy(struct of_changeset_entry *ce)
 {
+	/*
+	 * device links drop their device references (and hence their of_node
+	 * references) asynchronously on a dedicated workqueue. Hence we need
+	 * to flush it to make sure everything is done before doing the below
+	 * checks.
+	 */
+	fwnode_links_flush_queue();
 	if (ce->action == OF_RECONFIG_ATTACH_NODE &&
 	    of_node_check_flag(ce->np, OF_OVERLAY)) {
 		if (kref_read(&ce->np->kobj.kref) > 1) {

-- 
2.43.0

