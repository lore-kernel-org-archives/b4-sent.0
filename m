From: Kim Wooseok <5mghybrid@khu.ac.kr>
Date: Sat, 10 Oct 2026 07:39:16 +0900
Subject: [PATCH rtw-next] wifi: rtl8xxxu: isolate the USB register buffer
 from CPU state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-rtl8xxxu-usb-dma-v1-1-e670d9c08fdf@khu.ac.kr>
References: <20261010-rtl8xxxu-usb-dma-v1-0-e670d9c08fdf@khu.ac.kr>
In-Reply-To: <20261010-rtl8xxxu-usb-dma-v1-0-e670d9c08fdf@khu.ac.kr>
To: linux-wireless@vger.kernel.org
Cc: Jes Sorensen <Jes.Sorensen@gmail.com>, 
 Ping-Ke Shih <pkshih@realtek.com>, Kalle Valo <kvalo@kernel.org>, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Kim Wooseok <5mghybrid@khu.ac.kr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791585555; l=6582;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=Fi20EesCIFYA7ua1Pp4uDWX7+NVtPGKW8peZdq6hLUg=;
 b=n+8LSkIk2agDhFBlGXKpX59k2qz4XvGl7QMwma21+f0UECjyfyC/fqMQiBBDq81GFIi1VwXHB
 Ehu3grWBmHiB2MMtGih/c3iVlu2DJoVWPMzLZZ/jZwDdIramfKYuCKJ
X-Developer-Key: i=5mghybrid@khu.ac.kr; a=ed25519;
 pk=1az/6lC8Tmd6BcvyarPc8FWoSxsV/WRr5NLs1v+kjlE=
X-Endpoint-Received: by B4 Relay for 5mghybrid@khu.ac.kr/kernel-20260913 with auth_id=1028
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An RTL8192EU failed to reconnect on a Raspberry Pi after an AP power
cycle. RF_MODE contained a corrupted value, and restoring its initialized
value restored reception.

The register access helpers pass usb_buf directly to usb_control_msg(),
but the buffer is embedded next to usb_buf_mutex. On the affected Pi,
it shares a cache line with the mutex's waiter state. A contending task
updates that state while the USB transfer uses the buffer. This violates
the cache-line isolation required for non-coherent DMA.

Allocate the buffer once in probe and reuse it, avoiding an allocation
for every register access. Keep the existing register access helpers and
mutex protection. Free the buffer on probe failure and after power_off()
in disconnect, since shutdown still uses the register access helpers.

Fixes: 26f1fad29ad9 ("New driver: rtl8xxxu (mac80211)")
Cc: stable@vger.kernel.org
Signed-off-by: Kim Wooseok <5mghybrid@khu.ac.kr>
---
I tested the separate-buffer approach on an RTL8192EU connected to a
Raspberry Pi 5, using the existing Linux 6.18.34 kernel. While repeatedly
requesting scans, wireless ping traffic kept receiving replies and the
RF_MODE and HSSI register values remained stable.

The submission is based on rtw-next. An ARM64 build of the rtl8xxxu
driver with W=1 completed without warnings, and sparse reported no
diagnostics in core.c.
---
 drivers/net/wireless/realtek/rtl8xxxu/core.c     | 35 ++++++++++++++++--------
 drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h |  2 +-
 2 files changed, 24 insertions(+), 13 deletions(-)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index 3d0c22db3..604bb1e5b 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/core.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/core.c
@@ -622,9 +622,9 @@ u8 rtl8xxxu_read8(struct rtl8xxxu_priv *priv, u16 addr)
 	mutex_lock(&priv->usb_buf_mutex);
 	len = usb_control_msg(udev, usb_rcvctrlpipe(udev, 0),
 			      REALTEK_USB_CMD_REQ, REALTEK_USB_READ,
-			      addr, 0, &priv->usb_buf.val8, sizeof(u8),
+			      addr, 0, &priv->usb_buf->val8, sizeof(u8),
 			      RTW_USB_CONTROL_MSG_TIMEOUT);
-	data = priv->usb_buf.val8;
+	data = priv->usb_buf->val8;
 	mutex_unlock(&priv->usb_buf_mutex);
 
 	if (rtl8xxxu_debug & RTL8XXXU_DEBUG_REG_READ)
@@ -645,9 +645,9 @@ u16 rtl8xxxu_read16(struct rtl8xxxu_priv *priv, u16 addr)
 	mutex_lock(&priv->usb_buf_mutex);
 	len = usb_control_msg(udev, usb_rcvctrlpipe(udev, 0),
 			      REALTEK_USB_CMD_REQ, REALTEK_USB_READ,
-			      addr, 0, &priv->usb_buf.val16, sizeof(u16),
+			      addr, 0, &priv->usb_buf->val16, sizeof(u16),
 			      RTW_USB_CONTROL_MSG_TIMEOUT);
-	data = le16_to_cpu(priv->usb_buf.val16);
+	data = le16_to_cpu(priv->usb_buf->val16);
 	mutex_unlock(&priv->usb_buf_mutex);
 
 	if (rtl8xxxu_debug & RTL8XXXU_DEBUG_REG_READ)
