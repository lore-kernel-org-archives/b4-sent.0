From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 10:39:05 +0000
Subject: [PATCH 2/3] usb: typec: fusb302: Toggle with the default Rp
 current
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-tcpm-attach-reboot-v1-2-7657cc1e2dca@gmail.com>
References: <20261110-tcpm-attach-reboot-v1-0-7657cc1e2dca@gmail.com>
In-Reply-To: <20261110-tcpm-attach-reboot-v1-0-7657cc1e2dca@gmail.com>
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794307143; l=2135;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=G9r74JoIhZT94dJ6tTMGjq0F8LLdb74sZvrJnDecsR0=;
 b=4ve0PIDBEv9KVX3vtBywpv6RlFkDS691ExgWB7vxo6V65qFCXSE+QaqPlcyo0s4kkMibchjm0
 X3umfOMvTA2CVsw19M4Eit8Q5x3c3ta13/EZwUMa9evBqZWqzHwYkYZ
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tcpm_start_toggling() programs the Rp current that tcpm asks for, which
is the current of the source PDO (Rp 3.0A on boards that can source
3A) when the port starts toggling from Unattached.SRC, and the default
current when it starts from Unattached.SNK after a detach.

A Genesys Logic based USB-C to DisplayPort cable connected to the
Orange Pi 5 is often not detected after a warm reboot: the FUSB302
toggle state machine raises no interrupt with it while it drives the
high Rp current, but finds it within seconds once toggling restarts
with the default current after another device was detached.

Unattached sources may advertise any Rp level, and tcpm sets the
configured level through set_cc() once the port is attached, so always
toggle with the default current.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/usb/typec/tcpm/fusb302.c | 13 +++++++++++--
 1 file changed, 11 insertions(+), 2 deletions(-)

diff --git a/drivers/usb/typec/tcpm/fusb302.c b/drivers/usb/typec/tcpm/fusb302.c
index 3319f6a2b0c9..53c5671fe45b 100644
--- a/drivers/usb/typec/tcpm/fusb302.c
+++ b/drivers/usb/typec/tcpm/fusb302.c
@@ -942,10 +942,19 @@ static int tcpm_start_toggling(struct tcpc_dev *dev,
 	}
 
 	mutex_lock(&chip->lock);
-	ret = fusb302_set_src_current(chip, cc_src_current[cc]);
+	/*
+	 * Look for a partner with the default USB current advertisement.
+	 * Some sinks (seen with a Genesys Logic based USB-C to DisplayPort
+	 * cable) present an Rd that the FUSB302 toggle state machine does
+	 * not detect while it drives the high (3.0 A) Rp current, so they
+	 * are only found when toggling starts from the sink side. Unattached
+	 * sources may advertise any Rp level, and tcpm sets the configured
+	 * level through set_cc() once the port is attached.
+	 */
+	ret = fusb302_set_src_current(chip, SRC_CURRENT_DEFAULT);
 	if (ret < 0) {
 		fusb302_log(chip, "unable to set src current %s, ret=%d",
-			    typec_cc_status_name[cc], ret);
+			    typec_cc_status_name[TYPEC_CC_RP_DEF], ret);
 		goto done;
 	}
 	ret = fusb302_set_toggling(chip, mode);

-- 
2.55.0

