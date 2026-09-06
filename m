From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 20:36:31 +0200
Subject: [PATCH v2 08/22] thunderbolt: Don't read the UID if we already
 know it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-apple-soc-tbt-v2-8-1f80085f93fb@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1183; i=sven@kernel.org;
 h=from:subject:message-id; bh=nAvvsoDo0FnW497Le/eu1wxUngPW7Yw1+XhupbJs0xU=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bcTft1bIN3s71O0l644+DSY66WJwU0J+ZPd2KNX6Jp8
 2rWPMMLHaUsDGJcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJbJrDyPCP8cBJFrGu0xry
 bS2MqjJ5+b1LWh7XS5bY7Ol+1/NbUIuR4cFSFi6ZL3ExVSc9XOZEKQpxTJogVW5WPvXiadWgyyp
 yPAA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Apple Silicon the host router's UID comes from the DROM provided by
the device tree and is already known by the time tb_switch_set_uuid()
runs. Skip reading it from the config space again in that case.

For other USB4 hosts this only drops a duplicate read because
tb_drom_host_read() has already filled in the UID from ROUTER_CS_7
before tb_switch_set_uuid() runs. Device routers keep reading it
unconditionally.

Signed-off-by: Sven Peter <sven@kernel.org>
Reviewed-by: Joshua Peisach <jpeisach@ubuntu.com>
---
 drivers/thunderbolt/switch.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/thunderbolt/switch.c b/drivers/thunderbolt/switch.c
index 404c0693df50..3f54a5ae56b0 100644
--- a/drivers/thunderbolt/switch.c
+++ b/drivers/thunderbolt/switch.c
@@ -2692,9 +2692,11 @@ static int tb_switch_set_uuid(struct tb_switch *sw)
 		return 0;
 
 	if (tb_switch_is_usb4(sw)) {
-		ret = usb4_switch_read_uid(sw, &sw->uid);
-		if (ret)
-			return ret;
+		if (tb_route(sw) || !sw->uid) {
+			ret = usb4_switch_read_uid(sw, &sw->uid);
+			if (ret)
+				return ret;
+		}
 		uid = true;
 	} else {
 		/*

-- 
2.55.0