@@ -668,9 +668,9 @@ u32 rtl8xxxu_read32(struct rtl8xxxu_priv *priv, u16 addr)
 	mutex_lock(&priv->usb_buf_mutex);
 	len = usb_control_msg(udev, usb_rcvctrlpipe(udev, 0),
 			      REALTEK_USB_CMD_REQ, REALTEK_USB_READ,
-			      addr, 0, &priv->usb_buf.val32, sizeof(u32),
+			      addr, 0, &priv->usb_buf->val32, sizeof(u32),
 			      RTW_USB_CONTROL_MSG_TIMEOUT);
-	data = le32_to_cpu(priv->usb_buf.val32);
+	data = le32_to_cpu(priv->usb_buf->val32);
 	mutex_unlock(&priv->usb_buf_mutex);
 
 	if (rtl8xxxu_debug & RTL8XXXU_DEBUG_REG_READ)
@@ -688,10 +688,10 @@ int rtl8xxxu_write8(struct rtl8xxxu_priv *priv, u16 addr, u8 val)
 		addr |= 0x8000;
 
 	mutex_lock(&priv->usb_buf_mutex);
-	priv->usb_buf.val8 = val;
+	priv->usb_buf->val8 = val;
 	ret = usb_control_msg(udev, usb_sndctrlpipe(udev, 0),
 			      REALTEK_USB_CMD_REQ, REALTEK_USB_WRITE,
-			      addr, 0, &priv->usb_buf.val8, sizeof(u8),
+			      addr, 0, &priv->usb_buf->val8, sizeof(u8),
 			      RTW_USB_CONTROL_MSG_TIMEOUT);
 
 	mutex_unlock(&priv->usb_buf_mutex);
@@ -711,10 +711,10 @@ int rtl8xxxu_write16(struct rtl8xxxu_priv *priv, u16 addr, u16 val)
 		addr |= 0x8000;
 
 	mutex_lock(&priv->usb_buf_mutex);
-	priv->usb_buf.val16 = cpu_to_le16(val);
+	priv->usb_buf->val16 = cpu_to_le16(val);
 	ret = usb_control_msg(udev, usb_sndctrlpipe(udev, 0),
 			      REALTEK_USB_CMD_REQ, REALTEK_USB_WRITE,
-			      addr, 0, &priv->usb_buf.val16, sizeof(u16),
+			      addr, 0, &priv->usb_buf->val16, sizeof(u16),
 			      RTW_USB_CONTROL_MSG_TIMEOUT);
 	mutex_unlock(&priv->usb_buf_mutex);
 
@@ -733,10 +733,10 @@ int rtl8xxxu_write32(struct rtl8xxxu_priv *priv, u16 addr, u32 val)
 		addr |= 0x8000;
 
 	mutex_lock(&priv->usb_buf_mutex);
-	priv->usb_buf.val32 = cpu_to_le32(val);
+	priv->usb_buf->val32 = cpu_to_le32(val);
 	ret = usb_control_msg(udev, usb_sndctrlpipe(udev, 0),
 			      REALTEK_USB_CMD_REQ, REALTEK_USB_WRITE,
-			      addr, 0, &priv->usb_buf.val32, sizeof(u32),
+			      addr, 0, &priv->usb_buf->val32, sizeof(u32),
 			      RTW_USB_CONTROL_MSG_TIMEOUT);
 	mutex_unlock(&priv->usb_buf_mutex);
 
@@ -7851,6 +7851,13 @@ static int rtl8xxxu_probe(struct usb_interface *interface,
 
 	usb_set_intfdata(interface, hw);
 
+	/* Keep the USB register buffer separate from driver state. */
+	priv->usb_buf = kzalloc_obj(*priv->usb_buf);
+	if (!priv->usb_buf) {
+		ret = -ENOMEM;
+		goto err_set_intfdata;
+	}
+
 	ret = rtl8xxxu_parse_usb(priv, interface);
 	if (ret)
 		goto err_set_intfdata;
@@ -7971,7 +7978,9 @@ static int rtl8xxxu_probe(struct usb_interface *interface,
 err_set_intfdata:
 	usb_set_intfdata(interface, NULL);
 
+	kfree(priv->usb_buf);
 	kfree(priv->fw_data);
+
 	mutex_destroy(&priv->usb_buf_mutex);
 	mutex_destroy(&priv->syson_indirect_access_mutex);
 	mutex_destroy(&priv->h2c_mutex);
@@ -7999,7 +8008,9 @@ static void rtl8xxxu_disconnect(struct usb_interface *interface)
 
 	dev_info(&priv->udev->dev, "disconnecting\n");
 
+	kfree(priv->usb_buf);
 	kfree(priv->fw_data);
+
 	mutex_destroy(&priv->usb_buf_mutex);
 	mutex_destroy(&priv->syson_indirect_access_mutex);
 	mutex_destroy(&priv->h2c_mutex);
diff --git a/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h b/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
index c6953051d..8cbadcf71 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
+++ b/drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h
@@ -1891,7 +1891,7 @@ struct rtl8xxxu_priv {
 		__le32 val32;
 		__le16 val16;
 		u8 val8;
-	} usb_buf;
+	} *usb_buf;
 	union {
 		u8 raw[EFUSE_MAP_LEN];
 		struct rtl8723au_efuse efuse8723;

-- 
2.53.0

