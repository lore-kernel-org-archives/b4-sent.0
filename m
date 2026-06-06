From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 18:47:40 +1000
Subject: [PATCH 09/11] reboot-mode: reboot method activation support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-pm8916-pon-v1-9-170c9cbe5099@samcday.com>
References: <20260606-pm8916-pon-v1-0-170c9cbe5099@samcday.com>
In-Reply-To: <20260606-pm8916-pon-v1-0-170c9cbe5099@samcday.com>
To: u-boot@lists.denx.de, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, Peng Fan <peng.fan@nxp.com>, 
 Leo Yu-Chi Liang <ycliang@andestech.com>, Anshul Dalal <anshuld@ti.com>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Justin Klaassen <justin@tidylabs.net>, 
 Jamie Gibbons <jamie.gibbons@microchip.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Mateus Lima Alves <mateuslima.ti@gmail.com>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Ariel D'Alessandro <ariel.dalessandro@collabora.com>, 
 Dmitrii Merkurev <dimorinny@google.com>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780735669; l=2348;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=d6hNRTcjuOCe5Y5dKLR7z3oIjgEst648gdAhzCuHvx0=;
 b=cIre5IKMI7/rY/2w0xAl/6KcrF4SvOnWmSWpWluTR8AX4BMjvDOqVa5bUJBFruX/fpICOzFzu
 ssSuQwBW74iDb13BTTi2dFPsbqAQu48AsCzeU6yI083HVimWl8OOc8K
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Until now, the reboot-mode uclass didn't wire up a producer path to
allow arbitrary changes to the reboot mode. The current impl only uses
reboot_mode_ops->set to clear the reboot mode once it has been read at
boot-time.

The public API is expanded with a dm_reboot_mode_activate method, which
will instruct the given device to activate a particular reboot mode.

The first producer, `fastboot reboot`, will be introduced in the next
commit.

Signed-off-by: Sam Day <me@samcday.com>
---
 drivers/reboot-mode/reboot-mode-uclass.c | 18 ++++++++++++++++++
 include/reboot-mode/reboot-mode.h        | 12 ++++++++++++
 2 files changed, 30 insertions(+)

diff --git a/drivers/reboot-mode/reboot-mode-uclass.c b/drivers/reboot-mode/reboot-mode-uclass.c
index 7cbe02eb4ed..c47d11b681e 100644
--- a/drivers/reboot-mode/reboot-mode-uclass.c
+++ b/drivers/reboot-mode/reboot-mode-uclass.c
@@ -9,6 +9,24 @@
 #include <exports.h>
 #include <reboot-mode/reboot-mode.h>
 
+int dm_reboot_mode_activate(struct udevice *dev, const char *mode)
+{
+	struct reboot_mode_ops *ops = reboot_mode_get_ops(dev);
+	int i;
+	const struct reboot_mode_uclass_platdata *plat_data =
+		dev_get_uclass_plat(dev);
+
+	if (!ops || !ops->set)
+		return -ENOSYS;
+
+	for (i = 0; i < plat_data->count; i++) {
+		if (!strcmp(plat_data->modes[i].mode_name, mode))
+			return ops->set(dev, plat_data->modes[i].mode_id);
+	}
+
+	return -ENOENT;
+}
+
 int dm_reboot_mode_update(struct udevice *dev)
 {
 	struct reboot_mode_ops *ops = reboot_mode_get_ops(dev);
diff --git a/include/reboot-mode/reboot-mode.h b/include/reboot-mode/reboot-mode.h
index 5fbd7c801af..6510141ff89 100644
--- a/include/reboot-mode/reboot-mode.h
+++ b/include/reboot-mode/reboot-mode.h
@@ -53,4 +53,16 @@ struct reboot_mode_ops {
  */
 int dm_reboot_mode_update(struct udevice *dev);
 
+/**
+ * dm_reboot_mode_activate() - activate a reboot mode by name
+ *
+ * This will read the given @dev plat_data for a named mode, and write the
+ * magic value for that mode to the device.
+ *
+ * @dev Device to write reboot magic to
+ * @mode name of the mode to lookup for magic value
+ * Return: 0 on success, -ve on error
+ */
+int dm_reboot_mode_activate(struct udevice *dev, const char *mode);
+
 #endif /* REBOOT_MODE_REBOOT_MODE_H__ */

-- 
2.54.0

