MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-bt-inqcache-v1-1-9610f88a2a49@certik.com>
X-B4-Tracking: v=1; b=H4sIAKXPCWsC/yWMTQrCMBBGr1Jm7UATQalXEReZdGJGSqKZVITSu
 5vo8r3vZwPlIqxwGTYo/BaVnBqYwwA+unRnlLkx2NGejLFnpIqSXt75yOgNT2GcJ6ZwhLZ4Fg7
 y+b1dgZaVa841wu0f6UoP9rW/9TI5ZaTiko9dKae51RfsHvb9C3WxRdiaAAAA
X-Change-ID: 20261127-bt-inqcache-c1e9f0d9ebf3
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 15:46:47 +0000
Subject: [PATCH bluetooth] Bluetooth: hci_event: Requeue failed name
 resolutions
To: linux-bluetooth@vger.kernel.org
Cc: Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795805093; l=2025;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=7k2grbbT9bxaYWonzyj9mudhJSGr/nMZ7k7ShM0xQpE=;
 b=jG3DeROsDqtMrLtX/K8GoqCMToeXzflfF+imPHl1BhEJP4g31q1SBmDsvVrweK/A1LnQiTjs1
 jl3dI3jr9FmCjat+xEnFcwDYrZekljx0SZOIyX47IPZEcAsG/ZXlaaH
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a Remote Name Request fails, hci_check_pending_name() removes the
inquiry entry from the resolve list and changes its state to
NAME_NOT_KNOWN, but does not add it to the unknown list.

If an Extended Inquiry Result later supplies a complete name for the
same address, hci_inquiry_cache_update() treats the NAME_NOT_KNOWN
entry as linked and deletes it again. This corrupts the list in
hci_rx_work.

Add the entry to the unknown list after the failed resolution, so a
later result unlinks it exactly once.

Fixes: c3e7c0d90b14 ("Bluetooth: Set name_state to unknown when entry name is empty")
Cc: stable@vger.kernel.org
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
Reproduced under UML with KASAN and a vhci controller, on bluetooth-next
f57f78086ab5 and on mainline 9437ee8b6cf6. The sequence is BR/EDR
discovery, an EIR without a complete name, Confirm Name with
name_known=0, the Remote Name Request failing with page timeout, then a
second EIR for the same address with a complete name. The second
inquiry was started with a raw HCI_Inquiry from uid 65534 with no
capabilities, which hci_sec_filter allows. Stock and with the patch
reverted fault in list_del() from hci_extended_inquiry_result_evt() in
hci_rx_work. With the patch the guest stays up with no warning. The
reproducer is available if it helps.

This was found and the fix prepared with AI coding tools (OpenAI Codex
agents, with review by Claude). I went over the analysis and the patch
before signing off.

diff --git a/net/bluetooth/hci_event.c b/net/bluetooth/hci_event.c
index a9b6a6ccaa03..c767e8d32217 100644
--- a/net/bluetooth/hci_event.c
+++ b/net/bluetooth/hci_event.c
@@ -2582,6 +2582,8 @@ static void hci_check_pending_name(struct hci_dev *hdev, struct hci_conn *conn,
 	list_del(&e->list);
 
 	e->name_state = name ? NAME_KNOWN : NAME_NOT_KNOWN;
+	if (!name)
+		list_add(&e->list, &discov->unknown);
 	mgmt_remote_name(hdev, bdaddr, ACL_LINK, 0x00, e->data.rssi,
 			 name, name_len);
 
