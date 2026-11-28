From: Fabio Forni <development@redaril.me>
Subject: [PATCH v5 0/3] Migrate the multiplexer subsystem to fwnode
Date: Sat, 28 Nov 2026 11:43:09 +0100
Message-Id: <20261128-mux_fwnode-v5-0-6689b52f3800@redaril.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/23MwYrCMBCA4VcJc+5IkklK09O+xyKSOJM1sLaS7
 lZF+u6LHhaLXn/4/htMUotM0KsbVJnLVMYBeuUbBftDHL4EC0OvwGrb6mA8Hn8vu3weRhaMpvW
 B9hRyZmgUnKrkcnnMPreNgkOZfsZ6fbxnc69vN7NBg8I+ttxZbdl9VOFYy/fmKHD/zPbZtitr0
 aDvsuHOp8AsL5aerA0rS6gxJEohiiFyr9b9W6N1t7IONaZIRFqcSzau7LIsfxhIsYZZAQAA
X-Change-ID: 20260915-mux_fwnode-a16593c39ffd
To: Peter Rosin <peda@lysator.liu.se>, Linus Walleij <linusw@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 xu.yang_2@nxp.com, 
 =?utf-8?q?Alvin_=C5=A0ipraga?= <alvin.sipraga@analog.com>, 
 Fabio Forni <development@redaril.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2471;
 i=development@redaril.me; h=from:subject:message-id;
 bh=1SuCKJ68UOgHpLyDNKZr0RyJjcgerpccp/GgyvBIesI=;
 b=owGbwMvMwCXWeKho1tqFWemMp9WSGLK5NjhwX3X1zRGa+Zjz/JSbivdu8LzxP7t7nnnTmuczp
 O9+237sT0cpC4MYF4OsmCLLfyejTd1mJka3+iVqYeawMoEMYeDiFICJGGgzMlzTyV2bdfPL+u8v
 zRn+XbyWz5WntsbvnBtH7cGjj/a1rn/F8IdDWFvnoVAlw5J9UttsLx7Vvjct7KNL3o/XDw2Mw75
 IcbMCAA==
X-Developer-Key: i=development@redaril.me; a=openpgp;
 fpr=FF4232B28B363432DA8F187D81C2729AADA16A67
X-Endpoint-Received: by B4 Relay for development@redaril.me/default with auth_id=1033
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch migrates the multiplexer subsystem from using the of_*          
family of functions and structs, to the more generic fwnode framework.     
                                                                           
It is a rebase of a single commit[1] contained in a old patch series[2]
submitted by Xu Yang. The original commit plus follow-up comments were
tested on kernel v6.12 on an arm64-based board, but this current rebase
isn't tested yet.                                                  

While at it, a use-after-free bug was fixed in mux_get(), as suggested by
Alvin Šipraga.

v5 is a rebase against most recent master branch, plus a resend, as v4 was
neither acked not nacked.
                                                                           
Link: https://lore.kernel.org/all/20220823195429.1243516-3-xu.yang_2@nxp.com [1]
Link: https://lore.kernel.org/all/20220823195429.1243516-1-xu.yang_2@nxp.com [2]

Signed-off-by: Fabio Forni <development@redaril.me>
---
Changes in v5:
- Rebase against master, up to 7cd8495c0f16 ("Merge tag 'io_uring-7.4-20261127' of git://git.kernel.org/pub/scm/linux/kernel/git/axboe/linux")
- Link to v4: https://lore.kernel.org/r/20261008-mux_fwnode-v4-0-ba3330e44b2a@redaril.me

Changes in v4:
- The patch that fixes the use-after-free bug is applied before converting
  mux to fwnode, so that it can potentially be backported.
- Link to v3: https://lore.kernel.org/r/20260929-mux_fwnode-v3-0-9b3b9ae1334e@redaril.me

Changes in v3:
- Expand documentation of mux_chip_find_by_fwnode().
- Fix use-after-free bug in mux_get().
- Link to v2: https://lore.kernel.org/r/20260916-mux_fwnode-v2-1-58f1d85b9dde@redaril.me

Changes in v2:
- Rename devm_mux_state_get_from_swnode into devm_mux_state_get_from_fwnode
- Link to v1: https://lore.kernel.org/r/20260915-mux_fwnode-v1-1-ed5a6d8202d4@redaril.me

---
Fabio Forni (3):
      mux: Avoid use-after-free of args.np in mux_get()
      mux: convert to use fwnode interface
      mux: Document mux_chip_find_by_fwnode()

 drivers/mux/core.c                    | 135 ++++++++++++++++++++--------------
 drivers/pinctrl/pinctrl-generic-mux.c |   4 +-
 include/linux/mux/consumer.h          |   6 +-
 3 files changed, 87 insertions(+), 58 deletions(-)
---
base-commit: 7cd8495c0f16275c4f9abe1cef09a7b5fcd6d046
change-id: 20260915-mux_fwnode-a16593c39ffd

Best regards,
-- 
Fabio Forni <development@redaril.me>

