From: Penkacelsus <balthasar978@gmail.com>
Date: Tue, 20 Oct 2026 10:58:41 +0000
Subject: [PATCH] ACPI: SBS: Serialize battery state refreshes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-acpi-sbs-serialize-v1-1-913abf8ed30c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5EQBBA4atIraeS1n7CXGUyi1YKJWKky4gQd
 9dYfov3dlD2wgrvaAfPi6j8xoD4FQF1bmwZpQ4Ga2weG2vQ0SSoleIVukE2xpTLIk3KgpqMIIS
 T50bWe/r5PtZ/1TPN1wmO4wRO0QhLdgAAAA==
X-Change-ID: 20261020-acpi-sbs-serialize-4e984398cf5c
To: "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>
Cc: linux-acpi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Penkacelsus <balthasar978@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792493920; l=2969;
 i=balthasar978@gmail.com; s=20261020; h=from:subject:message-id;
 bh=juNEQpDZvarDTwpQSkqLQd/gYi+Y1pUsMl0a5qSjuSg=;
 b=7FyHcDkQ4jT9S3ICW1XCnA8onIWmGobgn3hBy6HhLI+qs/RqS5hZI3w+C2V4qD9nRRD5bQFhN
 MT/wqqgDl1+Am5D5DX6yJHVblPkXJFAIFEqe2uNJgEyeDL3ulhaE3nN
X-Developer-Key: i=balthasar978@gmail.com; a=ed25519;
 pk=2qjYMGCkah5ZygiRd5e1xAy6ayf0rjvvVxbCxzzG/8M=
X-Endpoint-Received: by B4 Relay for balthasar978@gmail.com/20261020 with auth_id=1249
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

acpi_battery_get_state() refreshes the battery state at most once per
cache_time (1 s), but the check and the update are not serialized:
callers that arrive together all see a stale cache and each read all
seven state registers over SMBus.

On T2 MacBooks (MacBookPro16,1: SBS battery behind the EC's SMBus host
controller) every SMBus word read takes about two dozen EC GPEs. A
desktop shell that reloads ten BAT0 attributes in parallel every 2 s
drove the EC GPE to ~680/s, which kept irq/9-acpi near 16% of a CPU.
Readers of a single attribute file each get their own thread in such
shells, so the race is the common case, not a corner case.

Serialize the refresh with a per-battery mutex taken in
acpi_battery_get_state(), so that the power supply readers and the
SMBus alarm callback share it. The first caller does the SMBus reads;
the others wait and then find a fresh cache. Use a new lock rather than
sbs->lock: acpi_sbs_remove() holds sbs->lock while it unregisters the
power supplies, which waits for sysfs readers to drain.

With ten parallel readers of state attributes every 200 ms, SMBus reads
drop from 26-29/s to 6/s (the cache floor) and EC GPEs from 600-670/s
to ~140/s.

Signed-off-by: Penkacelsus <balthasar978@gmail.com>
---
 drivers/acpi/sbs.c | 12 ++++++++++--
 1 file changed, 10 insertions(+), 2 deletions(-)

diff --git a/drivers/acpi/sbs.c b/drivers/acpi/sbs.c
index f10bbf13c..861739b18 100644
--- a/drivers/acpi/sbs.c
+++ b/drivers/acpi/sbs.c
@@ -55,6 +55,7 @@ struct acpi_battery {
 	struct power_supply_desc bat_desc;
 	struct acpi_sbs *sbs;
 	unsigned long update_time;
+	struct mutex state_lock;	/* serializes state refreshes */
 	char name[8];
 	char manufacturer_name[ACPI_SBS_BLOCK_MAX];
 	char device_name[ACPI_SBS_BLOCK_MAX];
@@ -355,6 +356,13 @@ static int acpi_battery_get_state(struct acpi_battery *battery)
 {
 	int i, result = 0;
 
+	/*
+	 * Callers that find the cache stale at the same time would each
+	 * re-read the whole state over SMBus. Serialize them so that only
+	 * the first one does; the others then find a fresh cache.
+	 */
+	guard(mutex)(&battery->state_lock);
+
 	if (battery->update_time &&
 	    time_before(jiffies, battery->update_time +
 				msecs_to_jiffies(cache_time)))
@@ -367,9 +375,8 @@ static int acpi_battery_get_state(struct acpi_battery *battery)
 					 (u8 *)battery +
 						state_readers[i].offset);
 		if (result)
-			goto end;
+			break;
 	}
-      end:
 	battery->update_time = jiffies;
 	return result;
 }
@@ -530,6 +537,7 @@ static int acpi_battery_add(struct acpi_sbs *sbs, int id)
 
 	battery->id = id;
 	battery->sbs = sbs;
+	mutex_init(&battery->state_lock);
 	result = acpi_battery_read(battery);
 	if (result)
 		return result;

---
base-commit: a7b81d2593fc90a93e108441a04e3b258d19f074
change-id: 20261020-acpi-sbs-serialize-4e984398cf5c

Best regards,
--  
Penkacelsus <balthasar978@gmail.com>

