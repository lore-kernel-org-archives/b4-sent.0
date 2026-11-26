From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: heikki.krogerus@linux.intel.com, gregkh@linuxfoundation.org
Cc: hdegoede@redhat.com, sven@kernel.org, j@jannau.net, 
 Thinh.Nguyen@synopsys.com, asahi@lists.linux.dev, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH v2 0/2] usb: roles: serialize unregister against callbacks
 and fix dwc3-apple lock order
Date: Thu, 26 Nov 2026 00:53:18 +0000
Message-Id: <20261126005318.71705-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795654398; l=1429;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=/KhVzA8eCb4chveoLC9MB4tLBld0vlSj58HKYp0F95E=;
 b=hlaqSQRedY9zEe3UKvea/O2DWIUYTYqp5KOe4VrM6OWsfHIZqmZOKA9kxNZFYhuU/sSUBpr1F
 t1QQzl2V+2HAOXQ9dS33qX2Dn8FL5b3srLlUFNK3X79wYvv2CnLHCw2
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This two-patch v2 series fixes the race between
usb_role_switch_unregister() and concurrent usb_role_switch_{get,set}_role()
callbacks without introducing an ABBA lock-order inversion in callers:

1. Move usb_role_switch_unregister() outside appledwc->lock in
   dwc3_apple_remove(), the only in-tree caller holding a mutex taken by
   its role switch callbacks.
2. Serialize sw->registered checks and teardown under sw->lock in
   drivers/usb/roles/class.c and document the locking contract on
   usb_role_switch_unregister().

Changes in v2:
- Audited all 15 in-tree usb_role_switch_unregister() callers and
  confirmed drivers/usb/dwc3/dwc3-apple.c is the sole caller holding a
  lock also acquired by ->set()/->get().
- Added patch 1/2 fixing dwc3_apple_remove() before patch 2/2 takes
  sw->lock in usb_role_switch_unregister().
- Documented the lock-ordering requirement in the kerneldoc of
  usb_role_switch_unregister().
- Link to v1: https://lore.kernel.org/r/20261125234825.94733-1-iasnezhkov@gmail.com

Found and drafted with an AI coding assistant.

Ilia Snezhkov (2):
  usb: dwc3: apple: unregister role switch outside appledwc->lock
  usb: roles: serialize registered checks and unregister under sw->lock

 drivers/usb/dwc3/dwc3-apple.c |  4 ++--
 drivers/usb/roles/class.c     | 19 ++++++++++++++-----
 2 files changed, 16 insertions(+), 7 deletions(-)

-- 
2.54.0 (Apple Git-157)


