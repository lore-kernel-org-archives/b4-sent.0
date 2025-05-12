From: Janne Grunau <j@jannau.net>
Date: Mon, 12 May 2025 23:55:15 +0200
Subject: [PATCH] HID: lenovo: Unbreak USB/BT keyboards on non-ACPI
 platforms
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250512-hid_lenovo_unbreak_non_acpi-v1-1-e9e37ecbfbfe@jannau.net>
X-B4-Tracking: v=1; b=H4sIAEJuImgC/x3MSwqAIBAA0KvErBPUPouuEiE2TTUUYyhFEN09a
 fk274FEkSlBVzwQ6eLEQTJMWQCuXhZSPGWD1bbRjbFq5cntJOEK7pQxkt+cBHEeD1aoazNXiKY
 aW8jDEWnm+9/74X0/64zrI20AAAA=
X-Change-ID: 20250512-hid_lenovo_unbreak_non_acpi-c041f3cc13b6
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>, 
 Vishnu Sankar <vishnuocv@gmail.com>
Cc: "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>, 
 linux-acpi@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5604; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=fDDp0h4tQHC+Zan4FRSlGu8S8lB9BEYY3hPbDJrYDf0=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhgylPB/5Q03Way/ElEVtcT1rJ/eVh3Hqo5xjq3/6nb0Qx
 J/9vE+xo5SFQYyLQVZMkSVJ+2UHw+oaxZjaB2Ewc1iZQIYwcHEKwERkDRn+J7B9DQuYyx3xgOd5
 rp7GU9FEizep0bx+Z+oY+Rbte3F9MyNDq5d2g/bWjY/mtxtc5G74snHam38v7pwX06tzuPa5ZXo
 rCwA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 84c9d2a968c8 ("HID: lenovo: Support for ThinkPad-X12-TAB-1/2 Kbd
Fn keys") added a dependency on ACPI_PLATFORM_PROFILE to cycle through
power profiles. This breaks USB and Bluetooth keyboards on non-ACPI
platforms since platform_profile_init() fails. See the warning below for
the visible symptom but cause is the dependency on the platform_profile
module.

[  266.225052] kernel: usb 1-1.3.2: new full-speed USB device number 9 using xhci_hcd
[  266.316032] kernel: usb 1-1.3.2: New USB device found, idVendor=17ef, idProduct=6047, bcdDevice= 3.30
[  266.327129] kernel: usb 1-1.3.2: New USB device strings: Mfr=1, Product=2, SerialNumber=0
[  266.327623] kernel: usb 1-1.3.2: Product: ThinkPad Compact USB Keyboard with TrackPoint
[  266.328096] kernel: usb 1-1.3.2: Manufacturer: Lenovo
[  266.337488] kernel: ------------[ cut here ]------------
[  266.337551] kernel: WARNING: CPU: 4 PID: 2619 at fs/sysfs/group.c:131 internal_create_group+0xc0/0x358
[  266.337584] kernel: Modules linked in: platform_profile(+) nft_fib_inet nft_fib_ipv4 nft_fib_ipv6 nft_fib nft_reject_inet nf_reject_ipv4 nf_reject_ipv6 nft_reject nft_ct nft>
[  266.337685] kernel:  apple_sio spi_apple apple_dart soundcore spmi_apple_controller pinctrl_apple_gpio i2c_pasemi_platform apple_admac i2c_pasemi_core clk_apple_nco xhci_pla>
[  266.337717] kernel: CPU: 4 UID: 0 PID: 2619 Comm: (udev-worker) Tainted: G S      W          6.14.4-400.asahi.fc41.aarch64+16k #1
[  266.337750] kernel: Tainted: [S]=CPU_OUT_OF_SPEC, [W]=WARN
[  266.337776] kernel: Hardware name: Apple Mac mini (M1, 2020) (DT)
[  266.337808] kernel: pstate: 61400009 (nZCv daif +PAN -UAO -TCO +DIT -SSBS BTYPE=--)
[  266.337834] kernel: pc : internal_create_group+0xc0/0x358
[  266.337860] kernel: lr : sysfs_create_group+0x20/0x40
[  266.337886] kernel: sp : ffff800086f877a0
[  266.337914] kernel: x29: ffff800086f877b0 x28: 0000000000000000 x27: ffffb66d0b338348
[  266.337939] kernel: x26: ffffb66d0b338358 x25: ffffb66d528c7c50 x24: ffffb66d507e37b0
[  266.337965] kernel: x23: 0000fffebf6708d8 x22: 0000000000000000 x21: ffffb66d0b370340
[  266.337991] kernel: x20: ffffb66d0b370308 x19: 0000000000000000 x18: 0000000000000000
[  266.338029] kernel: x17: 554e514553007373 x16: ffffb66d4f8c2268 x15: 595342555300656c
[  266.338051] kernel: x14: 69666f72702d6d72 x13: 00353236353d4d55 x12: 4e51455300737361
[  266.338075] kernel: x11: ffff6adf91b80100 x10: 0000000000000139 x9 : ffffb66d4f8c2288
[  266.338097] kernel: x8 : ffff800086f87620 x7 : 0000000000000000 x6 : 0000000000000000
[  266.338116] kernel: x5 : ffff6adfc896e100 x4 : 0000000000000000 x3 : ffff6adfc896e100
[  266.338139] kernel: x2 : ffffb66d0b3703a0 x1 : 0000000000000000 x0 : 0000000000000000
[  266.338155] kernel: Call trace:
[  266.338173] kernel:  internal_create_group+0xc0/0x358 (P)
[  266.338193] kernel:  sysfs_create_group+0x20/0x40
[  266.338206] kernel:  platform_profile_init+0x48/0x3ff8 [platform_profile]
[  266.338224] kernel:  do_one_initcall+0x60/0x358
[  266.338239] kernel:  do_init_module+0x94/0x260
[  266.338257] kernel:  load_module+0x5e0/0x708
[  266.338271] kernel:  init_module_from_file+0x94/0x100
[  266.338290] kernel:  __arm64_sys_finit_module+0x268/0x360
[  266.338309] kernel:  invoke_syscall+0x6c/0x100
[  266.338327] kernel:  el0_svc_common.constprop.0+0xc8/0xf0
[  266.338346] kernel:  do_el0_svc+0x24/0x38
[  266.338365] kernel:  el0_svc+0x3c/0x170
[  266.338385] kernel:  el0t_64_sync_handler+0x10c/0x138
[  266.338404] kernel:  el0t_64_sync+0x1b0/0x1b8
[  266.338419] kernel: ---[ end trace 0000000000000000 ]---

Fixes: 84c9d2a968c8 ("HID: lenovo: Support for ThinkPad-X12-TAB-1/2 Kbd Fn keys")
Cc: stable@vger.kernel.org
Signed-off-by: Janne Grunau <j@jannau.net>

------>8---------
I don't see an easy solution to keep the functionality in generic HID
code which is used on non-ACPI platforms. Solution for this are not
trivial so remove the functionality for now.
Cc-ing the ACPI maintainers in the case they can think of a solution for
this issue.

---
 drivers/hid/Kconfig      | 1 -
 drivers/hid/hid-lenovo.c | 5 +----
 2 files changed, 1 insertion(+), 5 deletions(-)

diff --git a/drivers/hid/Kconfig b/drivers/hid/Kconfig
index a503252702b7b43c332a12b14bc8b23b83e9f028..6b4445f54b2f2818d451ff28b3f7bcc2b1c7e99f 100644
--- a/drivers/hid/Kconfig
+++ b/drivers/hid/Kconfig
@@ -596,7 +596,6 @@ config HID_LED
 config HID_LENOVO
 	tristate "Lenovo / Thinkpad devices"
 	depends on ACPI
-	select ACPI_PLATFORM_PROFILE
 	select NEW_LEDS
 	select LEDS_CLASS
 	help
diff --git a/drivers/hid/hid-lenovo.c b/drivers/hid/hid-lenovo.c
index af29ba840522f99bc2f426d4753f70d442cef3af..cff4b5ddd9aa9bad0516f8c9beb58927c24477fc 100644
--- a/drivers/hid/hid-lenovo.c
+++ b/drivers/hid/hid-lenovo.c
@@ -32,8 +32,6 @@
 #include <linux/leds.h>
 #include <linux/workqueue.h>
 
-#include <linux/platform_profile.h>
-
 #include "hid-ids.h"
 
 /* Userspace expects F20 for mic-mute KEY_MICMUTE does not work */
@@ -729,8 +727,7 @@ static int lenovo_raw_event_TP_X12_tab(struct hid_device *hdev, u32 raw_data)
 				report_key_event(input, KEY_RFKILL);
 				return 1;
 			}
-			platform_profile_cycle();
-			return 1;
+			return 0;
 		case TP_X12_RAW_HOTKEY_FN_F10:
 			/* TAB1 has PICKUP Phone and TAB2 use Snipping tool*/
 			(hdev->product == USB_DEVICE_ID_LENOVO_X12_TAB) ?

---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250512-hid_lenovo_unbreak_non_acpi-c041f3cc13b6

Best regards,
-- 
Janne Grunau <j@jannau.net>

