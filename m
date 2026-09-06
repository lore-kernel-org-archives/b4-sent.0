From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 20:36:41 +0200
Subject: [PATCH v2 18/22] thunderbolt: Export symbols required by the Apple
 Silicon driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-apple-soc-tbt-v2-18-1f80085f93fb@kernel.org>
References: <20260906-b4-apple-soc-tbt-v2-0-1f80085f93fb@kernel.org>
In-Reply-To: <20260906-b4-apple-soc-tbt-v2-0-1f80085f93fb@kernel.org>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Konrad Dybcio <konradybcio@kernel.org>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>, Joshua Peisach <jpeisach@ubuntu.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2413; i=sven@kernel.org;
 h=from:subject:message-id; bh=McNohOokOZvCOPztdqrD6IMpQ2o/cc6SdtnvvgnHzSA=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bcTSdZK8S/HbugNl+Wt8oy+XhEgu36p59+sgc2Luk42
 n5kQUxGRykLgxgXg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAieyMZ/ie2ml3ZlrJ4+v4H
 pqWaHcd0vlcsSLD9xbDnAvsfm3StyXIM/5PSy6yEY2/IPpeY/aXQR9B4fnjydL0gYzct5a+6O4K
 7mAE=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver for the ACIO host router complex on Apple Silicon SoCs can
be built as a module and needs tb_probe() and the domain functions to
register its NHI with the software connection manager as well as
tb_cfg_write() to configure the cable details for its co-processor.
Restrict these exports to the thunderbolt_apple module to keep them
internal to the Thunderbolt subsystem.

Signed-off-by: Sven Peter <sven@kernel.org>
Reviewed-by: Joshua Peisach <jpeisach@ubuntu.com>
---
 drivers/thunderbolt/ctl.c    | 2 ++
 drivers/thunderbolt/domain.c | 2 ++
 drivers/thunderbolt/tb.c     | 2 ++
 3 files changed, 6 insertions(+)

diff --git a/drivers/thunderbolt/ctl.c b/drivers/thunderbolt/ctl.c
index cd47b627f97b..b2a6b300e934 100644
--- a/drivers/thunderbolt/ctl.c
+++ b/drivers/thunderbolt/ctl.c
@@ -8,6 +8,7 @@
 
 #include <linux/crc32.h>
 #include <linux/delay.h>
+#include <linux/export.h>
 #include <linux/slab.h>
 #include <linux/pci.h>
 #include <linux/dmapool.h>
@@ -1159,6 +1160,7 @@ int tb_cfg_write(struct tb_ctl *ctl, const void *buffer, u64 route, u32 port,
 	}
 	return res.err;
 }
+EXPORT_SYMBOL_FOR_MODULES(tb_cfg_write, "thunderbolt_apple");
 
 /**
  * tb_cfg_get_upstream_port() - get upstream port number of switch at route
diff --git a/drivers/thunderbolt/domain.c b/drivers/thunderbolt/domain.c
index 12c88509a54f..477a64258b87 100644
--- a/drivers/thunderbolt/domain.c
+++ b/drivers/thunderbolt/domain.c
@@ -490,6 +490,7 @@ int tb_domain_add(struct tb *tb, bool reset)
 
 	return ret;
 }
+EXPORT_SYMBOL_FOR_MODULES(tb_domain_add, "thunderbolt_apple");
 
 /**
  * tb_domain_remove() - Removes and releases a domain
@@ -514,6 +515,7 @@ void tb_domain_remove(struct tb *tb)
 
 	device_unregister(&tb->dev);
 }
+EXPORT_SYMBOL_FOR_MODULES(tb_domain_remove, "thunderbolt_apple");
 
 /**
  * tb_domain_suspend_noirq() - Suspend a domain
diff --git a/drivers/thunderbolt/tb.c b/drivers/thunderbolt/tb.c
index 72418a07166e..98bf67360cc4 100644
--- a/drivers/thunderbolt/tb.c
+++ b/drivers/thunderbolt/tb.c
@@ -6,6 +6,7 @@
  * Copyright (C) 2019, Intel Corporation
  */
 
+#include <linux/export.h>
 #include <linux/slab.h>
 #include <linux/errno.h>
 #include <linux/delay.h>
@@ -3440,3 +3441,4 @@ struct tb *tb_probe(struct tb_nhi *nhi)
 
 	return tb;
 }
+EXPORT_SYMBOL_FOR_MODULES(tb_probe, "thunderbolt_apple");

-- 
2.55.0

