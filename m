From: Nikita Travkin <nikita@trvn.ru>
Date: Wed, 03 Apr 2024 16:31:40 +0500
Subject: [PATCH v2 1/3] thermal: gov_power_allocator: Allow binding without
 cooling devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240403-gpa-no-cooling-devs-v2-1-79bdd8439449@trvn.ru>
References: <20240403-gpa-no-cooling-devs-v2-0-79bdd8439449@trvn.ru>
In-Reply-To: <20240403-gpa-no-cooling-devs-v2-0-79bdd8439449@trvn.ru>
To: Lukasz Luba <lukasz.luba@arm.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>
Cc: "Rafael J. Wysocki" <rafael.j.wysocki@intel.com>, 
 linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikita Travkin <nikitos.tr@gmail.com>, Nikita Travkin <nikita@trvn.ru>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1265; i=nikita@trvn.ru;
 h=from:subject:message-id; bh=JaFVxsb39ZVmN8wxFQAGbfSwFLxid+4cjStl8B0OjYU=;
 b=owEBbQKS/ZANAwAIAUMc7O4oGb91AcsmYgBmDT7ayj71lCR3yKHW00w225BagKD45KIyeK4Zo
 Nv9WOzvxBmJAjMEAAEIAB0WIQTAhK9UUj+qg34uxUdDHOzuKBm/dQUCZg0+2gAKCRBDHOzuKBm/
 dT67D/9Y1rHlBY/kqI+8fIkl2IAGpkr14cQ8CMjProFR1nblh9duMXXVUlJ3kJPEwfyiBVueb3z
 OqcICS2efrky3ton7DizOwYuGNd6MuOHuk21GPsIJNOq2JbBehC8zwVI3ipFO0YrDkjhXPsh5MJ
 xv+ASjjpMSMjA0luUNfNrc1CdsCrf0JBNRI3vuiNU9Qcb7oCD8vaZaMj8x4oIbcyuODKQvMZudE
 fG0d6sSaXtHq7GOee+I9h9K8mQGawxUlISRmWT9/tSDkge5xb3p9ZjItxaAyvNaon2/cOZiGhUf
 +vfdhWkvpaDjhoIh7jHbuTFdWJgcHexIpqkUhw+5/rYMr+xOnecukNB6eaSfssF1NwBe+Cg4U6f
 Ai/zwuJP96XX7hgQ69twdM+VWDVKTLjzoVycefjdSLc+jsK4tIyiqOx9ZITQK+e3lVQiLmZFz+j
 Wtd5UXDRRH6Ehf1BjokhS6IhQYFegT5q6NFi3qANv8WRsP7MWVnirYkiA7pXpNe3WELEUt5lfCe
 YiREDoGWS+gUmQbCJFv3vHDI+bT6S9n2PP2dr99NZW1amGh7w6heLAfPAAmN5QI2KwOLVclObW9
 cylBhpIRiVC9a1Wo3jxsx2Ow+J4mYfY8MAJVo6pWw0MUZ428VY2MZoQmCHAJJsN4h8TRoccukM+
 lD2vYzImEvAt0DQ==
X-Developer-Key: i=nikita@trvn.ru; a=openpgp;
 fpr=C084AF54523FAA837E2EC547431CECEE2819BF75
X-Endpoint-Received: by B4 Relay for nikita@trvn.ru/default with auth_id=151
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IPA was recently refactored to split out memory allocation into a
separate funciton. That funciton was made to return -EINVAL if there is
zero power_actors and thus no memory to allocate. This causes IPA to
fail probing when the thermal zone has no attached cooling devices.

Since cooling devices can attach after the thermal zone is created and
the governer is attached to it, failing probe due to the lack of cooling
devices is incorrect.

Change the allocate_actors_buffer() to return success when there is no
cooling devices present.

Fixes: 912e97c67cc3 ("thermal: gov_power_allocator: Move memory allocation out of throttle()")
Signed-off-by: Nikita Travkin <nikita@trvn.ru>
---
 drivers/thermal/gov_power_allocator.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/thermal/gov_power_allocator.c b/drivers/thermal/gov_power_allocator.c
index 1b17dc4c219c..ec637071ef1f 100644
--- a/drivers/thermal/gov_power_allocator.c
+++ b/drivers/thermal/gov_power_allocator.c
@@ -606,7 +606,7 @@ static int allocate_actors_buffer(struct power_allocator_params *params,
 
 	/* There might be no cooling devices yet. */
 	if (!num_actors) {
-		ret = -EINVAL;
+		ret = 0;
 		goto clean_state;
 	}
 

-- 
2.44.0

