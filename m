From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 20:36:26 +0200
Subject: [PATCH v2 03/22] usb: typec: tipd: Register a USB4 port mode for
 CD321x
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-apple-soc-tbt-v2-3-1f80085f93fb@kernel.org>
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
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2166; i=sven@kernel.org;
 h=from:subject:message-id; bh=HIg42Vsn0TNmV8kxJI54k7Wj89qIig0luyI+sG+agh8=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bcTbuX8HqzOHkmRlrHf5xS6rrOkaVksumZtuvWVtFin
 a+YGVw7SlkYxLgYZMUUWbbvtzd98vCN4NJNl97DzGFlAhnCwMUpABOx/c/wv3D+xkWzTmcX3Pkh
 YyHK7rVyCa+sQ3wqd9B7DmHh1MUWyxn+50apskv23p+/UJX9WOr+ggPHQkxWhbjsW2N49LqybqM
 lNwA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Register a USB4 mode next to the DP and Thunderbolt alternate modes so
that negotiated USB4 partner modes can be linked to the port. Identify
it using TYPEC_MODE_KIND_USB4 without an SVID or mode index.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/typec/tipd/core.c | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/drivers/usb/typec/tipd/core.c b/drivers/usb/typec/tipd/core.c
index f76f563dc42b..8c7f93d4270e 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -211,6 +211,7 @@ struct cd321x {
 
 	struct typec_altmode *port_altmode_dp;
 	struct typec_altmode *port_altmode_tbt;
+	struct typec_altmode *port_altmode_usb4;
 
 	struct typec_mux *mux;
 	struct typec_mux_state state;
@@ -1312,6 +1313,18 @@ static int cd321x_register_port_altmodes(struct cd321x *cd321x)
 	}
 	cd321x->port_altmode_tbt = amode;
 
+	memset(&desc, 0, sizeof(desc));
+	desc.mode_kind = TYPEC_MODE_KIND_USB4;
+	amode = typec_port_register_altmode(cd321x->tps.port, &desc);
+	if (IS_ERR(amode)) {
+		typec_unregister_altmode(cd321x->port_altmode_dp);
+		typec_unregister_altmode(cd321x->port_altmode_tbt);
+		cd321x->port_altmode_dp = NULL;
+		cd321x->port_altmode_tbt = NULL;
+		return PTR_ERR(amode);
+	}
+	cd321x->port_altmode_usb4 = amode;
+
 	return 0;
 }
 
@@ -1347,8 +1360,10 @@ cd321x_register_port(struct tps6598x *tps, struct fwnode_handle *fwnode)
 err_unregister_altmodes:
 	typec_unregister_altmode(cd321x->port_altmode_dp);
 	typec_unregister_altmode(cd321x->port_altmode_tbt);
+	typec_unregister_altmode(cd321x->port_altmode_usb4);
 	cd321x->port_altmode_dp = NULL;
 	cd321x->port_altmode_tbt = NULL;
+	cd321x->port_altmode_usb4 = NULL;
 err_unregister_port:
 	typec_unregister_port(tps->port);
 	return ret;
@@ -1371,6 +1386,8 @@ cd321x_unregister_port(struct tps6598x *tps)
 	cd321x->port_altmode_dp = NULL;
 	typec_unregister_altmode(cd321x->port_altmode_tbt);
 	cd321x->port_altmode_tbt = NULL;
+	typec_unregister_altmode(cd321x->port_altmode_usb4);
+	cd321x->port_altmode_usb4 = NULL;
 	typec_unregister_port(tps->port);
 }
 

-- 
2.55.0

