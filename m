From: Nikita Travkin <nikita@trvn.ru>
Date: Wed, 03 Apr 2024 16:31:42 +0500
Subject: [PATCH v2 3/3] thermal: gov_power_allocator: Suppress
 sustainable_power warning without trip_points
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240403-gpa-no-cooling-devs-v2-3-79bdd8439449@trvn.ru>
References: <20240403-gpa-no-cooling-devs-v2-0-79bdd8439449@trvn.ru>
In-Reply-To: <20240403-gpa-no-cooling-devs-v2-0-79bdd8439449@trvn.ru>
To: Lukasz Luba <lukasz.luba@arm.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>
Cc: "Rafael J. Wysocki" <rafael.j.wysocki@intel.com>, 
 linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikita Travkin <nikitos.tr@gmail.com>, Nikita Travkin <nikita@trvn.ru>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1262; i=nikita@trvn.ru;
 h=from:subject:message-id; bh=gQ/lCJyqNkEYXe64V1azuLWqhZDrPtWfWIzY6a+krrM=;
 b=owEBbQKS/ZANAwAIAUMc7O4oGb91AcsmYgBmDT7a1s4sHI60htO7JPYtLc7eKRvDv6ApO1t84
 n+JQrinvFmJAjMEAAEIAB0WIQTAhK9UUj+qg34uxUdDHOzuKBm/dQUCZg0+2gAKCRBDHOzuKBm/
 damjD/9nikGP8u0SyJYkb8/hRI+pmOTDJA6BZr9vFr3xFe9n8VUXi/uAQCG6N6g0/DMZZe1wHwD
 n7SObRXMQBQ8p6G7XxIbkEKqVyQgczzrt2q878TJ9utGt9JTGSlSKKVnslumOQ5brXm9Ykywd9D
 S+O4JveQ5TS1yFPEb4y9G/Y9BmP/URNMt2Y1smsu4E7PwbfFylfM/UUv30MhfXMK62wgQ9lecmf
 lj4KPmxY0DkmV5LTOZDB0WLz75bHQ/7z2ubYtv8FCZJHyZjIVeWCjr7XxDz7fmb2tZc1nmuEZAG
 zdSWk2wr3i/4kc2CY9FTNzqJ9Go6cLlWvMB7xNp7rx8oCSo4YBE/ifUVGncff3gVgTx96HmdyBR
 r3StSRE0Ss8Iz6Clwsi0bexqXEMJWDBryOIuu4h38WVUshRaYP/XAam/9bfWaPiad8CeIVGx+Eg
 RrgzNMB4AyKLeWqUjNwWQwoz7NQQXr1rcB/bIx2JY8T7MGlCdgTKNwjIfRGXna44VmTDwmFClpo
 77Nx6AAFdDkHjdpTCSEpzgvT+9i1p9kgfFEPK+tSDZn5bGu68pMmzJjlVmRb0TUWjxBpqn9cYmb
 gmbdl/egKr5zgMwp2p32obMQq9/w2kMubA2wXhBBHKPWu3iJy8m8A10uMbm9AAJJj6fxinf7NX8
 pL7h1RbIlz0xjtw==
X-Developer-Key: i=nikita@trvn.ru; a=openpgp;
 fpr=C084AF54523FAA837E2EC547431CECEE2819BF75
X-Endpoint-Received: by B4 Relay for nikita@trvn.ru/default with auth_id=151
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IPA warns if the thermal zone it was attached to doesn't define
sustainable_power value. In some cases though IPA may be bound to an
"empty" TZ, in which case the lack of sustainable_power doesn't matter.

Suppress the warning in case when IPA is bound to an empty TZ to make it
easier to see the warnings that actually matter.

Signed-off-by: Nikita Travkin <nikita@trvn.ru>
---

I've decided to add this along to supress those warnings for some TZ on
sc7180. Feel free to drop this patch if you think the warning should
always appear.
---
 drivers/thermal/gov_power_allocator.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/thermal/gov_power_allocator.c b/drivers/thermal/gov_power_allocator.c
index e25e48d76aa7..05a40f6b5928 100644
--- a/drivers/thermal/gov_power_allocator.c
+++ b/drivers/thermal/gov_power_allocator.c
@@ -704,7 +704,7 @@ static int power_allocator_bind(struct thermal_zone_device *tz)
 		params->allocated_tzp = true;
 	}
 
-	if (!tz->tzp->sustainable_power)
+	if (!tz->tzp->sustainable_power && params->trip_max)
 		dev_warn(&tz->device, "power_allocator: sustainable_power will be estimated\n");
 	else
 		params->sustainable_power = tz->tzp->sustainable_power;

-- 
2.44.0

