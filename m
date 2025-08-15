From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Fri, 15 Aug 2025 16:56:39 +0800
Subject: [PATCH] ACPICA: add more parameter validation for
 acpi_walk_namespace()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250815-acpi_fix-v1-1-a05ebfe1b8ac@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAEb2nmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDC0NT3cTkgsz4tMwKXWNzI5NUs2STlEQDIyWg8oKiVKAw2Kjo2NpaAKq
 N1oJaAAAA
X-Change-ID: 20250815-acpi_fix-3724e6c4da02
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Robert Moore <robert.moore@intel.com>, Len Brown <lenb@kernel.org>
Cc: linux-acpi@vger.kernel.org, acpica-devel@lists.linux.dev, 
 linux-kernel@vger.kernel.org, wangyuli@uniontech.com, 
 guanwentao@uniontech.com, niecheng1@uniontech.com, zhanjun@uniontech.com, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755248199; l=1219;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=TsnirmhdVe95wU+g+49Bvoj0s1Au2GOZZ9diwqQO6Lc=;
 b=sdZiZROQGQifna8Wfyn1Q9udujXPJBP3+KY88fRSul/V+zzMEqmEK6+0L2CgrbIC0AD/2g8sL
 fRoZUvajx4oCPt7xrDmguQSeIxaJutZUblGtKdK3xHjwupTMI6Yzr3C
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the Honor FMB-P-PCB laptop, an incorrect ACPI table causes
sdw_intel_acpi_scan to pass a NULL pointer as start_object to
acpi_walk_namespace() when calling it, which eventually causes the
kernel to report a NULL pointer dereference[1].

1. https://gist.github.com/Cryolitia/a860ffc97437dcd2cd988371d5b73ed7

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 drivers/acpi/acpica/nsxfeval.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/acpi/acpica/nsxfeval.c b/drivers/acpi/acpica/nsxfeval.c
index f9d059647cc52e94ce013af3382addba338820e8..c1f318ea7d5fcd846dc158b155286a6f5bba4cff 100644
--- a/drivers/acpi/acpica/nsxfeval.c
+++ b/drivers/acpi/acpica/nsxfeval.c
@@ -564,7 +564,7 @@ acpi_walk_namespace(acpi_object_type type,
 
 	/* Parameter validation */
 
-	if ((type > ACPI_TYPE_LOCAL_MAX) ||
+	if ((type > ACPI_TYPE_LOCAL_MAX) || (start_object == NULL) ||
 	    (!max_depth) || (!descending_callback && !ascending_callback)) {
 		return_ACPI_STATUS(AE_BAD_PARAMETER);
 	}

---
base-commit: 24ea63ea387714634813359e2c8e0e6c36952f73
change-id: 20250815-acpi_fix-3724e6c4da02

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

