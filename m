From: Sven Peter <sven@kernel.org>
Date: Sun, 30 Aug 2026 22:19:24 +0200
Subject: [PATCH 06/19] thunderbolt: Try reading host DROM from device tree
 first
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-apple-soc-tbt-v1-6-44bc9348683c@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2537; i=sven@kernel.org;
 h=from:subject:message-id; bh=qXUPQQ+/YlgdXuqv7U2bExUuKkk0IWuRWSMGsGl9d24=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9aUCaGOM/MNwkOWxbjxvMyYGvCJ007Rps1QtLpU8XVbr
 +iKws8dpSwMYlwMsmKKLNv325s+efhGcOmmS+9h5rAygQxh4OIUgIlcWs/I0O0jy9rxdsmdfYG+
 P+wuW8XIsHxscl7sKPuz7nfr3NWdMxn+V4sKilw9qjK/6NWzyc6fn67OeVP/MrHp742Ii4ku5RV
 pzAA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Apple Silicon SoCs the DROM is provided by a device tree property.
Try reading from that property first.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/thunderbolt/eeprom.c | 32 +++++++++++++++++++++++++++-----
 1 file changed, 27 insertions(+), 5 deletions(-)

diff --git a/drivers/thunderbolt/eeprom.c b/drivers/thunderbolt/eeprom.c
index 2a13fa6888ba..389de7df84f6 100644
--- a/drivers/thunderbolt/eeprom.c
+++ b/drivers/thunderbolt/eeprom.c
@@ -468,14 +468,14 @@ static void tb_switch_drom_free(struct tb_switch *sw)
 }
 
 /*
- * tb_drom_copy_efi - copy drom supplied by EFI to sw->drom if present
+ * tb_drom_copy_property - copy drom from a device property if present
  */
-static int tb_drom_copy_efi(struct tb_switch *sw, u16 *size)
+static int tb_drom_copy_property(struct tb_switch *sw, const char *name, u16 *size)
 {
 	struct device *dev = sw->tb->nhi->dev;
 	int len, res;
 
-	len = device_property_count_u8(dev, "ThunderboltDROM");
+	len = device_property_count_u8(dev, name);
 	if (len < 0 || len < sizeof(struct tb_drom_header))
 		return -EINVAL;
 
@@ -483,8 +483,7 @@ static int tb_drom_copy_efi(struct tb_switch *sw, u16 *size)
 	if (res)
 		return res;
 
-	res = device_property_read_u8_array(dev, "ThunderboltDROM", sw->drom,
-									len);
+	res = device_property_read_u8_array(dev, name, sw->drom, len);
 	if (res)
 		goto err;
 
@@ -500,6 +499,22 @@ static int tb_drom_copy_efi(struct tb_switch *sw, u16 *size)
 	return -EINVAL;
 }
 
+/*
+ * tb_drom_copy_of_apple - copy drom supplied by the device tree for Apple Silicon to sw->drom.
+ */
+static int tb_drom_copy_of_apple(struct tb_switch *sw, u16 *size)
+{
+	return tb_drom_copy_property(sw, "apple,thunderbolt-drom", size);
+}
+
+/*
+ * tb_drom_copy_efi - copy drom supplied by EFI to sw->drom if present
+ */
+static int tb_drom_copy_efi(struct tb_switch *sw, u16 *size)
+{
+	return tb_drom_copy_property(sw, "ThunderboltDROM", size);
+}
+
 static int tb_drom_copy_nvm(struct tb_switch *sw, u16 *size)
 {
 	u16 drom_offset;
@@ -675,6 +690,13 @@ static int tb_drom_host_read(struct tb_switch *sw)
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

