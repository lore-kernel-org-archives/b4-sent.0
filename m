From: Nikita Travkin <nikita@trvn.ru>
Date: Wed, 03 Apr 2024 16:31:41 +0500
Subject: [PATCH v2 2/3] thermal: gov_power_allocator: Allow binding without
 trip points
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240403-gpa-no-cooling-devs-v2-2-79bdd8439449@trvn.ru>
References: <20240403-gpa-no-cooling-devs-v2-0-79bdd8439449@trvn.ru>
In-Reply-To: <20240403-gpa-no-cooling-devs-v2-0-79bdd8439449@trvn.ru>
To: Lukasz Luba <lukasz.luba@arm.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>
Cc: "Rafael J. Wysocki" <rafael.j.wysocki@intel.com>, 
 linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikita Travkin <nikitos.tr@gmail.com>, Nikita Travkin <nikita@trvn.ru>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2101; i=nikita@trvn.ru;
 h=from:subject:message-id; bh=aX3XyiCHA+n2cubW1L4ZLcOrqQkfy11LKyh/4X5tJVw=;
 b=owEBbQKS/ZANAwAIAUMc7O4oGb91AcsmYgBmDT7aDjJW3qq1rSoA7iBt+c+AS53Nu9qzgj6L+
 e0DzRUDI5yJAjMEAAEIAB0WIQTAhK9UUj+qg34uxUdDHOzuKBm/dQUCZg0+2gAKCRBDHOzuKBm/
 dcvlD/0VZ9HatTS7LP55/Kje6FO3xvMn0crj+CRHX3Z1csFoUDnlTFaJsyFONaS5LvROuIutiJK
 gObneneKf2549moPVUtubHdi/vHQTdf2MWmxxSjhqyh+cNskIQk8WoRDpYVPrPY1Vma8858G4fb
 uhtSt4ygEXqClScqki9DlizOcWv1qqy3yMPMG/qR/Mi5C+s8rky9kbXaeN57QODSqtweVGD9Egw
 x027zgNdA0z8Tge29DlydmPAug6dAXHNWcSzhge48pXUjyoDTxIqfbxZGcgyV8meRB2nMCJSjXp
 SpJzRltV4m1uMirSDvEpoTrMrjZ1FL4he3D/0iQEcpBkBJTXfJTHiWSmlvsF5y/MFeknm8k6esu
 /2sW2+sD+5YY7h1nf1gPY+rVp+RPh3f10tYGLFvpLaO+6EtOFDxWPeUJJi4OAz2MQNZJbGtA7Sm
 J9uor6qK1GdCY8NYd1aMFRQCk6yytDi/XAkOKCQxQUsqmTPg3R9deMGLwJL5Wu3H98n+2vlWiMP
 lAYXs5mseKe8PKi08v0eWBmXPSmYL8ooqmv2P4nkKAmb9tqSRM/CZWDcHvFDqMLlnjaXGUm1vEY
 Ovppz7SH/mDIs0uu4Se0Exvel+IKYx7GV/ZvxVBI2kfE4zb7PfVLLc9CePlsPv1uzPxD0s6qcrq
 cvLXDNfkIfKxeFg==
X-Developer-Key: i=nikita@trvn.ru; a=openpgp;
 fpr=C084AF54523FAA837E2EC547431CECEE2819BF75
X-Endpoint-Received: by B4 Relay for nikita@trvn.ru/default with auth_id=151
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IPA probe function was recently refactored to perform extra error checks
and make sure the thermal zone has trip points necessary for the IPA
operation. With this change, if a thermal zone is probed such that it
has no trip points that IPA can use, IPA will fail and the TZ won't be
created. This is the case if a platform defines a TZ without cooling
devices and only with "hot"/"critical" trip points, often found on some
Qualcomm devices [1].

Documentation across IPA code (notably get_governor_trips() kerneldoc)
suggests that IPA is supposed to handle such TZ even if it won't
actually do anything.

This commit partially reverts the previous change to allow IPA to bind
to such "empty" thermal zones.

[1] arch/arm64/boot/dts/qcom/sc7180.dtsi#n4776

Fixes: e83747c2f8e3 ("thermal: gov_power_allocator: Set up trip points earlier")
Signed-off-by: Nikita Travkin <nikita@trvn.ru>
---
 drivers/thermal/gov_power_allocator.c | 12 ++++--------
 1 file changed, 4 insertions(+), 8 deletions(-)

diff --git a/drivers/thermal/gov_power_allocator.c b/drivers/thermal/gov_power_allocator.c
index ec637071ef1f..e25e48d76aa7 100644
--- a/drivers/thermal/gov_power_allocator.c
+++ b/drivers/thermal/gov_power_allocator.c
@@ -679,11 +679,6 @@ static int power_allocator_bind(struct thermal_zone_device *tz)
 		return -ENOMEM;
 
 	get_governor_trips(tz, params);
-	if (!params->trip_max) {
-		dev_warn(&tz->device, "power_allocator: missing trip_max\n");
-		kfree(params);
-		return -EINVAL;
-	}
 
 	ret = check_power_actors(tz, params);
 	if (ret < 0) {
@@ -714,9 +709,10 @@ static int power_allocator_bind(struct thermal_zone_device *tz)
 	else
 		params->sustainable_power = tz->tzp->sustainable_power;
 
-	estimate_pid_constants(tz, tz->tzp->sustainable_power,
-			       params->trip_switch_on,
-			       params->trip_max->temperature);
+	if (params->trip_max)
+		estimate_pid_constants(tz, tz->tzp->sustainable_power,
+				       params->trip_switch_on,
+				       params->trip_max->temperature);
 
 	reset_pid_controller(params);
 

-- 
2.44.0

