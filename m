From: Fabio Forni <development@redaril.me>
Subject: [PATCH v4 0/3] Migrate the multiplexer subsystem to fwnode
Date: Thu, 08 Oct 2026 22:06:52 +0200
Message-Id: <20261008-mux_fwnode-v4-0-ba3330e44b2a@redaril.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23MTQ7CIBCG4as0rMUUKKS48h7GGNoZLIn9CSjWN
 L27tKs2uvxm8rwTCegdBnLKJuIxuuD6Lo3ikJG6Md0dqYO0Cc+5yjWTtH2NN/vuekBqmJJa1EJ
 bCySBwaN14xq7XNNuXHj2/rO2I1uufzORUUYRpFFQpj8UZ49gvHscWyRLJ/KtVTvLk5WlZVDKS
 gPgjxUby/XOCppTXYlKG2RCFHs7z/MX/H+f/x0BAAA=
X-Change-ID: 20260915-mux_fwnode-a16593c39ffd
To: Peter Rosin <peda@lysator.liu.se>, Linus Walleij <linusw@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 xu.yang_2@nxp.com, 
 =?utf-8?q?Alvin_=C5=A0ipraga?= <alvin.sipraga@analog.com>, 
 Fabio Forni <development@redaril.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2114;
 i=development@redaril.me; h=from:subject:message-id;
 bh=IYapMP+y3ZsxKMdqNwQXhS6WWnTZLOKoL/RQz0KBpm4=;
 b=owGbwMvMwCXWeKho1tqFWemMp9WSGLKOf7/TqW4VdWndkl9Srldm1a5zKeGYt3XXrBQGOZsjS
 WwfPO/0dZSyMIhxMciKKbL8dzLa1G1mYnSrX6IWZg4rE8gQBi5OAZhIYxvDb7b1SSJz1rUwbz43
 RcRh+ew19idMT62dP8/QSOO86NvTprEM/0y8TKKvsMbxistvmGSm7H3aX7Zj36+/R8zVDtofn95
 2ghEA
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
base-commit: 6c377d19d4a5116d9bec5203aa3c6c11523e7898
change-id: 20260915-mux_fwnode-a16593c39ffd

Best regards,
-- 
Fabio Forni <development@redaril.me>

