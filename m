From: Dave Airlie <airlied@redhat.com>
Subject: [PATCH v3 0/2] nova-core: add initial support for gpu timer (v3)
Date: Tue, 03 Nov 2026 10:33:37 +1000
Message-Id: <20261103-nova-timer-v3-0-0cf9bbae8fd9@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23MSwrDIBSF4a2EO67FF4Z01H2UDEy8qXcQLSrSE
 tx7bcYd/gfOd0DGRJjhNhyQsFKmGHqoywCrt+GJjFxvkFwaIbhkIVbLCu2Y2KaXyaGSo7YC+uG
 VcKP3iT3m3p5yielz2lX81r9MFYyzRekRrTNam+me0HlbrmvcYW6tfQHxVKdNpQAAAA==
X-Change-ID: 20261102-nova-timer-f4b9de3274a1
To: Andreas Hindborg <a.hindborg@kernel.org>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, Gary Guo <gary@garyguo.net>, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1387; i=airlied@redhat.com;
 h=from:subject:message-id; bh=t7d6XO1s83oTsDc4sW8QAhQzijhkmPTiAZ/XbGhxRA8=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq6SvoQcfmiFC2yw38Q4WVTNNAk0PEbNSGki0W0
 2p7BwUy3GWJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCaukr6AAKCRAMdPNZecSG
 vh/gD/4/hCZ2P3R7qqGOCCHDBfGfpzdpFAFrppHk7c0si5wQqJGP4U7y0vvl0e8BwyQlVJeh6iJ
 Ad8G2RVlyg5TvRaEso+e+b/DbMApTXnOmBT+aKrrFS9lsNVW70lALThqs6rMOzVq6XXX8vYBxYv
 8pVieFx2eMTJ3xXHial9BP7KydXEMT6wQNKd4Eo6hkZRgg3ODwYJnFJOAudRIPj9CsHpOhi5eA3
 OcPcj6ZpRqb3O78KgkKcjkFqcySXMglp/TfC+3H8+TwM9AUwIxttbG8AuUn3KgA4zyqgyRNiYqt
 i6tEWSwgzFXHMzO5vN+Fby7iOW5b312sO9bbiDFAc1L1l+E1JTcTBVTYUgkYzpm3UF3Mf3TK3ZT
 0QJ8pZsnfcZtPvBS/EFpNrQDGr8Fq8EglcZezG0og1h+2H5RnMOnrha/tB3lC3OXixt497UIn7C
 2WK02l1afv3VpEkpJcCjPwcTvxoucmaCrYnghAZA4qNqbEoG27K3DjXP1JJo/59jvpSI4DNKtpm
 yvOK5FGV20aszksXzYQexJt1JYOx9ZCYqo5u66BYZRwjA2EAFfpf6f9Zzy0I/Tlm8LY+e3JiE4F
 xGyaKO31pF9sc2OkVsS7jLA6BUNBJWc4s9J1D+fXoB8ic6lkdHMRAMSDUKTyrGMlW4y7RKDDOF2
 dL5gdfHHVnQwNsw==
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

v2 changes on second patch.
v3 fix the WAR to be hopper only (Sashiko)

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
Dave Airlie (2):
      rust: time: expose as_nanos for clock sources.
      gpu: nova-core: add support for GPU timer block. (v3)

 drivers/gpu/nova-core/gpu.rs             |  5 ++
 drivers/gpu/nova-core/nova_core.rs       |  1 +
 drivers/gpu/nova-core/timer.rs           | 33 +++++++++++
 drivers/gpu/nova-core/timer/hal.rs       | 27 +++++++++
 drivers/gpu/nova-core/timer/hal/gh100.rs | 94 ++++++++++++++++++++++++++++++++
 drivers/gpu/nova-core/timer/hal/tu102.rs | 55 +++++++++++++++++++
 drivers/gpu/nova-core/timer/regs.rs      | 64 ++++++++++++++++++++++
 rust/kernel/time.rs                      |  3 +-
 8 files changed, 281 insertions(+), 1 deletion(-)
---
base-commit: 3497a403264b094ebd61b8b755165d56e7d9dc37
change-id: 20261102-nova-timer-f4b9de3274a1

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

