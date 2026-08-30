From: Sven Peter <sven@kernel.org>
Date: Sun, 30 Aug 2026 22:19:25 +0200
Subject: [PATCH 07/19] thunderbolt: Don't read the UID if we already know
 it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-apple-soc-tbt-v1-7-44bc9348683c@kernel.org>
References: <20260830-b4-apple-soc-tbt-v1-0-44bc9348683c@kernel.org>
In-Reply-To: <20260830-b4-apple-soc-tbt-v1-0-44bc9348683c@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Konrad Dybcio <konradybcio@kernel.org>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1132; i=sven@kernel.org;
 h=from:subject:message-id; bh=dVz3sxP5vavj12E7kkybYYbfTtTMRNdpjA2Sq4nGu8k=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9aUCWEHI31Y/sqHXRNsDqvs+ZK+//CSLoNZ3yborZ/m0
 LNIRXhNRykLgxgXg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAi8m8YGZZb1coYeZ/ee7gz
 89ENte74xapOrX4blglPYVm4Jv2S7FFGhu1hJ8TmxivM+X1t03/nT41XLbRuWt77xti2857VNfV
 wLWYA
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

