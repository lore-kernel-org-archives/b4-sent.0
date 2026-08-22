From: Rahul Kumar Rai <learn.rahul.rai@gmail.com>
Date: Sun, 23 Aug 2026 02:30:32 +0530
Subject: [PATCH] wifi: rtw88: disable ASPM and deep PS on ASUS TUF Gaming
 A15 FA506IH
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260823-fa506ih-rtw88-quirk-v1-1-ef0984d59e72@gmail.com>
X-B4-Tracking: v=1; b=H4sIAO8NimoC/yXMQQ6CMBBA0auQWTvJtIbacBXiAssURhKUKagJ4
 e4WWL7F/yskVuEEVbGC8keSvMYMcykg9M3YMUqbDZasI2+vGJuSnPSo89d7nBbRAV0w5a31FCg
 ayOVbOcrvuNb302l5PDnM+wq27Q9nRYTvdwAAAA==
X-Change-ID: 20260823-fa506ih-rtw88-quirk-6c157d80c0f1
To: Ping-Ke Shih <pkshih@realtek.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Rahul Kumar Rai <learn.rahul.rai@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787432431; l=2531;
 i=learn.rahul.rai@gmail.com; s=20260822; h=from:subject:message-id;
 bh=Pz6whzycVyQSyKGgPZ2rblAwgpB9ScAj/UQo4bzF9mM=;
 b=JguIOYUlo7J0TlQpd98nuZmMhoY9B1cNYh/4IdTS6bSWZk4aK5KYYHbZ2xST7iyQZd3kOkH9E
 1LCTLu7fZzOAzWuL0xj6F6pvhZVglcdPCQ8mb/lI7ZaMpT+SOViOWSc
X-Developer-Key: i=learn.rahul.rai@gmail.com; a=ed25519;
 pk=FKMDyIZj21KmruJbeSaCjxqun1AusvFUl0dM21tRMF4=
X-Endpoint-Received: by B4 Relay for learn.rahul.rai@gmail.com/20260822 with auth_id=970
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RTL8822CE on the ASUS TUF Gaming A15 FA506IH fails to return from
PCIe low-power states across system suspend. The device is inaccessible
on the way back to D0, so the MAC power-on sequence and the firmware
handshake that follow it fail, and the driver gives up. Wi-Fi stays
unavailable until the machine is powered off completely:

  rtw88_8822ce 0000:03:00.0: Unable to change power state from D3cold to D0, device inaccessible
  rtw88_8822ce 0000:03:00.0: failed to poll offset=0x5 mask=0x2 value=0x0
  rtw88_8822ce 0000:03:00.0: mac power on failed
  rtw88_8822ce 0000:03:00.0: probe with driver rtw88_8822ce failed with error -114

Reads of the ASPM link-configuration register over DBI also time out
around the same transitions.

This is not a one-off. It has been recurring on this machine for a long
time. The kernel logs still on disk begin at 2026-07-20 and already
contain six failed D-state transitions and three probe failures of this
kind, and the problem was present well before that window.

This is the same platform ASPM inter-operability problem already handled
for other machines through rtw_pci_quirks[], including the closely
related ASUS TUF Gaming A15 FA506II. The FA506IH reports a different DMI
board name, so that entry does not match. Disabling PCI ASPM and deep
power save stops the failure on this model as well.

  DMI_SYS_VENDOR = ASUSTeK COMPUTER INC.
  DMI_BOARD_NAME = FA506IH

Signed-off-by: Rahul Kumar Rai <learn.rahul.rai@gmail.com>
---
 drivers/net/wireless/realtek/rtw88/pci.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/net/wireless/realtek/rtw88/pci.c b/drivers/net/wireless/realtek/rtw88/pci.c
index 5b00c1e1eec6..fcb6f4c4cc2d 100644
--- a/drivers/net/wireless/realtek/rtw88/pci.c
+++ b/drivers/net/wireless/realtek/rtw88/pci.c
@@ -1789,6 +1789,16 @@ static const struct dmi_system_id rtw_pci_quirks[] = {
 		.driver_data = (void *)(BIT(QUIRK_DIS_CAP_PCI_ASPM) |
 					BIT(QUIRK_DIS_CAP_LPS_DEEP)),
 	},
+	{
+		.callback = rtw_pci_disable_caps,
+		.ident = "ASUS TUF Gaming A15 FA506IH",
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "ASUSTeK COMPUTER INC."),
+			DMI_MATCH(DMI_BOARD_NAME, "FA506IH"),
+		},
+		.driver_data = (void *)(BIT(QUIRK_DIS_CAP_PCI_ASPM) |
+					BIT(QUIRK_DIS_CAP_LPS_DEEP)),
+	},
 	{}
 };
 

---
base-commit: 66fb95a521110da673090294561844c9f76ebe64
change-id: 20260823-fa506ih-rtw88-quirk-6c157d80c0f1

Best regards,
--  
Rahul Kumar Rai <learn.rahul.rai@gmail.com>

