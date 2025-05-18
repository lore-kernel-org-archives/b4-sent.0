From: Janne Grunau <j@jannau.net>
Date: Sun, 18 May 2025 12:18:38 +0200
Subject: [PATCH 2/2] HID: lenovo: Remove CONFIG_ACPI dependency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250518-hid_lenovo_acpi_dependency-v1-2-afdb93b5d1a6@jannau.net>
References: <20250518-hid_lenovo_acpi_dependency-v1-0-afdb93b5d1a6@jannau.net>
In-Reply-To: <20250518-hid_lenovo_acpi_dependency-v1-0-afdb93b5d1a6@jannau.net>
To: Arnd Bergmann <arnd@arndb.de>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-acpi@vger.kernel.org, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1053; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=bo27DdOTnOoQpDLRJMS1oIMxCFrEhqBgkKEdS+8giu4=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhgzNLQyts6/cn2c7q3CmUPq6uJoXXNkbxIX3eQSc0Z9eN
 e985vrCjlIWBjEuBlkxRZYk7ZcdDKtrFGNqH4TBzGFlAhnCwMUpABOpbGT4H3TL9sD882cqd2nN
 mev9+03S9PYF317PPXVpabnF16OpE00Y/kpvWfjl6syyfxtOnGldsen6306L6Q+tnC88/H2nw+9
 +6XxuAA==
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With platform_profile_cycle() stubbed the dependency on CONFIG_ACPI can
be relaxed to `ACPI || !ACPI` and CONFIG_ACPI_PLATFORM_PROFILE is only
selected if ACPI is enabled.
Cycling through platform profiles is only functional with ACPI but that
should not be an issue as it only used on a detachable keyboard of a x86
tablet with a special connector.

Fixes: 52572cde8b4a4 ("HID: lenovo: select CONFIG_ACPI_PLATFORM_PROFILE")
Signed-off-by: Janne Grunau <j@jannau.net>
---
 drivers/hid/Kconfig | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/hid/Kconfig b/drivers/hid/Kconfig
index a503252702b7b43c332a12b14bc8b23b83e9f028..984f7bd235141f21e018b51f97546ec9d00324e8 100644
--- a/drivers/hid/Kconfig
+++ b/drivers/hid/Kconfig
@@ -595,8 +595,8 @@ config HID_LED
 
 config HID_LENOVO
 	tristate "Lenovo / Thinkpad devices"
-	depends on ACPI
-	select ACPI_PLATFORM_PROFILE
+	depends on ACPI || !ACPI
+	select ACPI_PLATFORM_PROFILE if ACPI
 	select NEW_LEDS
 	select LEDS_CLASS
 	help

-- 
2.49.0

