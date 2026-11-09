From: Dave Airlie <airlied@redhat.com>
Subject: [PATCH v6 0/2] nova-core: add initial support for gpu timer (v6)
Date: Mon, 09 Nov 2026 11:55:57 +1000
Message-Id: <20261109-nova-timer-v6-0-5544a3bd8b28@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23MSw6DIBSF4a0YxqXhcUHtqPtoOkC4VAZqg4a0M
 e696Ehjh+ck3z+TEWPAkdyKmURMYQxDn4e+FMS2pn8hDS5vIpjQnDNB+yEZOoUOI/XQ1A6lKMF
 wksE7og+fLfZ45t2GcRrid2snvr5/M4lTRhsJJRqnAXR9j+haM13t0JG1k+TeyoOV2TLr66YxW
 Hl3trC36mAhW1CmtFxwBw5PVu2tPliVrWHWCeUlIq8OdlmWH0zG/YJZAQAA
X-Change-ID: 20261102-nova-timer-f4b9de3274a1
To: Andreas Hindborg <a.hindborg@kernel.org>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, Gary Guo <gary@garyguo.net>, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2139; i=airlied@redhat.com;
 h=from:subject:message-id; bh=58uDrof2lXfwgFKv4lkz79VwDp7ch5NW6erIJginW+k=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq8SgxbzAzC/vkgvo57Ut9h8pVYRlJxM5p70MfQ
 C0TkGeAuxCJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavEoMQAKCRAMdPNZecSG
 vvgREACJ4gM7F9/nIXF0y01cro2sv9TaG6+LEmRwfx4B9JiVQg9QXdzMgz7Uw/BwLnG1FReCKZ0
 GVjgKJWR5Yo/g4+ViW94rqrmClK73ajCTUMlWMNC0ShmR1FhpGiJkoJfmbgjjqgedabSbjhgB8r
 kxC7UcMh82OAIrRdUi278AR4u20V4OeAFuRwdjenahbcfeTnQEjR/qtR+BocVQP0gPDMOqey8wS
 045JEPf/6dwIm34e0QneNge4/9Xyh1OZxhlcK+g7475jyXufvbsLELtLfAAr9XCqhk8XOnLTTun
 vGu5sQxRY9T7G/SO/2AEbG0aLl+2JTu5TYlb3llK1McHnEKWiAJDAsjaUJR0z9KgPsfNk0DrOJg
 7Yzl7qF+SawRcrl+W7QeYrxCmumrwNp44V9Pghvyj9Ng5tqt20xXP/OWqeykh3kTPp9yvAkR70+
 yBIDYVvg6txY1kOX4PTkrzTeeLC2rkPe2XyIjxR6TKQCrrs8vUCAJe7jL3Pkj6MPrInNNBYx5sq
 DvoXcMfcRiipTmfnWvRa4AY35+6Td49IDpOkKTJW/76xh3VliULARmTjyeDrhiBKYz0/w0qxQMG
 YbtNY27HDvK1//y3ux/kbcU/m3va1ABdGwE+tlYriYp07kLgaqrrLkGWensdpAacoIJIotQMVit
 5mhmc28RbLeaGWw==
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
      gpu: nova-core: add support for GPU timer block. (v6)

 drivers/gpu/nova-core/fsp.rs             | 16 +++++-
 drivers/gpu/nova-core/fsp/hal.rs         |  7 ++-
 drivers/gpu/nova-core/fsp/hal/gh100.rs   |  5 ++
 drivers/gpu/nova-core/fsp/regs.rs        | 31 ++++++++++
 drivers/gpu/nova-core/gpu.rs             |  8 +++
 drivers/gpu/nova-core/nova_core.rs       |  1 +
 drivers/gpu/nova-core/timer.rs           | 38 +++++++++++++
 drivers/gpu/nova-core/timer/hal.rs       | 31 ++++++++++
 drivers/gpu/nova-core/timer/hal/gh100.rs | 63 ++++++++++++++++++++
 drivers/gpu/nova-core/timer/hal/tu102.rs | 41 +++++++++++++
 drivers/gpu/nova-core/timer/regs.rs      | 98 ++++++++++++++++++++++++++++++++
 rust/kernel/time.rs                      |  3 +-
 12 files changed, 337 insertions(+), 5 deletions(-)
---
base-commit: 7a6bc132f1b51437063c9203e7221067b40a791e
change-id: 20261102-nova-timer-f4b9de3274a1

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

