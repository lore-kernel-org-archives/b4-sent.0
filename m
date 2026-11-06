From: Dave Airlie <airlied@redhat.com>
Subject: [PATCH v5 0/2] nova-core: add initial support for gpu timer (v5)
Date: Fri, 06 Nov 2026 15:34:01 +1000
Message-Id: <20261106-nova-timer-v5-0-a0cd25f3ee18@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23MSw6CMBSF4a2Qjq3p4wLiyH0YB33cSgdQ05JGQ
 9i7hRFEh+ck3z+ThNFjItdqJhGzTz6MZdSniphejU+k3pZNBBMN50zQMWRFJz9gpA50Z1GKFhQ
 nBbwiOv/eYvdH2b1PU4ifrZ35+v7NZE4Z1RJaVLYBaLpbRNur6WzCQNZOlnsrD1YWy4zrtFZ4c
 fbXwt7WBwvFQq1awwW3YPFgl2X5AsHoi4wdAQAA
X-Change-ID: 20261102-nova-timer-f4b9de3274a1
To: Andreas Hindborg <a.hindborg@kernel.org>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, Gary Guo <gary@garyguo.net>, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1950; i=airlied@redhat.com;
 h=from:subject:message-id; bh=g7MfgFdREEC1S5dgSmy+QtPmwok55SXsU5E0VesvkuA=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq7WbMRidSdN9Jw5fT0l6XMpGreiVf6TgZxiDUS
 81yQHZGUH6JAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCau1mzAAKCRAMdPNZecSG
 vs/MD/9mqXLJ15mBM5jLlypANpwPEAgbflJgeyg0bid7lzqr5W7vnH3wUbMm9jllX0esZocnF44
 0nU7T2WUaQJtVWfeuZSAU/oKWmcY/KHLzQo8T487kqo+ZSLV7GOY1COp0UHmTUsJfseX3i4q7TG
 lUiuznCxYaJqu+zgL1Y8UKnYx1r7AVVC8PbjTNbr+eZWTCt13EFCi6fgYl7gIzm10PcN5+cRyU9
 a3n+v82yHfmHhshpogZbS4MhFRpSx8jHs3RBzN7e/xD9P1JCUhrM0tcH6I7igbCzgPX0DD97y2n
 SYVIFAejYl3egVBjd9QFk525Cz8gICiyKgA2AcgdAWoE5gKVJGZjyAKEXycDtkFARdhsssebcwW
 d/uEfW7rkCvrf2G9ustA9GCC1seszco9babtgrMU5+NtXxCpApdQ0MegtYxCs8Bv7c4SInomG/8
 j4E+Wmm+bYcRZ0tQezREpPh3YPYTIrQDKkcfON+/6+nnu9Y9oxhO72pSIZGJkRyKAgDIYdkvsPj
 lkJ+wqyLKAppm7Gq+7AxqLt11T6iqNW9XVVN3gzf/zYj7eyAlInD4EAvoBW+/1YfSiaM3gD6vu2
 gCaogmsrjE8o6PbNpEXr2Ts5ATajsXc09lt5Sc84sw0QsUY8LZXIOojcyPL2YVazBub2b73/4hk
 gJb/UGQDYWgFDBg==
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
      gpu: nova-core: add support for GPU timer block. (v5)

 drivers/gpu/nova-core/fsp.rs             | 19 ++++++-
 drivers/gpu/nova-core/fsp/hal.rs         |  5 ++
 drivers/gpu/nova-core/fsp/hal/gh100.rs   |  6 ++
 drivers/gpu/nova-core/fsp/regs.rs        | 28 +++++++++
 drivers/gpu/nova-core/gpu.rs             |  8 +++
 drivers/gpu/nova-core/nova_core.rs       |  1 +
 drivers/gpu/nova-core/timer.rs           | 38 +++++++++++++
 drivers/gpu/nova-core/timer/hal.rs       | 31 ++++++++++
 drivers/gpu/nova-core/timer/hal/gh100.rs | 62 ++++++++++++++++++++
 drivers/gpu/nova-core/timer/hal/tu102.rs | 53 +++++++++++++++++
 drivers/gpu/nova-core/timer/regs.rs      | 98 ++++++++++++++++++++++++++++++++
 rust/kernel/time.rs                      |  3 +-
 12 files changed, 348 insertions(+), 4 deletions(-)
---
base-commit: 7a6bc132f1b51437063c9203e7221067b40a791e
change-id: 20261102-nova-timer-f4b9de3274a1

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

