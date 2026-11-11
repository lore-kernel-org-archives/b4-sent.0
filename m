From: Dave Airlie <airlied@redhat.com>
Subject: [PATCH v7 0/2] nova-core: add initial support for gpu timer (v7)
Date: Wed, 11 Nov 2026 15:23:23 +1000
Message-Id: <20261111-nova-timer-v7-0-3031c2476551@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23Mu47DIBCF4VeJqJcVlwHbqfIe0RbADGuK2BG2U
 KLI774klZG3PEf6/hdbKCda2Pn0YplKWtI81dF9nVgY3fRLPGHdTAllpRSKT3NxfE03yjyCH5C
 06sBJVsE9U0yPT+z6U/eYlnXOz0+7yPf7b6ZILrjX0JFDC2CHSyYc3fod5ht7d4reW91YXa0Ic
 fDeUR/xaGFvTWOhWjCuC1JJBKSDNXtrG2uqdSKgMlETyf5g7d4OjbXVGgPgtMfeq9Zu2/YHqNv
 vtpUBAAA=
X-Change-ID: 20261102-nova-timer-f4b9de3274a1
To: Andreas Hindborg <a.hindborg@kernel.org>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, Gary Guo <gary@garyguo.net>, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2362; i=airlied@redhat.com;
 h=from:subject:message-id; bh=aQdXRoN7clljpU8JEsQNneCbz/wWT5hjhffovrOERe0=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq8/vNl/cI6SPsqeoWBL2b95C3a8hMPEtHUimk5
 t+agOfZCX+JAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavP7zQAKCRAMdPNZecSG
 vrT9D/9t3xI6jF3ymxIYZKf4n75hoKh02+o8TFDQebeJV8Y2BRunE6xczFIsl0N9jbctIITpLfV
 8eWw7cz9Rcr/1IxJQmwuWexbqmUJA7xzJaCtNhZuS9AxRiDbw3+bGaU4SSKoDqfzNsv5WitmaSX
 CInLiQ+nXh8XbHNv2H7GU6saSassH5xr+rgxFirJPiUATqhKZncRQnSQFjz/OBPVeLL24gplB6G
 6O4klRYr3JbE+Ih5pVJ4gbve2iOG+78aBLd2poeebCOGi2pFiH0X8wrH1Tb3KllPHuQnwQ8WSZY
 jNVaGZSHG0BQ6QhBZOLeQTcaVF221N+Hd5P7Xy+ZXvIatMdCG2fomgCSeiukz459i5LSblPG+CX
 Oo3zdfy2/1LNWwaBmzZUl3kZmjRsOWDFEbi76YjoGXVM9KGqs/VNsYpdVHXTrzhJhhQP/jiGvET
 uUNrcyD4cBhvzmmsCInzv/9w3lkdNkiR/Uxh618fGFzU9qvR69xwknor138YyhWB4b37O6Qk9uq
 aMOfGh/6PuGdijV9An4FxWN4fDL2O6yP8EXaM2ldNub0fHPn+8OcKihZo22t87Xnsq9Rz/ZfsVd
 YWqd1xD2wbB3cUyakdCfwZ4G7pPoG05cOcIKOIpp5P0Wm+UyVNrYEUCd2AZyAyd2c8KbrN2g+DP
 Eg6WSxjJoPJfFCQ==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GPU has a timer, one of the pieces of information
we need to pass into GSP init later is the timer offset.
    
This series just adds support for setting up the timer
on Turing+, with hals for Turing and Hopper.
    
Right now it calculates the value to send to GSP but
the code to send it will be added later.
    
For some hardware variants sending a proper value
is required for GSP init to succeed.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
Changes in v7:
- Alexandre's review comments
- fix tu102 non-fatal just print error
- bunch of comments and nits
- Link to v6: https://lore.kernel.org/r/20261109-nova-timer-v6-0-5544a3bd8b28@redhat.com

Changes in v6:
- Alexandre's review comment handled
- fsp hal stores in fsp
- register cleanups
- Link to v5: https://lore.kernel.org/r/20261106-nova-timer-v5-0-a0cd25f3ee18@redhat.com

Changes in v5:
- Alexandre's review comments handled
- reworked registers/workaround logic into fsp
- fixed all the timer register handling to be non-falling.
- Link to v4: https://lore.kernel.org/r/20261105-nova-timer-v4-0-45a7c121d4de@redhat.com

Changes in v4:
- reworked register handling
- used a timerstate.
- Link to v3: https://lore.kernel.org/r/20261103-nova-timer-v3-0-0cf9bbae8fd9@redhat.com

---
Dave Airlie (2):
      rust: time: expose as_nanos for clock sources.
      gpu: nova-core: add support for GPU timer block. (v7)

 drivers/gpu/nova-core/fsp.rs             |  16 ++++-
 drivers/gpu/nova-core/fsp/hal.rs         |   7 ++-
 drivers/gpu/nova-core/fsp/hal/gh100.rs   |   5 ++
 drivers/gpu/nova-core/fsp/regs.rs        |  31 ++++++++++
 drivers/gpu/nova-core/gpu.rs             |   8 +++
 drivers/gpu/nova-core/nova_core.rs       |   1 +
 drivers/gpu/nova-core/timer.rs           |  40 ++++++++++++
 drivers/gpu/nova-core/timer/hal.rs       |  39 ++++++++++++
 drivers/gpu/nova-core/timer/hal/gh100.rs |  71 +++++++++++++++++++++
 drivers/gpu/nova-core/timer/hal/tu102.rs |  49 +++++++++++++++
 drivers/gpu/nova-core/timer/regs.rs      | 103 +++++++++++++++++++++++++++++++
 rust/kernel/time.rs                      |   3 +-
 12 files changed, 368 insertions(+), 5 deletions(-)
---
base-commit: 7a6bc132f1b51437063c9203e7221067b40a791e
change-id: 20261102-nova-timer-f4b9de3274a1

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

