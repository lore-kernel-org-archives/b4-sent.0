From: =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH v3 0/9] usb: storage: Mark various arrays as const
Date: Fri, 28 Feb 2025 16:11:15 +0100
Message-Id: <20250228-misc-const-v3-0-09b417ded9c4@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABPSwWcC/1WMQQ6DIBQFr2JYlwY+oLWr3qPpAvFTWRQMENLGe
 PeiK81bzUtmFpIwOkzk3iwkYnHJBV9BXBpiJu3fSN1YmQADySTj9OOSoSb4lCl2gzQW2KhsT6o
 wR7Tuu8eer8qTSznE394ufHu3jGIA6pgpnNYBt1YMt1aK7jGHlDFcPWaydQoc3fbkAmVUD61SW
 mrojTm567r+AWlKhIThAAAA
X-Change-ID: 20240401-misc-const-e7b4cf20d5f9
To: Alan Stern <stern@rowland.harvard.edu>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, usb-storage@lists.one-eyed-alien.net, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Jonathan_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740755487; l=1859;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=d6jAc3qib5tSgD8hCc1ZWLfDLKrBDtNf4sx4KR6R/lE=;
 b=F1afqBPYnJvF2KHLnpWOeY0Wgv1HJz8SL1YNWW21594n+LoTJHkJbeiJqMzW0ZSYkTlZ4R4Ll
 uG0qOvsQfcmBKjWrAS8sBGv5haqqScp8LVDTjxiz8fxunnwF4BYl3Ji
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While reading code, I noticed that some arrays in USB mass storage
drivers are declared static but not const, even though they are not
modified. This patchset marks them const.

All patches were compile-tested.

Signed-off-by: Jonathan Neuschäfer <j.ne@posteo.net>
---
Changes in v3:
- Elaborate *why* const is a good idea
- Link to v2: https://lore.kernel.org/r/20250226-misc-const-v2-0-ab655a4a29cc@posteo.net

Changes in v2:
- Add new patches 2-9
- Use consistent authorship information
- Link to v1: https://lore.kernel.org/r/20250225-misc-const-v1-1-121ff3b86437@posteo.net

---
Jonathan Neuschäfer (9):
      usb: storage: jumpshot: Use const for constant arrays
      usb: storage: transport: Use const for constant array
      usb: storage: alauda: Use const for card ID array
      usb: storage: datafab: Use const for constant arrays
      usb: storage: initializers: Use const for constant array
      usb: storage: realtek_cr: Use const for constant arrays
      usb: storage: sddr09: Use const for constant arrays
      usb: storage: sddr55: Use const for constant arrays
      usb: storage: shuttle_usbat: Use const for constant array

 drivers/usb/storage/alauda.c        |  8 ++++----
 drivers/usb/storage/datafab.c       | 14 +++++++-------
 drivers/usb/storage/initializers.c  |  2 +-
 drivers/usb/storage/jumpshot.c      | 10 +++++-----
 drivers/usb/storage/realtek_cr.c    |  6 +++---
 drivers/usb/storage/sddr09.c        | 14 +++++++-------
 drivers/usb/storage/sddr55.c        |  4 ++--
 drivers/usb/storage/shuttle_usbat.c |  2 +-
 drivers/usb/storage/transport.c     |  2 +-
 9 files changed, 31 insertions(+), 31 deletions(-)
---
base-commit: 2014c95afecee3e76ca4a56956a936e23283f05b
change-id: 20240401-misc-const-e7b4cf20d5f9

Best regards,
-- 
Jonathan Neuschäfer <j.ne@posteo.net>

