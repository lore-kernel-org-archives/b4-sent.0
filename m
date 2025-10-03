From: Massimiliano Minella <massimiliano.minella@se.com>
Date: Fri, 03 Oct 2025 11:06:16 +0200
Subject: [PATCH] docs: domain: add watchdog notification support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251003-update_wd_doc-v1-1-d96fa45fe994@se.com>
X-B4-Tracking: v=1; b=H4sIAAeS32gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDAwNj3dKClMSS1PjylPiU/GRd08REyyQT46RUA8tEJaCegqLUtMwKsHn
 RsbW1AHL5ITVfAAAA
To: devel@lists.libvirt.org
Cc: Massimiliano Minella <massimiliano.minella@se.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759482381; l=1351;
 i=massimiliano.minella@se.com; s=20250121; h=from:subject:message-id;
 bh=bFiEzWJz+fIM7frUH+1OEWNe/qWrDsiA5JUdcmLOdoM=;
 b=FpPI+OKHP1J/TogVfdapssFKgknaVtrvjCkzxyO2AsAW1LfOKDHAFtRnuVIbIPzvRaiVHNmkA
 jbgo1cpjHu5BmplOe2T8ssxNFAWfCc/b9mfrk64ex/ad9hOPvwG/wZa
X-Developer-Key: i=massimiliano.minella@se.com; a=ed25519;
 pk=p6Og4stDBPm4cBEySH8oVWARLO52pxVayNFqHslSXU0=
X-Endpoint-Received: by B4 Relay for massimiliano.minella@se.com/20250121 with auth_id=325
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since v0.8.0 a watchdog notification is available under event ID
VIR_DOMAIN_EVENT_ID_WATCHDOG, update the documentation to remove the
previous limitation.

Signed-off-by: Massimiliano Minella <massimiliano.minella@se.com>
---
Remove limitation on notification support for watchdog.
---
 docs/formatdomain.rst | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git docs/formatdomain.rst docs/formatdomain.rst
index f50dce477f..d70022a239 100644
--- docs/formatdomain.rst
+++ docs/formatdomain.rst
@@ -8350,8 +8350,8 @@ The watchdog device requires an additional driver and management daemon in the
 guest. Just enabling the watchdog in the libvirt configuration does not do
 anything useful on its own.
 
-Currently libvirt does not support notification when the watchdog fires. This
-feature is planned for a future version of libvirt.
+:since:`Since 0.8.0`, a notification is available when the watchdog fires, using
+the event ID ``VIR_DOMAIN_EVENT_ID_WATCHDOG``.
 
 Having multiple watchdogs is usually not something very common, but be aware
 that this might happen, for example, when an implicit watchdog device is added

---
base-commit: eb99bbaf2e5b1e91f4999c7a1ccc90d67dfbe471
change-id: 20251003-update_wd_doc-5aa9b43be09a

Best regards,
-- 
Massimiliano Minella <massimiliano.minella@se.com>

