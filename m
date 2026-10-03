From: Ryan Leung <untilscour@protonmail.com>
Date: Sat, 03 Oct 2026 04:19:35 +0000
Subject: [PATCH v5] wifi: mt76: mt7996: add thermal zone device
 registration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261003-mt7996-thermal-zone-v5-1-d7cf8820d187@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAFaCwGoC/43NTW6DMBQE4KtEXscVz4B/suo9qiyM/SiOAka2g
 5Ii7l6TLhKpKMpypJlvZhIxOIzksJtJwMlF54cc6v2OmE4P30idzZmwgvFCMEb7JJTiNHUYen2
 mP35AqsGiMA1YwSTJyzFg66539ev4l+OlOaFJK7U2OheTD7f77QRr7/XDBBSolFJx5KiUrD/H4
 JMfeu3OH8b3ZL2Z2AOSUGxDLEM1L23bNK0CsQ2Vb0BlhjQqK4zlxiJsQtUzBNtQlSFltIBaS43
 Q/oOWZfkFcdRSJqgBAAA=
X-Change-ID: 20260722-mt7996-thermal-zone-a1de7cb1d728
To: Felix Fietkau <nbd@nbd.name>, Lorenzo Bianconi <lorenzo@kernel.org>, 
 Ryder Lee <ryder.lee@mediatek.com>, Shayne Chen <shayne.chen@mediatek.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Ryan Leung <untilscour@protonmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791001188; l=5381;
 i=untilscour@protonmail.com; s=20260906; h=from:subject:message-id;
 bh=fkkK5Q5LKx/PoPRbymDj4AA3V5lC4TvI70nnngZ0TJE=;
 b=NiXnAIPCa4RbcUpzl+gogZMMUs52wxm6zZTbsasWrvGS6hHkyby99jbKhm1oFuA7pXtf6km/D
 45lvHq07gfXBSvqz22ocoj6eLetFbenuwB400DtCiopE5bxiOltib0/
X-Developer-Key: i=untilscour@protonmail.com; a=ed25519;
 pk=eCaNcoQNRWYKZ9D7KbOGKvQVK2YFguJXZxglTtAR7Xk=
X-Endpoint-Received: by B4 Relay for untilscour@protonmail.com/20260906 with auth_id=1011
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Register the mt7996 phy as a thermal zone sensor using
thermal_of_zone_register() so that device tree thermal-zones
nodes can reference the Wi-Fi chip as a temperature source. This
allows the kernel thermal governor to control external cooling
devices such as PWM fans based on Wi-Fi chip temperature.

Registration is non-fatal: -ENODEV is returned when no
thermal-sensors DT property references this device, which is the
expected case on platforms without a thermal zone configured.

Unregister the thermal zone together with the existing cooling device
when the phy is torn down, and on the hwmon registration failure path
in the same init routine, so neither is left registered against a phy
that is about to be freed. Clear both pointers after unregistering,
since this init-time failure path can now run before the normal
teardown path also unregisters the same phy, and without clearing them,
that second call would unregister already-freed objects.

Signed-off-by: Ryan Leung <untilscour@protonmail.com>
---
Changes in v5:
- Use non-devm thermal_of_zone_register() / thermal_of_zone_unregister()
  instead of devm: the zone's get_temp callback dereferences the phy, which
  is freed before the parent device devres teardown would run anyway,
  and the explicit teardown already needed for cdev makes devm redundant.
- Link to v4: https://patch.msgid.link/20260811-mt7996-thermal-zone-v4-1-9ca715a8ae1f@protonmail.com

Changes in v4:
- Clear phy->tzone/phy->cdev in mt7996_unregister_thermal() after
  unregistering, making it idempotent.
- Link to v3: https://patch.msgid.link/20260810-mt7996-thermal-zone-v3-1-ae9d7cd6cde1@protonmail.com

Changes in v3:
- Unwind cdev/tzone registration in mt7996_thermal_init() on hwmon registration failure.
- Link to v2: https://patch.msgid.link/20260810-mt7996-thermal-zone-v2-1-563dfbbf9175@protonmail.com

