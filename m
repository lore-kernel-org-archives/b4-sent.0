From: Janne Grunau <j@jannau.net>
Date: Mon, 19 May 2025 22:49:20 +0200
Subject: [PATCH v2] HID: lenovo: Remove CONFIG_ACPI dependency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250519-hid_lenovo_acpi_dependency-v2-1-124760ddd6f7@jannau.net>
X-B4-Tracking: v=1; b=H4sIAE+ZK2gC/43NTQ6CMBCG4auQWVvTovzoynsYQgY6yBgzJS02E
 sLdrZzA5fMt3m+FQJ4pwDVbwVPkwE4S8kMG/YjyIMU2GXKdF7owtRrZti8SF12L/cStpYnEkvS
 L0oRVjWVnq7OGFJg8DfzZ4/cmeeQwO7/sX9H81r+y0SitcLDd5dQV1mB5e6IIvo9CMzTbtn0Be
 /HAJ8UAAAA=
X-Change-ID: 20250518-hid_lenovo_acpi_dependency-0ea78a6bd740
To: Arnd Bergmann <arnd@arndb.de>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>, 
 Armin Wolf <W_Armin@gmx.de>
Cc: linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-acpi@vger.kernel.org, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3410; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=Bitucw1yaCIqyRa0nTR6FoFtUSPlCwvKN7PBGDQsgTI=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhgztmUExzVNNrU5d+bm3lbGH47zQsumf/q/xWLvAVuj7v
 O/RDNryHaUsDGJcDLJiiixJ2i87GFbXKMbUPgiDmcPKBDKEgYtTACbSWMTwz2zLpDfhYuc+nd8z
 8ey8xtLHm34VlUcLuHLIe/iJJPx0i2Nk+LihpPzlXO/eZ41OytO+76pWv3ki6GuymkXI1KNPTl9
 dyAYA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The hid-lenovo driver supports external Bluetooth and USB devices which
can be used with non-ACPI systems/kernels. Call platform_profile_cycle()
only if CONFIG_ACPI_PLATFORM_PROFILE is enabled and select
CONFIG_ACPI_PLATFORM_PROFILE only if ACPI is enabled.
This should not affect functionality since only the detachable keyboard
of a x86 tablet with a custom connector has an hotkey for cycling
through power profiles.

Fixes: 52572cde8b4a4 ("HID: lenovo: select CONFIG_ACPI_PLATFORM_PROFILE")
Signed-off-by: Janne Grunau <j@jannau.net>
---
hid-lenovo supports external generic USB and Bluetooth devices and
should be buildable and usable on non-ACPI kernels and systems. Commit
84c9d2a968c82 ("HID: lenovo: Support for ThinkPad-X12-TAB-1/2 Kbd Fn
keys") added a hot key to cycle through power profiles using ACPI's
platform_profile. This resulted in adding a dependency on ACPI and
selecting CONFIG_ACPI_PLATFORM_PROFILE to fix build an link errors in
commit 52572cde8b4a ("HID: lenovo: select
CONFIG_ACPI_PLATFORM_PROFILE"). This is undesirable for HID drivers
supporting generic USB and Bluetooth devices. So instead call
platform_profile_cycle() only CONFIG_ACPI_PLATFORM_PROFILE is enabled
and select the latter only if ACPI is enabled.

Supercedes with Armin Wolf's "ACPI: platform_profile: Add support for
non-ACPI platforms" [1] the earlier removel in "HID: lenovo: Unbreak
USB/BT keyboards on non-ACPI platforms" [2].

[1]: https://lore.kernel.org/linux-acpi/20250518185111.3560-1-W_Armin@gmx.de/
[2]: https://lore.kernel.org/linux-input/20250512-hid_lenovo_unbreak_non_acpi-v1-1-e9e37ecbfbfe@jannau.net/
---
Changes in v2:
- drop stub platform_profile_cycle()
- call platform_profile_cycle() conditioanlly
- drop 'depends on ACPI || !ACPI'
- Link to v1: https://lore.kernel.org/r/20250518-hid_lenovo_acpi_dependency-v1-0-afdb93b5d1a6@jannau.net
---
 drivers/hid/Kconfig      | 3 +--
 drivers/hid/hid-lenovo.c | 6 ++++--
 2 files changed, 5 insertions(+), 4 deletions(-)

diff --git a/drivers/hid/Kconfig b/drivers/hid/Kconfig
index a503252702b7b43c332a12b14bc8b23b83e9f028..1656bb1504f750d73011d3f008e27b4436a58678 100644
--- a/drivers/hid/Kconfig
+++ b/drivers/hid/Kconfig
@@ -595,8 +595,7 @@ config HID_LED
 
 config HID_LENOVO
 	tristate "Lenovo / Thinkpad devices"
-	depends on ACPI
-	select ACPI_PLATFORM_PROFILE
+	select ACPI_PLATFORM_PROFILE if ACPI
 	select NEW_LEDS
 	select LEDS_CLASS
 	help
diff --git a/drivers/hid/hid-lenovo.c b/drivers/hid/hid-lenovo.c
index af29ba840522f99bc2f426d4753f70d442cef3af..73c6a26638a22ad1c8368112e8ab185232a9df12 100644
--- a/drivers/hid/hid-lenovo.c
+++ b/drivers/hid/hid-lenovo.c
@@ -728,9 +728,11 @@ static int lenovo_raw_event_TP_X12_tab(struct hid_device *hdev, u32 raw_data)
 			if (hdev->product == USB_DEVICE_ID_LENOVO_X12_TAB) {
 				report_key_event(input, KEY_RFKILL);
 				return 1;
+			} else if (IS_ENABLED(CONFIG_ACPI_PLATFORM_PROFILE)) {
+				platform_profile_cycle();
+				return 1;
 			}
-			platform_profile_cycle();
-			return 1;
+			return 0;
 		case TP_X12_RAW_HOTKEY_FN_F10:
 			/* TAB1 has PICKUP Phone and TAB2 use Snipping tool*/
 			(hdev->product == USB_DEVICE_ID_LENOVO_X12_TAB) ?

---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250518-hid_lenovo_acpi_dependency-0ea78a6bd740

Best regards,
-- 
Janne Grunau <j@jannau.net>

