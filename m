From: Miao Wang <shankerwangmiao@gmail.com>
Date: Mon, 10 Aug 2026 21:04:29 +0800
Subject: [PATCH RFC v8 6/8] gpiolib: add gpio_device_get_fwnode() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-ls2kbmc-mod-v8-6-16e44f7322f4@gmail.com>
References: <20260810-ls2kbmc-mod-v8-0-16e44f7322f4@gmail.com>
In-Reply-To: <20260810-ls2kbmc-mod-v8-0-16e44f7322f4@gmail.com>
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 Chong Qiao <qiaochong@loongson.cn>, Lee Jones <lee@kernel.org>, 
 Huacai Chen <chenhuacai@kernel.org>, Corey Minyard <corey@minyard.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: Xi Ruoyao <xry111@xry111.site>, WANG Xuerui <kernel@xen0n.name>, 
 Yinbo Zhu <zhuyinbo@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, openipmi-developer@lists.sourceforge.net, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1908;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=TZFM28+jBaBa8iuXdlwWyQ1gE02lWVl9BRxh0Scrj4Y=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqecxjlULkZ4X60g/XRmeS6crNRMHWhmHGqiM9v
 wse6/LGD+GJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCannMYwAKCRCwMePKe/7Z
 bkqgD/4x7yxBnYVahId7LUwoDFHlX2WIvHFRTnXw38UTrnQrsXkL4SrKdCVzVzMY6/UfIcWwAq4
 I4QG4cP80i17VpuGzgCtk9df2eVcAHJnpbHlAKxgvMDkgSJi0bAlbjdgAzI5s/VdTcN1tPOUuUJ
 n4SFznBarVBxEKC2r7RctqTKxr+bruVbprr38P5VlMcJwOgw6l6+MVcMnntjQOcdcNhdPZc1g1a
 hLvMOiLOx1IEw+c28F5HJNrk4HTOjVEDMosi6f3DjdPxIzuujg9krS51kUuWTMtuI6L6kLCnWiE
 P8XNN5jSJ5yMZvTTam4GUMhFH3zUuGPMuQMwY9sEQdOe4AsIjFvvftLLQB+zmQuDelk3cWKbmtI
 vfKiTl+DD8qtKgRigjO/1dMctfBPij2+rrM9dnHKvj4Oe5jOy+mbD4OvKUiM7M4pWkziyjjYQjn
 HqGlDtUYeishnaif1tF3hnqDHXXlqWwKY1MjEfqdjw15DP7KGN45kIady26WI90oPXUlAmpA5Mi
 BKW+t8ptSbwy/yeTXlAVGN2EqFena4xZIPy40CkDMkNjCXbx3zQeh4f7Xfxoht0FmkzFRsHzWSO
 qBrR1qditRMfg1VvO8wpt+iZsMsWeN/TdmKRu2s8J+k2Xh2eYFBjPdK/GKHvXjktBjUYWzlgZjG
 OSxA7CxT185DOYg==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a helper function to retrieve the fwnode associated with a
struct gpio_device. This is useful for drivers that need to access the
fwnode of a GPIO device for various purposes, such as creating software
nodes or handling GPIOs in a platform-specific manner.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/gpio/gpiolib.c      | 13 +++++++++++++
 include/linux/gpio/driver.h |  1 +
 2 files changed, 14 insertions(+)

diff --git a/drivers/gpio/gpiolib.c b/drivers/gpio/gpiolib.c
index e5fb60111151f6de20b424551acf213fb058e190..3774ebbbe550cdce0989a2d06f2ab658529c3bab 100644
--- a/drivers/gpio/gpiolib.c
+++ b/drivers/gpio/gpiolib.c
@@ -1583,6 +1583,19 @@ struct device *gpio_device_to_device(struct gpio_device *gdev)
 }
 EXPORT_SYMBOL_GPL(gpio_device_to_device);
 
+/**
+ * gpio_device_get_fwnode() - Retrieve the fwnode of the underlying device.
+ * @gdev: GPIO device for which to return the fwnode.
+ *
+ * Returns:
+ * The fwnode handle of the underlying device.
+ */
+struct fwnode_handle *gpio_device_get_fwnode(struct gpio_device *gdev)
+{
+	return dev_fwnode(gpio_device_to_device(gdev));
+}
+EXPORT_SYMBOL_GPL(gpio_device_get_fwnode);
+
 #ifdef CONFIG_GPIOLIB_IRQCHIP
 
 /*
diff --git a/include/linux/gpio/driver.h b/include/linux/gpio/driver.h
index 17511434ed077dde8807bd7630c342e146e5230b..4dd9120707ec72a978f5f916cc5473a91b65d2b9 100644
--- a/include/linux/gpio/driver.h
+++ b/include/linux/gpio/driver.h
@@ -641,6 +641,7 @@ DEFINE_FREE(gpio_device_put, struct gpio_device *,
 	    if (!IS_ERR_OR_NULL(_T)) gpio_device_put(_T))
 
 struct device *gpio_device_to_device(struct gpio_device *gdev);
+struct fwnode_handle *gpio_device_get_fwnode(struct gpio_device *gdev);
 
 bool gpiochip_line_is_irq(struct gpio_chip *gc, unsigned int offset);
 int gpiochip_reqres_irq(struct gpio_chip *gc, unsigned int offset);

-- 
2.49.0

