From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v2 0/3] usb: ehci-generic: setup a bulk of phy when
 possible
Date: Thu, 08 Feb 2024 01:19:19 +0800
Message-Id: <20240208-ehci-v2-0-6bf084b7ffac@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJe7w2UC/13MSw7CIBSF4a00dyzmQitNHbkP0wGvyo1aGqhE0
 7B3sUOH/8nJt0FykVyCc7NBdJkShbmGODRgvJpvjpGtDQJFhwI5c94Qk6ZVqrdDP7QC6nWJbqL
 3zlzH2p7SGuJnVzP/rX9A5gyZ1ieURuMkO3sJr/URwv1owhPGUsoXcRjmYpoAAAA=
To: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707326360; l=1101;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=/fS0bsXE9PBV5gTFm3ibliWw9oyVb2Wx4OmS5rN/YT4=;
 b=vkj11UBLtpollvoGwe7fsoKrlcNdwAm/D4KHcUbUMUH7ZHdRGe68avgsiqcqH4ln+jOnZhxyv
 RA2nxF45+PqA1FUfljNsMIUSpqUyucXI5Z10Gwc16bGj4acpa2tBi4A
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

one USB controller can have multiple ports specified in dts, all of them
should be setup to make use of all possible ports.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v2:
- Rewrite generic_phy_setup_bulk(): Actually v1 is doing things
  completely wrong. This series should work and it's tested on a real
  machine.
- Link to v1: https://lore.kernel.org/r/20240201-ehci-v1-0-bb506cb0f64d@outlook.com

---
Yang Xiwen (3):
      phy: add generic_setup(shutdown)_phy_bulk()
      test: phy: test generic_setup(shutdown)_phy_bulk()
      usb: ehci: Make usage of generic_{setup,shutdown}_phy_bulk() helpers

 drivers/phy/phy-uclass.c        | 41 +++++++++++++++++++++++++++++++++++++++++
 drivers/usb/host/ehci-generic.c |  8 ++++----
 include/generic-phy.h           | 29 +++++++++++++++++++++++++++++
 test/dm/phy.c                   |  4 ++++
 4 files changed, 78 insertions(+), 4 deletions(-)
---
base-commit: b6d8969bcb94321dfed1399f2eaa8768ba42caaa
change-id: 20240201-ehci-6c3aa7d97932

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

