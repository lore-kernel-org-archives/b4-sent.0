From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 20:36:34 +0200
Subject: [PATCH v2 11/22] thunderbolt: Find Apple VSE capability during
 startup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-apple-soc-tbt-v2-11-1f80085f93fb@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2467; i=sven@kernel.org;
 h=from:subject:message-id; bh=hWtjtaprJYt4jyipWU9LokTTRoke60o6AWtWpZvW760=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bcTQeP+QZZqqv3lf21S5op6nGjZtsUQ7d5LZFzQ2y3m
 bnmeLJ2lLIwiHExyIopsmzfb2/65OEbwaWbLr2HmcPKBDKEgYtTACbi+ZeRoWHKom2Moj7Mexm0
 trcsX2nZ7Hpdq8WHU87p1d197PO1JBn+hzCoq79lrpKR3axyyW6+/2WPkmdMV47cMXUUML75Qjm
 NCQA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Only Apple Silicon host routers have the Apple vendor-specific extended
capability. Look it up when the software connection manager starts and
store its offset in the root switch.

The Apple NHI driver can then use the stored offset when programming
cable information without searching the router capabilities itself.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/thunderbolt/tb.c      | 4 ++++
 drivers/thunderbolt/tb.h      | 2 ++
 drivers/thunderbolt/tb_regs.h | 1 +
 3 files changed, 7 insertions(+)

diff --git a/drivers/thunderbolt/tb.c b/drivers/thunderbolt/tb.c
index bf1c192ec10a..d2832323cc36 100644
--- a/drivers/thunderbolt/tb.c
+++ b/drivers/thunderbolt/tb.c
@@ -3025,6 +3025,10 @@ static int tb_start(struct tb *tb, bool reset)
 		return dev_err_probe(tb->nhi->dev, PTR_ERR(tb->root_switch),
 				     "failed to allocate host router\n");
 
+	ret = tb_switch_find_vse_cap(tb->root_switch, TB_VSE_CAP_APPLE);
+	if (ret > 0)
+		tb->root_switch->cap_vsec_apple = ret;
+
 	/*
 	 * ICM firmware upgrade needs running firmware and in native
 	 * mode that is not available so disable firmware upgrade of the
diff --git a/drivers/thunderbolt/tb.h b/drivers/thunderbolt/tb.h
index 4373336d9425..fbd1a0a9927a 100644
--- a/drivers/thunderbolt/tb.h
+++ b/drivers/thunderbolt/tb.h
@@ -132,6 +132,7 @@ struct tb_switch_tmu {
  * @link_usb4: Upstream link is USB4
  * @generation: Switch Thunderbolt generation
  * @cap_plug_events: Offset to the plug events capability (%0 if not found)
+ * @cap_vsec_apple: Offset to the Apple vendor specific capability (%0 if not found)
  * @cap_vsec_tmu: Offset to the TMU vendor specific capability (%0 if not found)
  * @cap_lc: Offset to the link controller capability (%0 if not found)
  * @cap_lp: Offset to the low power (CLx for TBT) capability (%0 if not found)
@@ -187,6 +188,7 @@ struct tb_switch {
 	bool link_usb4;
 	unsigned int generation;
 	int cap_plug_events;
+	int cap_vsec_apple;
 	int cap_vsec_tmu;
 	int cap_lc;
 	int cap_lp;
diff --git a/drivers/thunderbolt/tb_regs.h b/drivers/thunderbolt/tb_regs.h
index 92d893634d2b..a37e55fec157 100644
--- a/drivers/thunderbolt/tb_regs.h
+++ b/drivers/thunderbolt/tb_regs.h
@@ -31,6 +31,7 @@ enum tb_switch_cap {
 };
 
 enum tb_switch_vse_cap {
+	TB_VSE_CAP_APPLE		= 0x00,
 	TB_VSE_CAP_PLUG_EVENTS		= 0x01, /* also EEPROM */
 	TB_VSE_CAP_TIME2		= 0x03,
 	TB_VSE_CAP_CP_LP		= 0x04,

-- 
2.55.0

