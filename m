From: Fabio Forni <development@redaril.me>
Subject: [PATCH v3 0/3] Migrate the multiplexer subsystem to fwnode
Date: Tue, 29 Sep 2026 22:51:45 +0200
Message-Id: <20260929-mux_fwnode-v3-0-9b3b9ae1334e@redaril.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22MQQ6CMBBFr0JmbQ0ttqGuvIcxpjJTmUTBtFoxh
 LtbWEni8v2f90aIFJgi7IsRAiWO3HcZqk0BTeu6KwnGzKBKZUortbi/hrN/dz2ScNJoWzWV9R4
 hC49Anocldjxlbjk++/BZ2knO699MkkIKQu0M1vnH3SEQusC37Z1g7iT165qVq7Kray+x1heLS
 Ct3mqYvpzksaOEAAAA=
X-Change-ID: 20260915-mux_fwnode-a16593c39ffd
To: Peter Rosin <peda@lysator.liu.se>, Linus Walleij <linusw@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 xu.yang_2@nxp.com, 
 =?utf-8?q?Alvin_=C5=A0ipraga?= <alvin.sipraga@analog.com>, 
 Fabio Forni <development@redaril.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1874;
 i=development@redaril.me; h=from:subject:message-id;
 bh=yMXlm7fl8wPjVC8wr1zDe/3bBhAXU0dk9oPkRIGtYbo=;
 b=owGbwMvMwCXWeKho1tqFWemMp9WSGLL2qLxZdVdt8c6NVcu6tcrsIu+tNl7gH/TIQeuaDOvV5
 oL1bwRbOkpZGMS4GGTFFFn+Oxlt6jYzMbrVL1ELM4eVCWQIAxenAEwkeQfD/1ANw/TrhtvyDmW7
 rZ95id+442Dtzp3p7IptArE9R1x3mjAynL4amXfmx/klC7bKrmhrfT3VyfxqBcvz+eee7n+c7/S
 giwkA
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
                                                                           
Link: https://lore.kernel.org/all/20220823195429.1243516-3-xu.yang_2@nxp.com [1]
Link: https://lore.kernel.org/all/20220823195429.1243516-1-xu.yang_2@nxp.com [2]

Signed-off-by: Fabio Forni <development@redaril.me>
---
Changes in v3:
- Expand documentation of mux_chip_find_by_fwnode().
- Fix use-after-free bug in mux_get().
- Link to v2: https://lore.kernel.org/r/20260916-mux_fwnode-v2-1-58f1d85b9dde@redaril.me

Changes in v2:
- Rename devm_mux_state_get_from_swnode into devm_mux_state_get_from_fwnode
- Link to v1: https://lore.kernel.org/r/20260915-mux_fwnode-v1-1-ed5a6d8202d4@redaril.me

---
Fabio Forni (3):
      mux: convert to use fwnode interface
      mux: Document mux_chip_find_by_fwnode()
      mux: Avoid use-after-free of args.fwnode in mux_get()

 drivers/mux/core.c                    | 134 ++++++++++++++++++++--------------
 drivers/pinctrl/pinctrl-generic-mux.c |   4 +-
 include/linux/mux/consumer.h          |   6 +-
 3 files changed, 86 insertions(+), 58 deletions(-)
---
base-commit: f6e7b42bf05b2427fb8a7a1d1c387a86638bb413
change-id: 20260915-mux_fwnode-a16593c39ffd

Best regards,
-- 
Fabio Forni <development@redaril.me>

