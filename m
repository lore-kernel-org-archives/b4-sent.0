From: Vincent Jardin <vjardin@free.fr>
Date: Thu, 23 Jul 2026 17:44:56 +0200
Subject: [PATCH] hwmon: (pmbus/core) notify on the hwmon device, not the
 i2c client
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-fix_hwmon_notify_v1-v1-1-5a24c528686d@free.fr>
X-B4-Tracking: v=1; b=H4sIAPc2YmoC/x2MQQqAIBAAvyJ7TlCTpL4SIVFb7iENDSuivycdB
 2bmgYSRMEHHHoiYKVHwBWTFYHKjX5HTXBiUUI0wquYLXdadW/DWh4OW22bJjUY5trrWzSShlHv
 Eov3XfnjfD7qlFTdlAAAA
To: Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784821501; l=1985;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=mvBVaQ/t9TqovxzoIusrFozS/2VXRXLUOR6BEPoWm7A=;
 b=GOwMDFU2EGh4zEkApIoHvh9my2mZaaEDWVKHquKMgbTaCoC9rXGKANGnvQfBbCdPJ6sM0YrCR
 T6H4mq8FnABD1ab9+ILw0N2+RNSYyO8SORzscKRW7XbcD8AD55Oza5J
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pmbus_notify() calls sysfs_notify() and kobject_uevent() on the i2c
client's kobject, but the alarm attributes live on the hwmon class
device registered by pmbus_do_probe(). Notifying the parent i2c device
is a no-op for both poll(POLLPRI) waiters and udev listeners: the named
attribute does not exist on that kobject.

Notify the hwmon device instead, so poll() wakes up and "change"
uevents fire on the inX_alarm/tempX_alarm attributes when SMBALERT#
reports a fault.

Fixes: f469bde9afd1 ("hwmon: (pmbus/core) Notify hwmon events")
Cc: stable@vger.kernel.org # v6.4+
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Found during the review of the MPQ8646 series (v1):

  https://lore.kernel.org/all/20260723131352.182B61F000E9@smtp.kernel.org/

The sysfs_notify() half is a no-op today: the named attribute does not
exist on the i2c client's kobject. Note the KOBJ_CHANGE uevent source
moves from the i2c device to the hwmon class device, matching what
hwmon_notify_event() does.
---
 drivers/hwmon/pmbus/pmbus_core.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/hwmon/pmbus/pmbus_core.c b/drivers/hwmon/pmbus/pmbus_core.c
index 3143b9e0316c..0081f16c3a95 100644
--- a/drivers/hwmon/pmbus/pmbus_core.c
+++ b/drivers/hwmon/pmbus/pmbus_core.c
@@ -2985,8 +2985,9 @@ static void pmbus_notify(struct pmbus_data *data, int page, int reg, int flags)
 
 		if (reg == sreg && page == spage && (smask & flags)) {
 			dev_dbg(data->dev, "sysfs notify: %s", da->attr.name);
-			sysfs_notify(&data->dev->kobj, NULL, da->attr.name);
-			kobject_uevent(&data->dev->kobj, KOBJ_CHANGE);
+			sysfs_notify(&data->hwmon_dev->kobj, NULL,
+				     da->attr.name);
+			kobject_uevent(&data->hwmon_dev->kobj, KOBJ_CHANGE);
 			flags &= ~smask;
 		}
 

---
base-commit: 248951ddc14de84de3910f9b13f51491a8cd91df
change-id: 20260723-fix_hwmon_notify_v1-74e1a94346c1

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