Changes in v2:
- Take phy->dev->mt76.mutex around mt7996_mcu_get_temperature()
- Unregister phy->tzone explicitly in mt7996_unregister_thermal() before the phy is freed
- Link to v1: https://patch.msgid.link/20260722-mt7996-thermal-zone-v1-1-88896e6e9985@protonmail.com
---
 drivers/net/wireless/mediatek/mt76/mt7996/init.c   | 40 +++++++++++++++++++++-
 drivers/net/wireless/mediatek/mt76/mt7996/mt7996.h |  1 +
 2 files changed, 40 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/mediatek/mt76/mt7996/init.c b/drivers/net/wireless/mediatek/mt76/mt7996/init.c
index fb635a092584..007ac129ddc0 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7996/init.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7996/init.c
@@ -234,17 +234,42 @@ static const struct thermal_cooling_device_ops mt7996_thermal_ops = {
 	.set_cur_state = mt7996_thermal_set_cur_throttle_state,
 };
 
+static int mt7996_thermal_get_temp(struct thermal_zone_device *tz, int *temp)
+{
+	struct mt7996_phy *phy = thermal_zone_device_priv(tz);
+	int val;
+
+	mutex_lock(&phy->dev->mt76.mutex);
+	val = mt7996_mcu_get_temperature(phy);
+	mutex_unlock(&phy->dev->mt76.mutex);
+	if (val < 0)
+		return val;
+
+	*temp = val * 1000;
+	return 0;
+}
+
+static const struct thermal_zone_device_ops mt7996_tz_ops = {
+	.get_temp = mt7996_thermal_get_temp,
+};
+
 static void mt7996_unregister_thermal(struct mt7996_phy *phy)
 {
 	struct wiphy *wiphy = phy->mt76->hw->wiphy;
 	char name[sizeof("cooling_deviceXXX")];
 
+	if (phy->tzone) {
+		thermal_of_zone_unregister(phy->tzone);
+		phy->tzone = NULL;
+	}
+
 	if (!phy->cdev)
 		return;
 
 	snprintf(name, sizeof(name), "cooling_device%d", phy->mt76->band_idx);
 	sysfs_remove_link(&wiphy->dev.kobj, name);
 	thermal_cooling_device_unregister(phy->cdev);
+	phy->cdev = NULL;
 }
 
 static int mt7996_thermal_init(struct mt7996_phy *phy)
@@ -275,14 +300,27 @@ static int mt7996_thermal_init(struct mt7996_phy *phy)
 	phy->throttle_temp[MT7996_CRIT_TEMP_IDX] = MT7996_CRIT_TEMP;
 	phy->throttle_temp[MT7996_MAX_TEMP_IDX] = MT7996_MAX_TEMP;
 
+	phy->tzone = thermal_of_zone_register(phy->dev->mt76.dev,
+					      phy->mt76->band_idx, phy,
+					      &mt7996_tz_ops);
+	if (IS_ERR(phy->tzone)) {
+		if (PTR_ERR(phy->tzone) != -ENODEV)
+			dev_warn(phy->dev->mt76.dev,
+				 "failed to register thermal zone %d: %ld\n",
+				 phy->mt76->band_idx, PTR_ERR(phy->tzone));
+		phy->tzone = NULL;
+	}
+
 	if (!IS_REACHABLE(CONFIG_HWMON))
 		return 0;
 
 	hwmon = devm_hwmon_device_register_with_groups(&wiphy->dev, name, phy,
 						       mt7996_hwmon_groups);
 
-	if (IS_ERR(hwmon))
+	if (IS_ERR(hwmon)) {
+		mt7996_unregister_thermal(phy);
 		return PTR_ERR(hwmon);
+	}
 
 	return 0;
 }
diff --git a/drivers/net/wireless/mediatek/mt76/mt7996/mt7996.h b/drivers/net/wireless/mediatek/mt76/mt7996/mt7996.h
index 2a0cdb56f822..39fa25a562e5 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7996/mt7996.h
+++ b/drivers/net/wireless/mediatek/mt76/mt7996/mt7996.h
@@ -372,6 +372,7 @@ struct mt7996_phy {
 
 	struct ieee80211_sband_iftype_data iftype[NUM_NL80211_BANDS][NUM_NL80211_IFTYPES];
 
+	struct thermal_zone_device *tzone;
 	struct thermal_cooling_device *cdev;
 	u8 cdev_state;
 	u8 throttle_state;

---
base-commit: f49defea7668d8c68ec19fa085ef3da6075561c7
change-id: 20260722-mt7996-thermal-zone-a1de7cb1d728

Best regards,
--  
Ryan Leung <untilscour@protonmail.com>

