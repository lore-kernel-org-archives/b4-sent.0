From: Marc Kleine-Budde <mkl@pengutronix.de>
Subject: [PATCH 0/6] can: gs_usb: convert to NAPI
Date: Wed, 05 Jul 2023 11:39:51 +0200
Message-Id: <20230705-gs_usb-rx-offload-v1-0-8e7e46e40137@pengutronix.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGc6pWQC/x3M0QpAQBBA0V/RPJtaI1Z+RRJ2lilZ7URK/t3m8
 Tzc+4ByFFZoswciX6IS9oQiz2Bex31hFJcMZKg01lS46HDqhPHG4P0WRoeWyBFVtXV1A6k7Inu
 5/2fXv+8HE0MgymMAAAA=
To: linux-can@vger.kernel.org
Cc: kernel@pengutronix.de, Marc Kleine-Budde <mkl@pengutronix.de>
X-Mailer: b4 0.13-dev-099c9
X-Developer-Signature: v=1; a=openpgp-sha256; l=2015; i=mkl@pengutronix.de;
 h=from:subject:message-id; bh=BL615b5IF7/nLs4QiWPSb9Zd2CYKJy7kdWODpiawfo0=;
 b=owEBbQGS/pANAwAKAb5QHEoqigToAcsmYgBkpTpvDCVuXvyUP1TBGBN0tPlqc3OXqxMsDpJSz
 b9tVyfJMFuJATMEAAEKAB0WIQQOzYG9qPI0qV/1MlC+UBxKKooE6AUCZKU6bwAKCRC+UBxKKooE
 6AxNB/466dNgyz7YolWbxqWRjzcre1JDzHREaWprwL7y+CUMJSsfaXKMvAiVynXNdOYsqCHambL
 BEkXyZkqMpb55lw/9qqfdU5Zkmb6+vO40YxP5NtQKzA1G7z/tR/f+KfL75GiuqYv16hh2cPK75y
 clgSGH+WRiflMKm7G4LmSY0rXNCeBh/KsRLXIrU6ZM5USuIMBGKH6GFd/tgbZvhaii23Pjmcwcp
 2DxGgMYMdBuwGyCVN0c1iKhM+GJ3skBEG36VSMznbSB/jeP8mHAKnGdJWTCQKR3Hh5WR+fIK41q
 My9wdsdhI2IJpgP4w9rHqRB7VX94fBEDfLnPPwMgE6K9kO9M
X-Developer-Key: i=mkl@pengutronix.de; a=openpgp;
 fpr=C1400BA0B3989E6FBC7D5B5C2B5EE211C58AEA54
X-Endpoint-Received: by B4 Relay for mkl@pengutronix.de/default with auth_id=52
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Traditionally USB drivers used to pass the received CAN frames/skbs to
the network stack with netif_rx(). In netif_rx() the skbs are queued
to the local CPU. If IRQs are handled in round robin, OoO packets may
occur.

To support devices without timestamping the TX path of the rx-offload
helper is cleaned up and extended:
- rename rx_offload_get_echo_skb() ->
  can_rx_offload_get_echo_skb_queue_timestamp()
- add can_rx_offload_get_echo_skb_queue_tail()

The remaining 4 patches first add some cleanups to the gs_usb driver
and the last one converts it to NAPI with the rx-offload helper.

Link: https://lore.kernel.org/all/559D628C.5020100@hartkopp.net
Link: https://github.com/candle-usb/candleLight_fw/issues/166
Signed-off-by: Marc Kleine-Budde <mkl@pengutronix.de>
---
Marc Kleine-Budde (6):
      can: rx-offload: rename rx_offload_get_echo_skb() -> can_rx_offload_get_echo_skb_queue_timestamp()
      can: rx-offload: add can_rx_offload_get_echo_skb_queue_tail()
      can: gs_usb: gs_usb_receive_bulk_callback(): count RX overflow errors also in case of OOM
      can: gs_usb: gs_usb_receive_bulk_callback(): make use of netdev
      can: gs_usb: gs_usb_receive_bulk_callback(): make use of stats
      can: gs_usb: convert to NAPI/rx-offload to avoid OoO reception

 drivers/net/can/dev/rx-offload.c              | 36 +++++++++--
 drivers/net/can/flexcan/flexcan-core.c        |  4 +-
 drivers/net/can/m_can/m_can.c                 |  8 +--
 drivers/net/can/spi/mcp251xfd/mcp251xfd-tef.c |  6 +-
 drivers/net/can/ti_hecc.c                     |  4 +-
 drivers/net/can/usb/Kconfig                   |  1 +
 drivers/net/can/usb/gs_usb.c                  | 90 ++++++++++++++++++++-------
 include/linux/can/rx-offload.h                | 11 ++--
 8 files changed, 116 insertions(+), 44 deletions(-)
---
base-commit: 3a8a670eeeaa40d87bd38a587438952741980c18
change-id: 20230705-gs_usb-rx-offload-722d22567d68

Best regards,
-- 
Marc Kleine-Budde <mkl@pengutronix.de>

