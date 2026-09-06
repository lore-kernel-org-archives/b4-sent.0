From: Ryan Leung <untilscour@protonmail.com>
Date: Sun, 06 Sep 2026 21:42:06 +0000
Subject: [PATCH mt76 v3] wifi: mt76: mt7915: fix thermal zone
 use-after-free and cooling device leak
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-mt7915-unregister-thermal-v3-1-efb2d06e61f4@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAC3enWoC/42OQQ6DIBBFr2JYlwawIHbVezRdII5Ko2AATRvj3
 Yu6bNJ0+Sf/vzcLCuANBHTNFuRhNsE4m0J+ypDulG0BmzplxAgTRJISD7EoKceT9dCaEMHj2IE
 fVI8lA0m4FlQqgdJ+9NCY186+ozQT6HFcw1Q9QccNu/W6hHH+vb8w07192Cj5YZsppliLmhfVR
 Ve5kLfRu+jsoEx/1m7YZTP7G8cSjinScKrqhovmC7eu6wdbFVLDLgEAAA==
X-Change-ID: 20260809-mt7915-unregister-thermal-82e805c618a6
To: Felix Fietkau <nbd@nbd.name>, Lorenzo Bianconi <lorenzo@kernel.org>, 
 Ryder Lee <ryder.lee@mediatek.com>, Shayne Chen <shayne.chen@mediatek.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Ryan Leung <untilscour@protonmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788730934; l=3446;
 i=untilscour@protonmail.com; s=20260906; h=from:subject:message-id;
 bh=jg+VrZXwazJVrct69E59ekan8eJXBrNoBIRKgj68l10=;
 b=x0FHS3zeNHr8A2J5GkukmZc+dv0Tf0y/xb73NXQoLHXl+rMbmkLv3Ip73CTp8uRdJ87MOUzDI
 6LOHGLHUKcRBQjZ36TG1u1kk3G9PC4jq4R2mfU36LyzCQZS0BvQnaVt
X-Developer-Key: i=untilscour@protonmail.com; a=ed25519;
 pk=eCaNcoQNRWYKZ9D7KbOGKvQVK2YFguJXZxglTtAR7Xk=
X-Endpoint-Received: by B4 Relay for untilscour@protonmail.com/20260906 with auth_id=1011
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The thermal zone registered against the parent device is never torn
down when the phy is unregistered, so it can still be dereferenced
by the thermal core after the phy is freed. The thermal zone and
cooling device are also left registered if a later hwmon
registration step fails during init, leaking both.

Unregister the thermal zone alongside the cooling device on both the
regular unregister path and the init failure path. Also clear
phy->tzone and phy->cdev after unregistering so that a future caller
invoking the function twice doesn't unregister already-freed objects.

While at it, include the band index in the thermal zone registration
warning to help identify which band failed on multi-band chips.

Fixes: 313f1a27ebcb ("wifi: mt76: mt7915: add thermal zone device registration")
Signed-off-by: Ryan Leung <untilscour@protonmail.com>
---
Changes in v3:
- Clear phy->tzone/phy->cdev in mt7915_unregister_thermal() after
  unregistering, making it idempotent.
- Link to v2: https://patch.msgid.link/20260810-mt7915-unregister-thermal-v2-1-2a0f51adf56f@protonmail.com

Changes in v2:
- Unwind cdev/tzone registration in mt7915_thermal_init() on hwmon registration failure.
- Link to v1: https://patch.msgid.link/20260810-mt7915-unregister-thermal-v1-1-c6d57b4cb368@protonmail.com
---
 drivers/net/wireless/mediatek/mt76/mt7915/init.c | 17 ++++++++++++++---
 1 file changed, 14 insertions(+), 3 deletions(-)

diff --git a/drivers/net/wireless/mediatek/mt76/mt7915/init.c b/drivers/net/wireless/mediatek/mt76/mt7915/init.c
index ca46a203aa48..e5285d1a1f9d 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7915/init.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7915/init.c
@@ -200,11 +200,17 @@ static void mt7915_unregister_thermal(struct mt7915_phy *phy)
 {
 	struct wiphy *wiphy = phy->mt76->hw->wiphy;
 
+	if (phy->tzone) {
+		devm_thermal_of_zone_unregister(phy->dev->mt76.dev, phy->tzone);
+		phy->tzone = NULL;
+	}
+
 	if (!phy->cdev)
 		return;
 
 	sysfs_remove_link(&wiphy->dev.kobj, "cooling_device");
 	thermal_cooling_device_unregister(phy->cdev);
+	phy->cdev = NULL;
 }
 
 static int mt7915_thermal_init(struct mt7915_phy *phy)
@@ -213,6 +219,7 @@ static int mt7915_thermal_init(struct mt7915_phy *phy)
 	struct thermal_cooling_device *cdev;
 	struct device *hwmon;
 	const char *name;
+	int ret;
 
 	name = devm_kasprintf(&wiphy->dev, GFP_KERNEL, "mt7915_%s",
 			      wiphy_name(wiphy));
@@ -238,8 +245,8 @@ static int mt7915_thermal_init(struct mt7915_phy *phy)
 	if (IS_ERR(phy->tzone)) {
 		if (PTR_ERR(phy->tzone) != -ENODEV)
 			dev_warn(phy->dev->mt76.dev,
-				 "failed to register thermal zone: %ld\n",
-				 PTR_ERR(phy->tzone));
+				 "failed to register thermal zone %d: %ld\n",
+				 phy->mt76->band_idx, PTR_ERR(phy->tzone));
 		phy->tzone = NULL;
 	}
 
@@ -248,7 +255,11 @@ static int mt7915_thermal_init(struct mt7915_phy *phy)
 
 	hwmon = devm_hwmon_device_register_with_groups(&wiphy->dev, name, phy,
 						       mt7915_hwmon_groups);
-	return PTR_ERR_OR_ZERO(hwmon);
+	ret = PTR_ERR_OR_ZERO(hwmon);
+	if (ret)
+		mt7915_unregister_thermal(phy);
+
+	return ret;
 }
 
 static void mt7915_led_set_config(struct led_classdev *led_cdev,

---
base-commit: 1b60ed34f712e9f606d80951f1586f4274ebadf1
change-id: 20260809-mt7915-unregister-thermal-82e805c618a6

Best regards,
--  
Ryan Leung <untilscour@protonmail.com>

