From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 20:36:30 +0200
Subject: [PATCH v2 07/22] thunderbolt: Try reading host DROM from device
 tree first
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-apple-soc-tbt-v2-7-1f80085f93fb@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2399; i=sven@kernel.org;
 h=from:subject:message-id; bh=pwxcwyZ177lrb/kV9/qF46wwbZfRgBA0AoGXpy/5Mqg=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bcTfsEHy9bOu34xDspJQwv9E6sfu8go97PKMb4vNNrk
 prqD73tHaUsDGJcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJGO1iZLhulPaq3MLIdll0
 +l3DtxduCCQv+5zw6W5LmNm5wt079GYwMpzL8D79P+ZXUKnwu61M4Tqsi/90XZypEuyia7daylR
 jCjcA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Apple Silicon SoCs the DROM is provided by a device tree property.
Try reading from that property first.

Signed-off-by: Sven Peter <sven@kernel.org>
Reviewed-by: Joshua Peisach <jpeisach@ubuntu.com>
---
 drivers/thunderbolt/eeprom.c | 27 ++++++++++++++++++++++-----
 1 file changed, 22 insertions(+), 5 deletions(-)

diff --git a/drivers/thunderbolt/eeprom.c b/drivers/thunderbolt/eeprom.c
index 2a13fa6888ba..69d5c5f70eaf 100644
--- a/drivers/thunderbolt/eeprom.c
+++ b/drivers/thunderbolt/eeprom.c
@@ -468,14 +468,15 @@ static void tb_switch_drom_free(struct tb_switch *sw)
 }
 
 /*
- * tb_drom_copy_efi - copy drom supplied by EFI to sw->drom if present
+ * tb_drom_copy_property() - Copy DROM from a device property if present
  */
-static int tb_drom_copy_efi(struct tb_switch *sw, u16 *size)
+static int tb_drom_copy_property(struct tb_switch *sw, const char *name,
+				 u16 *size)
 {
 	struct device *dev = sw->tb->nhi->dev;
 	int len, res;
 
-	len = device_property_count_u8(dev, "ThunderboltDROM");
+	len = device_property_count_u8(dev, name);
 	if (len < 0 || len < sizeof(struct tb_drom_header))
 		return -EINVAL;
 
@@ -483,8 +484,7 @@ static int tb_drom_copy_efi(struct tb_switch *sw, u16 *size)
 	if (res)
 		return res;
 
-	res = device_property_read_u8_array(dev, "ThunderboltDROM", sw->drom,
-									len);
+	res = device_property_read_u8_array(dev, name, sw->drom, len);
 	if (res)
 		goto err;
 
@@ -500,6 +500,16 @@ static int tb_drom_copy_efi(struct tb_switch *sw, u16 *size)
 	return -EINVAL;
 }
 
+static int tb_drom_copy_of_apple(struct tb_switch *sw, u16 *size)
+{
+	return tb_drom_copy_property(sw, "apple,thunderbolt-drom", size);
+}
+
+static int tb_drom_copy_efi(struct tb_switch *sw, u16 *size)
+{
+	return tb_drom_copy_property(sw, "ThunderboltDROM", size);
+}
+
 static int tb_drom_copy_nvm(struct tb_switch *sw, u16 *size)
 {
 	u16 drom_offset;
@@ -675,6 +685,13 @@ static int tb_drom_host_read(struct tb_switch *sw)
 {
 	u16 size;
 
+	/*
+	 * Apple Silicon machines always get their host DROM from the Device Tree,
+	 * so make sure to try reading it first before any other method.
+	 */
+	if (!tb_drom_copy_of_apple(sw, &size))
+		return tb_drom_parse(sw, size);
+
 	if (tb_switch_is_usb4(sw)) {
 		usb4_switch_read_uid(sw, &sw->uid);
 		if (!usb4_copy_drom(sw, &size))

-- 
2.55.0

